from rest_framework import serializers
from django.db.models import Q
from .models import Product
from categories.models import Category


class ProductSerializer(serializers.ModelSerializer):
    """Complete serializer for Product model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Category details
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_id = serializers.UUIDField(source='category.id', read_only=True)
    
    # Computed fields
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',
            'price',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'category_id',
            'category_name',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'created_by', 'created_by_id',
            'category_id', 'category_name', 'stock_status', 'stock_status_display', 'total_value'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        # Remove empty strings and strip whitespace
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        if not cleaned_pieces:
            raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:  # Max value for decimal(12,2)
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        return value.strip()

    def validate_color(self, value):
        """Clean color field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Color is required.")
        return value.strip().title()

    def validate_fabric(self, value):
        """Clean fabric field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Fabric is required.")
        return value.strip().title()

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()


class ProductCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating products"""
    
    category = serializers.UUIDField(write_only=True, help_text="Category UUID")
    
    class Meta:
        model = Product
        fields = (
            'name',
            'detail',
            'price',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'category'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        if not cleaned_pieces:
            raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_category(self, value):
        """Validate category exists and is active"""
        try:
            category = Category.objects.get(id=value, is_active=True)
            return category
        except Category.DoesNotExist:
            raise serializers.ValidationError("Invalid category or category is not active.")

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        return value.strip()

    def validate_color(self, value):
        """Clean color field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Color is required.")
        return value.strip().title()

    def validate_fabric(self, value):
        """Clean fabric field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Fabric is required.")
        return value.strip().title()

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()

    def create(self, validated_data):
        """Create product with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class ProductUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating products"""
    
    category = serializers.UUIDField(write_only=True, help_text="Category UUID", required=False)
    
    class Meta:
        model = Product
        fields = (
            'name',
            'detail',
            'price',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'category'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        if not cleaned_pieces:
            raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_category(self, value):
        """Validate category exists and is active"""
        try:
            category = Category.objects.get(id=value, is_active=True)
            return category
        except Category.DoesNotExist:
            raise serializers.ValidationError("Invalid category or category is not active.")

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        return value.strip()

    def validate_color(self, value):
        """Clean color field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Color is required.")
        return value.strip().title()

    def validate_fabric(self, value):
        """Clean fabric field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Fabric is required.")
        return value.strip().title()

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()


class ProductListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing products"""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',  # Added
            'price',
            'color',
            'fabric',
            'pieces',  # Added
            'quantity',
            'category_name',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'created_by_email'
        )


class ProductDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single product view"""
    
    category = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',
            'price',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'category',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'updated_at',
            'created_by'
        )

    def get_category(self, obj):
        """Get category details"""
        return {
            'id': str(obj.category.id),
            'name': obj.category.name,
            'description': obj.category.description
        }


class ProductStatsSerializer(serializers.Serializer):
    """Serializer for product statistics"""
    
    total_products = serializers.IntegerField()
    total_inventory_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    low_stock_count = serializers.IntegerField()
    out_of_stock_count = serializers.IntegerField()
    category_breakdown = serializers.ListField()
    stock_status_summary = serializers.DictField()


class BulkQuantityUpdateSerializer(serializers.Serializer):
    """Serializer for bulk quantity updates"""
    
    updates = serializers.ListField(
        child=serializers.DictField(
            child=serializers.CharField()
        ),
        help_text="List of {product_id: new_quantity} updates"
    )

    def validate_updates(self, value):
        """Validate bulk updates"""
        if not value:
            raise serializers.ValidationError("At least one update is required.")
        
        validated_updates = []
        product_ids = []
        
        for update in value:
            if 'product_id' not in update or 'quantity' not in update:
                raise serializers.ValidationError(
                    "Each update must contain 'product_id' and 'quantity'."
                )
            
            try:
                product_id = update['product_id']
                quantity = int(update['quantity'])
                
                if quantity < 0:
                    raise serializers.ValidationError(
                        f"Quantity for product {product_id} cannot be negative."
                    )
                
                product_ids.append(product_id)
                validated_updates.append({
                    'product_id': product_id,
                    'quantity': quantity
                })
                
            except (ValueError, TypeError):
                raise serializers.ValidationError(
                    f"Invalid quantity for product {update.get('product_id', 'unknown')}."
                )
        
        # Check for duplicates
        if len(product_ids) != len(set(product_ids)):
            raise serializers.ValidationError("Duplicate product IDs found in updates.")
        
        # Verify all products exist and are active
        existing_products = Product.active_products().filter(
            id__in=product_ids
        ).values_list('id', flat=True)
        
        existing_ids = [str(pid) for pid in existing_products]
        missing_ids = [pid for pid in product_ids if pid not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Products not found or inactive: {', '.join(missing_ids)}"
            )
        
        return validated_updates
    