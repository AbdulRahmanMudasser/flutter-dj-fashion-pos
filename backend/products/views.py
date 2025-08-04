from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q
from decimal import Decimal, InvalidOperation
from .models import Product
from .serializers import (
    ProductSerializer,
    ProductCreateSerializer,
    ProductListSerializer,
    ProductUpdateSerializer,
    ProductDetailSerializer,
    ProductStatsSerializer,
    BulkQuantityUpdateSerializer
)


# Function-based views (following your Category module pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_products(request):
    """
    List all active products with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        category_id = request.GET.get('category_id', '').strip()
        color = request.GET.get('color', '').strip()
        fabric = request.GET.get('fabric', '').strip()
        stock_level = request.GET.get('stock_level', '').strip()
        
        # Price range
        min_price = request.GET.get('min_price', '').strip()
        max_price = request.GET.get('max_price', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'name')  # name, price, quantity, created_at
        sort_order = request.GET.get('sort_order', 'asc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            products = Product.objects.all()
        else:
            products = Product.active_products()
        
        # Apply search filter
        if search:
            products = products.search(search)
        
        # Apply category filter
        if category_id:
            products = products.filter(category_id=category_id)
        
        # Apply color filter
        if color:
            products = products.filter(color__icontains=color)
        
        # Apply fabric filter
        if fabric:
            products = products.filter(fabric__icontains=fabric)
        
        # Apply price range filter
        try:
            if min_price:
                products = products.filter(price__gte=Decimal(min_price))
            if max_price:
                products = products.filter(price__lte=Decimal(max_price))
        except (InvalidOperation, ValueError):
            return Response({
                'success': False,
                'message': 'Invalid price range values.',
                'errors': {'detail': 'Price values must be valid numbers.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply stock level filter
        if stock_level:
            products = products.stock_level(stock_level.upper())
        
        # Apply sorting
        sort_fields = {
            'name': 'name',
            'price': 'price',
            'quantity': 'quantity',
            'created_at': 'created_at',
            'updated_at': 'updated_at'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            products = products.order_by(order_field)
        
        # Select related to avoid N+1 queries
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
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
                    'category_id': category_id,
                    'color': color,
                    'fabric': fabric,
                    'stock_level': stock_level,
                    'min_price': min_price,
                    'max_price': max_price,
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
            'message': 'Failed to retrieve products.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_product(request):
    """
    Create a new product
    """
    serializer = ProductCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                product = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Product created successfully.',
                    'data': ProductDetailSerializer(product).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Product creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Product creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_product(request, product_id):
    """
    Retrieve a specific product by ID
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        serializer = ProductDetailSerializer(product)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_product(request, product_id):
    """
    Update a product
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        
        serializer = ProductUpdateSerializer(
            product,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    product = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Product updated successfully.',
                        'data': ProductDetailSerializer(product).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Product update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Product update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_product(request, product_id):
    """
    Hard delete a product (permanently remove from database)
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        
        # Store product name for response message
        product_name = product.name
        
        # Check if product is being used in sales (optional safety check)
        # Uncomment this if you have a Sales model that references products
        # if hasattr(product, 'sale_items') and product.sale_items.exists():
        #     return Response({
        #         'success': False,
        #         'message': 'Cannot delete product as it is being used in sales.',
        #         'errors': {'detail': 'This product is currently part of one or more sales.'}
        #     }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the product
        product.delete()
        
        return Response({
            'success': True,
            'message': f'Product "{product_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_product(request, product_id):
    """
    Soft delete a product (set is_active=False)
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        
        if not product.is_active:
            return Response({
                'success': False,
                'message': 'Product is already inactive.',
                'errors': {'detail': 'This product has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        product.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Product soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_product(request, product_id):
    """
    Restore a soft-deleted product (set is_active=True)
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        
        if product.is_active:
            return Response({
                'success': False,
                'message': 'Product is already active.',
                'errors': {'detail': 'This product is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        product.restore()
        
        return Response({
            'success': True,
            'message': 'Product restored successfully.',
            'data': ProductDetailSerializer(product).data
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_products(request):
    """
    Search products by name, color, fabric, or category
    """
    try:
        query = request.GET.get('q', '').strip()
        if not query:
            return Response({
                'success': False,
                'message': 'Search query is required.',
                'errors': {'detail': 'Please provide a search query parameter "q".'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search products
        products = Product.active_products().search(query)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'search_query': query
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Search failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def products_by_category(request, category_id):
    """
    Get products by category
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get products by category
        products = Product.products_by_category(category_id)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'category_id': category_id
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve products by category.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def low_stock_products(request):
    """
    Get products with low stock
    """
    try:
        threshold = int(request.GET.get('threshold', 5))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get low stock products
        products = Product.low_stock_products(threshold=threshold)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'threshold': threshold,
                'alert_message': f'{total_count} products with stock level ≤ {threshold}'
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid parameters.',
            'errors': {'detail': 'Threshold, page, and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve low stock products.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def product_statistics(request):
    """
    Get comprehensive product statistics
    """
    try:
        stats = Product.get_statistics()
        serializer = ProductStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve product statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_product_quantity(request, product_id):
    """
    Update product quantity
    """
    try:
        product = get_object_or_404(Product, id=product_id)
        
        new_quantity = request.data.get('quantity')
        if new_quantity is None:
            return Response({
                'success': False,
                'message': 'Quantity is required.',
                'errors': {'detail': 'Please provide quantity in request body.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            new_quantity = int(new_quantity)
            if new_quantity < 0:
                raise ValueError("Quantity cannot be negative")
        except (ValueError, TypeError):
            return Response({
                'success': False,
                'message': 'Invalid quantity value.',
                'errors': {'detail': 'Quantity must be a non-negative integer.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Update quantity
        update_result = product.update_quantity(new_quantity, user=request.user)
        
        return Response({
            'success': True,
            'message': 'Product quantity updated successfully.',
            'data': {
                'product_id': str(product.id),
                'product_name': product.name,
                'old_quantity': update_result['old_quantity'],
                'new_quantity': update_result['new_quantity'],
                'difference': update_result['difference'],
                'stock_status': product.stock_status,
                'stock_status_display': product.stock_status_display
            }
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Quantity update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_update_quantities(request):
    """
    Bulk update product quantities
    """
    serializer = BulkQuantityUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                updates = serializer.validated_data['updates']
                results = []
                
                for update in updates:
                    product_id = update['product_id']
                    new_quantity = update['quantity']
                    
                    product = Product.objects.get(id=product_id)
                    update_result = product.update_quantity(new_quantity, user=request.user)
                    
                    results.append({
                        'product_id': product_id,
                        'product_name': product.name,
                        'old_quantity': update_result['old_quantity'],
                        'new_quantity': update_result['new_quantity'],
                        'difference': update_result['difference'],
                        'stock_status': product.stock_status
                    })
                
                return Response({
                    'success': True,
                    'message': f'Successfully updated {len(results)} products.',
                    'data': {
                        'updated_products': results,
                        'total_updated': len(results)
                    }
                }, status=status.HTTP_200_OK)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Bulk update failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Bulk update failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def duplicate_product(request, product_id):
    """
    Duplicate an existing product
    """
    try:
        original_product = get_object_or_404(Product, id=product_id)
        
        # Get new name from request data or auto-generate
        new_name = request.data.get('name', f"{original_product.name} (Copy)")
        
        # Create duplicate
        with transaction.atomic():
            duplicate_data = {
                'name': new_name,
                'detail': original_product.detail,
                'price': original_product.price,
                'color': original_product.color,
                'fabric': original_product.fabric,
                'pieces': original_product.pieces.copy(),
                'quantity': 0,  # Start with 0 quantity for duplicate
                'category': original_product.category,
                'created_by': request.user
            }
            
            duplicate_product = Product.objects.create(**duplicate_data)
            
            return Response({
                'success': True,
                'message': 'Product duplicated successfully.',
                'data': ProductDetailSerializer(duplicate_product).data
            }, status=status.HTTP_201_CREATED)
            
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        