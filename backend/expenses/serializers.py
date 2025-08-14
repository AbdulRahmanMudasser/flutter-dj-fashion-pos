from rest_framework import serializers
from django.utils import timezone
from django.db.models import Sum, Count, Avg
from decimal import Decimal
from .models import Expense


class ExpenseSerializer(serializers.ModelSerializer):
    """Main serializer for Expense model"""
    
    formatted_amount = serializers.ReadOnlyField()
    withdrawal_initials = serializers.ReadOnlyField()
    expense_summary = serializers.ReadOnlyField()
    expense_age_days = serializers.ReadOnlyField()
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = Expense
        fields = [
            'id', 'expense', 'description', 'amount', 'formatted_amount',
            'withdrawal_by', 'withdrawal_initials', 'date', 'time',
            'category', 'notes', 'expense_summary', 'expense_age_days',
            'created_at', 'updated_at', 'created_by', 'created_by_name'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'created_by']
    
    def validate_amount(self, value):
        """Validate amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive and greater than zero.")
        return value
    
    def validate_date(self, value):
        """Validate date is not in the future"""
        if value > timezone.now().date():
            raise serializers.ValidationError("Date cannot be in the future.")
        return value
    
    def validate(self, attrs):
        """Additional validation"""
        # Ensure withdrawal_by is from valid choices
        withdrawal_by = attrs.get('withdrawal_by')
        if withdrawal_by:
            valid_choices = [choice[0] for choice in Expense.WITHDRAWAL_CHOICES]
            if withdrawal_by not in valid_choices:
                raise serializers.ValidationError({
                    'withdrawal_by': f'Invalid choice. Must be one of: {", ".join(valid_choices)}'
                })
        
        return attrs


class ExpenseCreateSerializer(ExpenseSerializer):
    """Serializer for creating expenses"""
    
    def create(self, validated_data):
        """Create expense with current user as created_by"""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ExpenseUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating expenses"""
    
    class Meta:
        model = Expense
        fields = [
            'expense', 'description', 'amount', 'withdrawal_by',
            'date', 'time', 'category', 'notes'
        ]
    
    def validate_amount(self, value):
        """Validate amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive and greater than zero.")
        return value
    
    def validate_date(self, value):
        """Validate date is not in the future"""
        if value > timezone.now().date():
            raise serializers.ValidationError("Date cannot be in the future.")
        return value


class ExpenseListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing expenses"""
    
    formatted_amount = serializers.ReadOnlyField()
    withdrawal_initials = serializers.ReadOnlyField()
    expense_summary = serializers.ReadOnlyField()
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = Expense
        fields = [
            'id', 'expense_summary', 'formatted_amount', 'withdrawal_by',
            'withdrawal_initials', 'date', 'time', 'category',
            'created_by_name', 'created_at'
        ]


class ExpenseStatisticsSerializer(serializers.Serializer):
    """Serializer for expense statistics"""
    
    total_expenses = serializers.DecimalField(max_digits=12, decimal_places=2)
    expense_count = serializers.IntegerField()
    average_expense = serializers.DecimalField(max_digits=12, decimal_places=2)
    formatted_total = serializers.CharField()
    formatted_average = serializers.CharField()
    
    # By authority statistics
    by_authority = serializers.DictField()
    
    # By category statistics
    by_category = serializers.DictField()
    
    # Recent trends
    monthly_trend = serializers.ListField()
    
    def to_representation(self, instance):
        """Custom representation for statistics"""
        # Get basic statistics
        expenses = Expense.objects.active()
        total_amount = expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
        count = expenses.count()
        average = expenses.aggregate(avg=Avg('amount'))['avg'] or Decimal('0')
        
        # Statistics by authority
        by_authority = {}
        for choice in Expense.WITHDRAWAL_CHOICES:
            authority = choice[0]
            auth_expenses = expenses.filter(withdrawal_by=authority)
            auth_total = auth_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            auth_count = auth_expenses.count()
            by_authority[authority] = {
                'total_amount': float(auth_total),
                'formatted_amount': f"PKR {auth_total:,.2f}",
                'count': auth_count,
                'percentage': float((auth_total / total_amount * 100) if total_amount > 0 else 0)
            }
        
        # Statistics by category
        by_category = {}
        categories = expenses.exclude(category__isnull=True).exclude(category='').values_list('category', flat=True).distinct()
        for category in categories:
            cat_expenses = expenses.filter(category=category)
            cat_total = cat_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            cat_count = cat_expenses.count()
            by_category[category] = {
                'total_amount': float(cat_total),
                'formatted_amount': f"PKR {cat_total:,.2f}",
                'count': cat_count,
                'percentage': float((cat_total / total_amount * 100) if total_amount > 0 else 0)
            }
        
        # Monthly trend (last 6 months)
        from datetime import datetime, timedelta
        from django.db.models import Q
        
        monthly_trend = []
        for i in range(6):
            month_start = (timezone.now().date().replace(day=1) - timedelta(days=i*30))
            month_end = month_start.replace(day=28) + timedelta(days=4)
            month_end = month_end - timedelta(days=month_end.day)
            
            month_expenses = expenses.filter(date__range=[month_start, month_end])
            month_total = month_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            month_count = month_expenses.count()
            
            monthly_trend.append({
                'month': month_start.strftime('%B %Y'),
                'total_amount': float(month_total),
                'formatted_amount': f"PKR {month_total:,.2f}",
                'count': month_count
            })
        
        return {
            'total_expenses': float(total_amount),
            'expense_count': count,
            'average_expense': float(average),
            'formatted_total': f"PKR {total_amount:,.2f}",
            'formatted_average': f"PKR {average:,.2f}",
            'by_authority': by_authority,
            'by_category': by_category,
            'monthly_trend': monthly_trend
        }


