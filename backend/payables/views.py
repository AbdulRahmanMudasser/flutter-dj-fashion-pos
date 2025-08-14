from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, Sum
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from .models import Payable, PayablePayment
from .serializers import (
    PayableBulkActionSerializer,
    PayableSerializer,
    PayableCreateSerializer,
    PayableListSerializer,
    PayableStatsSerializer,
    PayableUpdateSerializer,
    PayableDetailSerializer,
    PayableContactUpdateSerializer,
    PayablePaymentSerializer,
    PayablePaymentCreateSerializer,
)
from .signals import payable_bulk_updated


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_payables(request):
    """
    List all active payables with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        status_filter = request.GET.get('status', '').strip()
        priority_filter = request.GET.get('priority', '').strip()
        vendor_id = request.GET.get('vendor_id', '').strip()
        
        # Date range filters
        due_after = request.GET.get('due_after', '').strip()
        due_before = request.GET.get('due_before', '').strip()
        borrowed_after = request.GET.get('borrowed_after', '').strip()
        borrowed_before = request.GET.get('borrowed_before', '').strip()
        
        # Special filters
        overdue_only = request.GET.get('overdue_only', 'false').lower() == 'true'
        urgent_only = request.GET.get('urgent_only', 'false').lower() == 'true'
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'expected_repayment_date')
        sort_order = request.GET.get('sort_order', 'asc')
        
        # Base queryset
        if show_inactive:
            payables = Payable.objects.all()
        else:
            payables = Payable.active_payables()
        
        # Apply search filter
        if search:
            payables = payables.search(search)
        
        # Apply status filter
        if status_filter:
            payables = payables.filter(status=status_filter)
        
        # Apply priority filter
        if priority_filter:
            payables = payables.filter(priority=priority_filter)
        
        # Apply vendor filter
        if vendor_id:
            payables = payables.filter(vendor_id=vendor_id)
        
        # Apply special filters
        if overdue_only:
            payables = payables.overdue()
        
        if urgent_only:
            payables = payables.urgent()
        
        # Apply date range filters
        if due_after:
            try:
                payables = payables.filter(expected_repayment_date__gte=due_after)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid due_after date format. Use YYYY-MM-DD.',
                    'errors': {'due_after': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if due_before:
            try:
                payables = payables.filter(expected_repayment_date__lte=due_before)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid due_before date format. Use YYYY-MM-DD.',
                    'errors': {'due_before': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if borrowed_after:
            try:
                payables = payables.filter(date_borrowed__gte=borrowed_after)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid borrowed_after date format. Use YYYY-MM-DD.',
                    'errors': {'borrowed_after': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if borrowed_before:
            try:
                payables = payables.filter(date_borrowed__lte=borrowed_before)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid borrowed_before date format. Use YYYY-MM-DD.',
                    'errors': {'borrowed_before': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply sorting
        sort_fields = {
            'creditor_name': 'creditor_name',
            'amount_borrowed': 'amount_borrowed',
            'balance_remaining': 'balance_remaining',
            'expected_repayment_date': 'expected_repayment_date',
            'date_borrowed': 'date_borrowed',
            'priority': 'priority',
            'status': 'status',
            'created_at': 'created_at',
            'updated_at': 'updated_at'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            payables = payables.order_by(order_field)
        
        # Select related to avoid N+1 queries
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'filters_applied': {
                    'search': search,
                    'status': status_filter,
                    'priority': priority_filter,
                    'vendor_id': vendor_id,
                    'overdue_only': overdue_only,
                    'urgent_only': urgent_only,
                    'due_after': due_after,
                    'due_before': due_before,
                    'borrowed_after': borrowed_after,
                    'borrowed_before': borrowed_before,
                    'sort_by': sort_by,
                    'sort_order': sort_order
                }
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError as e:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve payables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_payable(request):
    """
    Create a new payable
    """
    serializer = PayableCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                payable = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Payable created successfully.',
                    'data': PayableDetailSerializer(payable).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Payable creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Payable creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payable(request, payable_id):
    """
    Retrieve a specific payable by ID
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        serializer = PayableDetailSerializer(payable)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_payable(request, payable_id):
    """
    Update a payable
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        serializer = PayableUpdateSerializer(
            payable,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    payable = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Payable updated successfully.',
                        'data': PayableDetailSerializer(payable).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Payable update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Payable update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_payable(request, payable_id):
    """
    Hard delete a payable (permanently remove from database)
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        # Store payable info for response message
        creditor_name = payable.creditor_name
        amount = payable.amount_borrowed
        
        # Check if payable has payments
        if payable.payments.exists():
            return Response({
                'success': False,
                'message': 'Cannot delete payable as it has payment history.',
                'errors': {'detail': 'This payable has payment records.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the payable
        payable.delete()
        
        return Response({
            'success': True,
            'message': f'Payable for "{creditor_name}" (Amount: {amount}) deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payable deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_payable(request, payable_id):
    """
    Soft delete a payable (set is_active=False)
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        if not payable.is_active:
            return Response({
                'success': False,
                'message': 'Payable is already inactive.',
                'errors': {'detail': 'This payable has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payable.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Payable soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payable soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_payable(request, payable_id):
    """
    Restore a soft-deleted payable (set is_active=True)
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        if payable.is_active:
            return Response({
                'success': False,
                'message': 'Payable is already active.',
                'errors': {'detail': 'This payable is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payable.restore()
        
        return Response({
            'success': True,
            'message': 'Payable restored successfully.',
            'data': PayableDetailSerializer(payable).data
        }, status=status.HTTP_200_OK)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payable restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_payment(request, payable_id):
    """
    Add a payment to a payable
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        # Add payable to the request data
        payment_data = request.data.copy()
        payment_data['payable'] = payable_id
        
        serializer = PayablePaymentSerializer(
            data=payment_data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    payment = serializer.save()
                    
                    # Refresh payable to get updated calculations
                    payable.refresh_from_db()
                    
                    return Response({
                        'success': True,
                        'message': 'Payment added successfully.',
                        'data': {
                            'payment': PayablePaymentSerializer(payment).data,
                            'payable': PayableDetailSerializer(payable).data
                        }
                    }, status=status.HTTP_201_CREATED)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Payment addition failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Payment addition failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_payable_contact(request, payable_id):
    """
    Update payable contact information
    """
    try:
        payable = get_object_or_404(Payable, id=payable_id)
        
        serializer = PayableContactUpdateSerializer(
            payable,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    payable = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Payable contact information updated successfully.',
                        'data': {
                            'id': str(payable.id),
                            'creditor_name': payable.creditor_name,
                            'creditor_phone': payable.creditor_phone,
                            'creditor_email': payable.creditor_email
                        }
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Contact update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Contact update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Payable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payable not found.',
            'errors': {'detail': 'Payable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    