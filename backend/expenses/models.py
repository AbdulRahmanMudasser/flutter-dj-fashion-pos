from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator
from decimal import Decimal
import uuid

User = get_user_model()

class ExpenseManager(models.Manager):
    """Custom manager for Expense model"""
    
    def active(self):
        """Get only active expenses"""
        return self.filter(is_active=True)
    
    def by_authority(self, authority):
        """Get expenses by withdrawal authority"""
        return self.active().filter(withdrawal_by=authority)
    
    def by_category(self, category):
        """Get expenses by category"""
        return self.active().filter(category=category)
    
    def by_date_range(self, start_date, end_date):
        """Get expenses within date range"""
        return self.active().filter(date__range=[start_date, end_date])
    
    def recent(self, limit=10):
        """Get recent expenses"""
        return self.active().order_by('-created_at')[:limit]


class Expense(models.Model):
    """Expense model for tracking company expenses and withdrawals"""
    
    WITHDRAWAL_CHOICES = [
        ('Mr. Sheikh Parveez Maqbool', 'Mr. Sheikh Parveez Maqbool'),
        ('Mr Sheikh Zain Maqbool', 'Mr Sheikh Zain Maqbool'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    expense = models.CharField(max_length=200, help_text="Expense title/name")
    description = models.TextField(help_text="Detailed description of the expense")
    amount = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Expense amount"
    )
    withdrawal_by = models.CharField(
        max_length=50,
        choices=WITHDRAWAL_CHOICES,
        help_text="Who authorized/made the withdrawal"
    )
    date = models.DateField(help_text="Date of expense")
    time = models.TimeField(help_text="Time of expense")
    category = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Optional expense category"
    )
    notes = models.TextField(
        blank=True, 
        null=True,
        help_text="Additional notes"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        help_text="Who recorded this expense"
    )
    is_active = models.BooleanField(default=True, help_text="For soft deletion")
    
    objects = ExpenseManager()
    
    class Meta:
        db_table = 'expense'
        verbose_name = 'Expense'
        verbose_name_plural = 'Expenses'
        ordering = ['-date', '-time']
        indexes = [
            models.Index(fields=['date']),
            models.Index(fields=['withdrawal_by']),
            models.Index(fields=['category']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        if not self.expense:
            return "New Expense"
        return f"{self.expense} - {self.formatted_amount}"
    
    @property
    def expense_age_days(self):
        """Days since expense was recorded"""
        if not self.date:
            return 0
        return (timezone.now().date() - self.date).days
    
    @property
    def formatted_amount(self):
        """Currency formatted amount display"""
        if self.amount is None:
            return "PKR 0.00"
        return f"PKR {self.amount:,.2f}"
    
    @property
    def withdrawal_initials(self):
        """Initials of person who made withdrawal"""
        name_parts = self.withdrawal_by.split()
        initials = ""
        for part in name_parts:
            if part.startswith(('Mr.', 'Mr', 'Mrs.', 'Mrs', 'Ms.', 'Ms')):
                continue
            if part:
                initials += part[0].upper()
        return initials or self.withdrawal_by[:2].upper()
    
    @property
    def expense_summary(self):
        """Short summary for display"""
        if not self.expense:
            return "New Expense"
        summary = self.expense
        if len(summary) > 50:
            summary = summary[:47] + "..."
        amount_display = self.formatted_amount if self.amount is not None else "PKR 0.00"
        return f"{summary} - {amount_display}"
    
    def clean(self):
        """Custom validation"""
        from django.core.exceptions import ValidationError
        
        # Date cannot be in the future
        if self.date > timezone.now().date():
            raise ValidationError({'date': 'Date cannot be in the future.'})
        
        # Amount must be positive
        if self.amount <= 0:
            raise ValidationError({'amount': 'Amount must be positive and greater than zero.'})
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    def delete(self):
        """Soft delete"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def hard_delete(self):
        """Permanent delete"""
        super().delete()
        