class BulkExpenseActionSerializer(serializers.Serializer):
    """Serializer for bulk operations on expenses"""
    
    action = serializers.ChoiceField(choices=['delete', 'activate', 'deactivate'])
    expense_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1
    )
    
    def validate_expense_ids(self, value):
        """Validate that all expense IDs exist and belong to active expenses"""
        existing_ids = set(
            Expense.objects.filter(id__in=value, is_active=True).values_list('id', flat=True)
        )
        provided_ids = set(value)
        
        if not provided_ids.issubset(existing_ids):
            missing_ids = provided_ids - existing_ids
            raise serializers.ValidationError(
                f"The following expense IDs do not exist or are inactive: {list(missing_ids)}"
            )
        
        return value


class MonthlySummarySerializer(serializers.Serializer):
    """Serializer for monthly expense summary"""
    
    month = serializers.CharField()
    year = serializers.IntegerField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    formatted_amount = serializers.CharField()
    expense_count = serializers.IntegerField()
    average_expense = serializers.DecimalField(max_digits=12, decimal_places=2)
    formatted_average = serializers.CharField()
    categories = serializers.DictField()
    authorities = serializers.DictField()
    daily_breakdown = serializers.ListField()
    
    def to_representation(self, instance):
        """Custom representation for monthly summary"""
        month = instance.get('month', timezone.now().month)
        year = instance.get('year', timezone.now().year)
        
        # Get expenses for the month
        expenses = Expense.objects.active().filter(
            date__year=year,
            date__month=month
        )
        
        total_amount = expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
        count = expenses.count()
        average = expenses.aggregate(avg=Avg('amount'))['avg'] or Decimal('0')
        
        # Category breakdown
        categories = {}
        for expense in expenses.exclude(category__isnull=True).exclude(category=''):
            cat = expense.category
            if cat not in categories:
                categories[cat] = {'amount': Decimal('0'), 'count': 0}
            categories[cat]['amount'] += expense.amount
            categories[cat]['count'] += 1
        
        # Format categories
        formatted_categories = {}
        for cat, data in categories.items():
            formatted_categories[cat] = {
                'amount': float(data['amount']),
                'formatted_amount': f"PKR {data['amount']:,.2f}",
                'count': data['count']
            }
        
        # Authority breakdown
        authorities = {}
        for choice in Expense.WITHDRAWAL_CHOICES:
            authority = choice[0]
            auth_expenses = expenses.filter(withdrawal_by=authority)
            auth_total = auth_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            auth_count = auth_expenses.count()
            authorities[authority] = {
                'amount': float(auth_total),
                'formatted_amount': f"PKR {auth_total:,.2f}",
                'count': auth_count
            }
        
        # Daily breakdown
        from django.db.models import Q
        daily_breakdown = []
        import calendar
        days_in_month = calendar.monthrange(year, month)[1]
        
        for day in range(1, days_in_month + 1):
            day_expenses = expenses.filter(date__day=day)
            day_total = day_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            day_count = day_expenses.count()
            
            daily_breakdown.append({
                'day': day,
                'amount': float(day_total),
                'formatted_amount': f"PKR {day_total:,.2f}",
                'count': day_count
            })
        
        month_name = calendar.month_name[month]
        
        return {
            'month': month_name,
            'year': year,
            'total_amount': float(total_amount),
            'formatted_amount': f"PKR {total_amount:,.2f}",
            'expense_count': count,
            'average_expense': float(average),
            'formatted_average': f"PKR {average:,.2f}",
            'categories': formatted_categories,
            'authorities': authorities,
            'daily_breakdown': daily_breakdown
        }
    