import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from decimal import Decimal
import json


class Product(models.Model):
    """Product model for inventory management"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    name = models.CharField(
        max_length=200,
        help_text="Product name"
    )
    detail = models.TextField(
        help_text="Product description/details"
    )
    price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Product price in PKR"
    )
    color = models.CharField(
        max_length=50,
        help_text="Product color"
    )
    fabric = models.CharField(
        max_length=100,
        help_text="Fabric type/material"
    )
    pieces = models.JSONField(
        default=list,
        help_text="Array of product pieces (e.g., ['Blouse', 'Lehenga', 'Dupatta'])"
    )
    quantity = models.PositiveIntegerField(
        default=0,
        help_text="Available quantity in stock"
    )
    category = models.ForeignKey(
        'categories.Category',
        on_delete=models.PROTECT,
        related_name='products',
        help_text="Product category"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion. Inactive products won't appear in lists"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_products',
        help_text="User who created this product"
    )

    class Meta:
        db_table = 'product'
        verbose_name = 'Product'
        verbose_name_plural = 'Products'
        ordering = ['-created_at', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['category']),
            models.Index(fields=['quantity']),
            models.Index(fields=['price']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.name} - {self.color} ({self.fabric})"

    def clean(self):
        """Validate model data"""
        if self.price and self.price < 0:
            raise ValidationError({'price': 'Price cannot be negative.'})
        
        if self.quantity < 0:
            raise ValidationError({'quantity': 'Quantity cannot be negative.'})
        
        # Validate pieces is a list
        if self.pieces and not isinstance(self.pieces, list):
            raise ValidationError({'pieces': 'Pieces must be a list.'})
        
        # Validate each piece is a string
        if self.pieces:
            for piece in self.pieces:
                if not isinstance(piece, str):
                    raise ValidationError({'pieces': 'Each piece must be a string.'})

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def stock_status(self):
        """Get stock status based on quantity"""
        if self.quantity is None:
            return 'UNKNOWN'
        elif self.quantity == 0:
            return 'OUT_OF_STOCK'
        elif self.quantity <= 5:
            return 'LOW_STOCK'
        elif self.quantity <= 20:
            return 'MEDIUM_STOCK'
        else:
            return 'HIGH_STOCK'

    @property
    def stock_status_display(self):
        """Human readable stock status"""
        status_map = {
            'OUT_OF_STOCK': 'Out of Stock',
            'LOW_STOCK': 'Low Stock',
            'MEDIUM_STOCK': 'Medium Stock',
            'HIGH_STOCK': 'In Stock',
            'UNKNOWN': 'Unknown'
        }
        return status_map.get(self.stock_status, 'Unknown')

    @property
    def total_value(self):
        """Calculate total inventory value for this product"""
        if self.price is None:
            return Decimal('0.00')
        return self.price * self.quantity

    def soft_delete(self):
        """Soft delete the product by setting is_active to False"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])

    def restore(self):
        """Restore a soft-deleted product"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])

    def update_quantity(self, new_quantity, user=None):
        """Update product quantity with optional user tracking"""
        old_quantity = self.quantity
        self.quantity = new_quantity
        self.save(update_fields=['quantity', 'updated_at'])
        
        # You can extend this to log quantity changes if needed
        return {
            'old_quantity': old_quantity,
            'new_quantity': new_quantity,
            'difference': new_quantity - old_quantity
        }

    def is_low_stock(self, threshold=5):
        """Check if product is low in stock"""
        if self.quantity is None:
            return False
        return 0 < self.quantity <= threshold

    def can_fulfill_quantity(self, requested_quantity):
        """Check if we have enough stock for requested quantity"""
        if self.quantity is None:
            return False
        return self.quantity >= requested_quantity

    @classmethod
    def active_products(cls):
        """Return only active products"""
        return cls.objects.filter(is_active=True)

    @classmethod
    def low_stock_products(cls, threshold=5):
        """Get products with low stock"""
        return cls.active_products().filter(
            quantity__gt=0,
            quantity__lte=threshold
        )

    @classmethod
    def out_of_stock_products(cls):
        """Get products that are out of stock"""
        return cls.active_products().filter(quantity=0)

    @classmethod
    def products_by_category(cls, category_id):
        """Get active products by category"""
        return cls.active_products().filter(category_id=category_id)

    @classmethod
    def get_statistics(cls):
        """Get inventory statistics"""
        active_products = cls.active_products()
        
        total_products = active_products.count()
        
        # Calculate total value safely
        total_value = Decimal('0.00')
        for product in active_products:
            if product.price is not None and product.quantity is not None:
                total_value += product.price * product.quantity
        
        low_stock_count = cls.low_stock_products().count()
        out_of_stock_count = cls.out_of_stock_products().count()
        
        # Category breakdown
        from django.db.models import Count, Sum, Case, When, DecimalField
        category_stats = active_products.values(
            'category__name'
        ).annotate(
            count=Count('id'),
            total_quantity=Sum('quantity'),
            total_value=Sum(
                Case(
                    When(price__isnull=False, quantity__isnull=False, 
                         then=models.F('price') * models.F('quantity')),
                    default=0,
                    output_field=DecimalField(max_digits=15, decimal_places=2)
                )
            )
        ).order_by('-count')

        return {
            'total_products': total_products,
            'total_inventory_value': float(total_value),
            'low_stock_count': low_stock_count,
            'out_of_stock_count': out_of_stock_count,
            'category_breakdown': list(category_stats),
            'stock_status_summary': {
                'in_stock': active_products.filter(quantity__gt=20).count(),
                'medium_stock': active_products.filter(quantity__gt=5, quantity__lte=20).count(),
                'low_stock': low_stock_count,
                'out_of_stock': out_of_stock_count,
            }
        }


class ProductQuerySet(models.QuerySet):
    """Custom QuerySet for Product model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def by_category(self, category_id):
        return self.filter(category_id=category_id)
    
    def search(self, query):
        """Search products by name, color, fabric, or category name"""
        return self.filter(
            models.Q(name__icontains=query) |
            models.Q(color__icontains=query) |
            models.Q(fabric__icontains=query) |
            models.Q(category__name__icontains=query)
        )
    
    def price_range(self, min_price=None, max_price=None):
        """Filter products by price range"""
        queryset = self
        if min_price is not None:
            queryset = queryset.filter(price__gte=min_price)
        if max_price is not None:
            queryset = queryset.filter(price__lte=max_price)
        return queryset
    
    def stock_level(self, level):
        """Filter by stock level"""
        if level == 'OUT_OF_STOCK':
            return self.filter(quantity=0)
        elif level == 'LOW_STOCK':
            return self.filter(quantity__gt=0, quantity__lte=5)
        elif level == 'MEDIUM_STOCK':
            return self.filter(quantity__gt=5, quantity__lte=20)
        elif level == 'HIGH_STOCK':
            return self.filter(quantity__gt=20)
        return self


# Add the custom manager to the Product model
Product.add_to_class('objects', models.Manager.from_queryset(ProductQuerySet)())
    