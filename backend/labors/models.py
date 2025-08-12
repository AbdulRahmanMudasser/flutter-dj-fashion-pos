import uuid
import re
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator, MinValueValidator, MaxValueValidator
from django.utils import timezone
from datetime import timedelta, date


class LaborQuerySet(models.QuerySet):
    """Custom QuerySet for Labor model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def inactive(self):
        return self.filter(is_active=False)
    
    def search(self, query):
        """Search labors by name, cnic, phone, caste, designation, city, or area"""
        return self.filter(
            models.Q(name__icontains=query) |
            models.Q(cnic__icontains=query) |
            models.Q(phone_number__icontains=query) |
            models.Q(caste__icontains=query) |
            models.Q(designation__icontains=query) |
            models.Q(city__icontains=query) |
            models.Q(area__icontains=query)
        )
    
    def by_city(self, city):
        """Filter labors by city"""
        return self.filter(city__iexact=city)
    
    def by_area(self, area):
        """Filter labors by area"""
        return self.filter(area__iexact=area)
    
    def by_designation(self, designation):
        """Filter labors by designation"""
        return self.filter(designation__iexact=designation)
    
    def by_caste(self, caste):
        """Filter labors by caste"""
        return self.filter(caste__iexact=caste)
    
    def by_gender(self, gender):
        """Filter labors by gender"""
        return self.filter(gender=gender)
    
    def recent(self, days=30):
        """Get labors joined in the last N days"""
        date_threshold = timezone.now().date() - timedelta(days=days)
        return self.filter(joining_date__gte=date_threshold)
    
    def joined_between(self, start_date, end_date):
        """Filter labors joined between dates"""
        return self.filter(joining_date__range=[start_date, end_date])
    
    def salary_range(self, min_salary=None, max_salary=None):
        """Filter labors by salary range"""
        queryset = self
        if min_salary is not None:
            queryset = queryset.filter(salary__gte=min_salary)
        if max_salary is not None:
            queryset = queryset.filter(salary__lte=max_salary)
        return queryset
    
    def age_range(self, min_age=None, max_age=None):
        """Filter labors by age range"""
        queryset = self
        if min_age is not None:
            queryset = queryset.filter(age__gte=min_age)
        if max_age is not None:
            queryset = queryset.filter(age__lte=max_age)
        return queryset


def validate_pakistani_cnic(value):
    """Validate Pakistani CNIC format: 42101-1234567-8"""
    pattern = r'^\d{5}-\d{7}-\d{1}$'
    if not re.match(pattern, value):
        raise ValidationError(
            'CNIC must be in format: 12345-1234567-1'
        )


def validate_joining_date(value):
    """Validate that joining date is not in the future"""
    if value > date.today():
        raise ValidationError("Joining date cannot be in the future.")


class Labor(models.Model):
    """Labor model for managing workforce"""
    
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    
    # Phone validator
    phone_regex = RegexValidator(
        regex=r'^[\+]?[0-9\-\s]{10,20}$',
        message="Phone number must be entered in valid format"
    )
    
    # Primary fields
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    name = models.CharField(
        max_length=200,
        help_text="Full name of the labor"
    )
    cnic = models.CharField(
        max_length=15,
        unique=True,
        validators=[validate_pakistani_cnic],
        help_text="Pakistani CNIC in format: 12345-1234567-1"
    )
    phone_number = models.CharField(
        max_length=20,
        validators=[phone_regex],
        help_text="Contact phone number"
    )
    caste = models.CharField(
        max_length=100,
        help_text="Caste/community of the labor"
    )
    designation = models.CharField(
        max_length=150,
        help_text="Job designation/position"
    )
    joining_date = models.DateField(
        validators=[validate_joining_date],
        help_text="Date when labor joined"
    )
    salary = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Monthly salary amount"
    )
    area = models.CharField(
        max_length=100,
        help_text="Area/locality within the city"
    )
    city = models.CharField(
        max_length=100,
        help_text="City where labor is located"
    )
    gender = models.CharField(
        max_length=1,
        choices=GENDER_CHOICES,
        help_text="Gender of the labor"
    )
    age = models.PositiveIntegerField(
        validators=[
            MinValueValidator(16, "Minimum age must be 16 years"),
            MaxValueValidator(70, "Maximum age must be 70 years")
        ],
        help_text="Age of the labor"
    )
    
    # System fields
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_labors'
    )
    
    # Custom manager
    objects = models.Manager.from_queryset(LaborQuerySet)()
    
    class Meta:
        db_table = 'labor'
        verbose_name = 'Labor'
        verbose_name_plural = 'Labors'
        ordering = ['-created_at', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['cnic']),
            models.Index(fields=['phone_number']),
            models.Index(fields=['designation']),
            models.Index(fields=['caste']),
            models.Index(fields=['city']),
            models.Index(fields=['area']),
            models.Index(fields=['gender']),
            models.Index(fields=['joining_date']),
            models.Index(fields=['salary']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.designation})"
    
    def clean(self):
        """Validate model data"""
        # Clean and validate name
        if self.name:
            self.name = self.name.strip()
            if not self.name:
                raise ValidationError({'name': 'Labor name cannot be empty.'})
        
        # Clean phone number
        if self.phone_number:
            self.phone_number = self.phone_number.strip()
            self.phone_number = self.format_phone_number(self.phone_number)
        
        # Clean other fields
        if self.caste:
            self.caste = self.caste.strip().title()
        if self.designation:
            self.designation = self.designation.strip().title()
        if self.cnic:
            self.cnic = self.cnic.strip()
        if self.city:
            self.city = self.city.strip().title()
        if self.area:
            self.area = self.area.strip().title()
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    # Properties
    @property
    def display_name(self):
        """Get display name for labor"""
        return f"{self.name} ({self.designation})"
    
    @property
    def full_address(self):
        """Return complete address"""
        return f"{self.area}, {self.city}"
    
    @property
    def is_new_labor(self):
        """Check if labor is new (joined within last 30 days)"""
        thirty_days_ago = date.today() - timedelta(days=30)
        return self.joining_date >= thirty_days_ago
    
    @property
    def is_recent_labor(self):
        """Check if labor was added recently (last 7 days)"""
        seven_days_ago = date.today() - timedelta(days=7)
        return self.joining_date >= seven_days_ago
    
    @property
    def work_experience_days(self):
        """Get work experience in days"""
        if not self.joining_date:
            return 0
        return (date.today() - self.joining_date).days
    
    @property
    def work_experience_years(self):
        """Get work experience in years"""
        return round(self.work_experience_days / 365.25, 1)
    
    @property
    def phone_country_code(self):
        """Extract country code from phone number"""
        if not self.phone_number or not self.phone_number.startswith('+'):
            return '+92'  # Default to Pakistan
        match = re.match(r'^\+(\d{1,4})', self.phone_number)
        return f"+{match.group(1)}" if match else '+92'
    
    @property
    def formatted_phone(self):
        """Get formatted phone with country code"""
        if self.phone_number and not self.phone_number.startswith('+'):
            if self.phone_number.startswith('0'):
                return f'+92{self.phone_number[1:]}'
            else:
                return f'+92{self.phone_number}'
        return self.phone_number
    
    @property
    def gender_display(self):
        """Get human-readable gender"""
        return dict(self.GENDER_CHOICES).get(self.gender, 'Unknown')
    
    # Helper methods
    def get_initials(self):
        """Get labor initials for avatar"""
        words = self.name.split()
        if len(words) >= 2:
            return f"{words[0][0]}{words[1][0]}".upper()
        elif len(words) == 1:
            return words[0][:2].upper()
        return "LA"
    
    @staticmethod
    def format_phone_number(phone):
        """Format phone number to a consistent format"""
        # Remove all non-digit characters except +
        cleaned = re.sub(r'[^\d+]', '', phone)
        
        # Handle Pakistani mobile numbers
        if cleaned.startswith('03') and len(cleaned) == 11:
            return f"+92-{cleaned[1:]}"
        elif cleaned.startswith('923') and len(cleaned) == 12:
            return f"+{cleaned[:2]}-{cleaned[2:]}"
        elif cleaned.startswith('+923') and len(cleaned) == 13:
            return f"{cleaned[:3]}-{cleaned[3:]}"
        
        return phone  # Return original if no pattern matches
    
    def soft_delete(self):
        """Soft delete the labor"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted labor"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    # Class methods
    @classmethod
    def active_labors(cls):
        """Return only active labors"""
        return cls.objects.filter(is_active=True)
    
    @classmethod
    def new_labors(cls, days=30):
        """Get labors joined within specified days"""
        cutoff_date = date.today() - timedelta(days=days)
        return cls.active_labors().filter(joining_date__gte=cutoff_date)
    
    @classmethod
    def recent_labors(cls, days=7):
        """Get recently joined labors"""
        cutoff_date = date.today() - timedelta(days=days)
        return cls.active_labors().filter(joining_date__gte=cutoff_date)
    
    @classmethod
    def labors_by_city(cls, city):
        """Get labors by city"""
        return cls.active_labors().filter(city__iexact=city)
    
    @classmethod
    def labors_by_area(cls, area):
        """Get labors by area"""
        return cls.active_labors().filter(area__iexact=area)
    
    @classmethod
    def labors_by_designation(cls, designation):
        """Get labors by designation"""
        return cls.active_labors().filter(designation__iexact=designation)
    
    @classmethod
    def get_statistics(cls):
        """Get comprehensive labor statistics"""
        active_labors = cls.active_labors()
        total_labors = active_labors.count()
        new_labors_count = cls.new_labors().count()
        recent_labors_count = cls.recent_labors().count()
        inactive_labors_count = cls.objects.filter(is_active=False).count()
        
        # Salary statistics
        salary_stats = active_labors.aggregate(
            avg_salary=models.Avg('salary'),
            min_salary=models.Min('salary'),
            max_salary=models.Max('salary'),
            total_salary_cost=models.Sum('salary')
        )
        
        # Age statistics
        age_stats = active_labors.aggregate(
            avg_age=models.Avg('age'),
            min_age=models.Min('age'),
            max_age=models.Max('age')
        )
        
        # Gender breakdown
        gender_breakdown = list(
            active_labors.values('gender')
            .annotate(count=models.Count('id'))
            .order_by('gender')
        )
        
        # Designation breakdown (top 10)
        designation_breakdown = list(
            active_labors.exclude(designation='')
            .values('designation')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        # City breakdown (top 10)
        city_breakdown = list(
            active_labors.exclude(city='')
            .values('city')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        # Caste breakdown (top 10)
        caste_breakdown = list(
            active_labors.exclude(caste='')
            .values('caste')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        return {
            'total_labors': total_labors,
            'active_labors': total_labors,
            'inactive_labors': inactive_labors_count,
            'new_labors_this_month': new_labors_count,
            'recent_labors_this_week': recent_labors_count,
            'salary_statistics': salary_stats,
            'age_statistics': age_stats,
            'gender_breakdown': gender_breakdown,
            'top_designations': designation_breakdown,
            'top_cities': city_breakdown,
            'top_castes': caste_breakdown,
        }
    
    # Payment-related methods (for future integration)
    def get_advance_payments_count(self):
        """Get total number of advance payments for this labor"""
        # This will be implemented when AdvancePayment model is available
        # return self.advance_payments.count()
        return 0
    
    def get_total_advance_amount(self):
        """Get total advance amount for this labor"""
        # This will be implemented when AdvancePayment model is available
        # return self.advance_payments.aggregate(total=models.Sum('amount'))['total'] or 0.00
        return 0.00
    
    def get_payments_count(self):
        """Get total number of payments for this labor"""
        # This will be implemented when Payment model is available
        # return self.payments.count()
        return 0
    
    def get_total_payments_amount(self):
        """Get total payments amount for this labor"""
        # This will be implemented when Payment model is available
        # return self.payments.aggregate(total=models.Sum('amount'))['total'] or 0.00
        return 0.00
    
    def get_last_payment_date(self):
        """Get date of last payment to this labor"""
        # This will be implemented when Payment model is available
        # return self.payments.order_by('-created_at').first()?.created_at
        return None
    
    def get_remaining_advance_balance(self):
        """Get remaining advance balance for this labor"""
        # This will be calculated as: total_advance - total_payments
        total_advance = self.get_total_advance_amount()
        total_payments = self.get_total_payments_amount()
        return total_advance - total_payments
    