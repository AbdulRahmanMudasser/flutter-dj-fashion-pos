from rest_framework import serializers
from django.db.models import Q
from .models import OrderItem
from products.models import Product
from orders.models import Order


class OrderItemSerializer(serializers.ModelSerializer):
    """Complete serializer for OrderItem model"""
    
    # Order details
    order_id = serializers.UUIDField(source='order.id', read_only=True)
    
    # Product details
    product_id = serializers.UUIDField(source='product.id', read_only=True)
    product_color = serializers.CharField(source='product.color', read_only=True)
    product_fabric = serializers.CharField(source='product.fabric', read_only=True)
    current_stock = serializers.IntegerField(source='product.quantity', read_only=True)
    
    # Computed fields
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True, source='line_total')
    product_display_info = serializers.JSONField(read_only=True)
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order_id',
            'product_id',
            'product_name',
            'product_color',
            'product_fabric',
            'current_stock',
            'quantity',
            'unit_price',
            'customization_notes',
            'line_total',
            'total_value',
            'product_display_info',
            'is_active',
            'created_at',
            'updated_at'
        )
        read_only_fields = (
            'id', 'order_id', 'product_id', 'product_name', 'product_color',
            'product_fabric', 'current_stock', 'line_total', 'total_value',
            'product_display_info', 'created_at', 'updated_at'
        )

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

    def validate_unit_price(self, value):
        """Validate unit price field"""
        if value < 0:
            raise serializers.ValidationError("Unit price cannot be negative.")
        if value > 9999999999.99:  # Max value for decimal(12,2)
            raise serializers.ValidationError("Unit price is too large.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value


class OrderItemCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating order items"""
    
    order = serializers.UUIDField(write_only=True, help_text="Order UUID")
    product = serializers.UUIDField(write_only=True, help_text="Product UUID")
    
    class Meta:
        model = OrderItem
        fields = (
            'order',
            'product',
            'quantity',
            'unit_price',
            'customization_notes'
        )

    def validate_order(self, value):
        """Validate order exists and is active"""
        try:
            order = Order.objects.get(id=value, is_active=True)
            return order
        except Order.DoesNotExist:
            raise serializers.ValidationError("Invalid order or order is not active.")

    def validate_product(self, value):
        """Validate product exists and is active"""
        try:
            product = Product.objects.get(id=value, is_active=True)
            return product
        except Product.DoesNotExist:
            raise serializers.ValidationError("Invalid product or product is not active.")

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

    def validate_unit_price(self, value):
        """Validate unit price field"""
        if value < 0:
            raise serializers.ValidationError("Unit price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Unit price is too large.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value

    def validate(self, data):
        """Cross-field validation"""
        order = data.get('order')
        product = data.get('product')
        quantity = data.get('quantity')
        
        # Check if product is already in this order
        if OrderItem.objects.filter(order=order, product=product, is_active=True).exists():
            raise serializers.ValidationError({
                'product': 'This product is already in the order. Update the existing item instead.'
            })
        
        # Check if enough stock is available
        if not product.can_fulfill_quantity(quantity):
            raise serializers.ValidationError({
                'quantity': f'Not enough stock. Available: {product.quantity}, Requested: {quantity}'
            })
        
        # If unit_price not provided, use product price
        if 'unit_price' not in data or data['unit_price'] is None:
            data['unit_price'] = product.price
        
        return data

    def create(self, validated_data):
        """Create order item"""
        return super().create(validated_data)


class OrderItemUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating order items"""
    
    class Meta:
        model = OrderItem
        fields = (
            'quantity',
            'unit_price',
            'customization_notes'
        )

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        
        # Check stock availability for the quantity change
        if self.instance and self.instance.product:
            current_quantity = self.instance.quantity
            quantity_difference = value - current_quantity
            
            if quantity_difference > 0:  # Increasing quantity
                available_stock = self.instance.product.quantity
                if available_stock < quantity_difference:
                    raise serializers.ValidationError(
                        f'Not enough stock for quantity increase. '
                        f'Available: {available_stock}, Additional needed: {quantity_difference}'
                    )
        
        return value

    def validate_unit_price(self, value):
        """Validate unit price field"""
        if value < 0:
            raise serializers.ValidationError("Unit price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Unit price is too large.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value


class OrderItemListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing order items"""
    
    order_id = serializers.UUIDField(source='order.id', read_only=True)
    product_id = serializers.UUIDField(source='product.id', read_only=True)
    product_color = serializers.CharField(source='product.color', read_only=True)
    product_fabric = serializers.CharField(source='product.fabric', read_only=True)
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order_id',
            'product_id',
            'product_name',
            'product_color',
            'product_fabric',
            'quantity',
            'unit_price',
            'line_total',
            'is_active',
            'created_at'
        )


class OrderItemDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single order item view"""
    
    order = serializers.SerializerMethodField()
    product = serializers.SerializerMethodField()
    product_display_info = serializers.JSONField(read_only=True)
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order',
            'product',
            'product_name',
            'quantity',
            'unit_price',
            'customization_notes',
            'line_total',
            'product_display_info',
            'is_active',
            'created_at',
            'updated_at'
        )

    def get_order(self, obj):
        """Get order details"""
        return {
            'id': str(obj.order.id),
            'customer_name': obj.order.customer_name,
            'status': obj.order.status,
            'date_ordered': obj.order.date_ordered
        }

    def get_product(self, obj):
        """Get product details"""
        if obj.product:
            return {
                'id': str(obj.product.id),
                'name': obj.product.name,
                'color': obj.product.color,
                'fabric': obj.product.fabric,
                'current_price': obj.product.price,
                'current_stock': obj.product.quantity
            }
        return {
            'name': obj.product_name,
            'note': 'Product no longer available'
        }


class OrderItemStatsSerializer(serializers.Serializer):
    """Serializer for order item statistics"""
    
    total_items = serializers.IntegerField()
    total_quantity_ordered = serializers.IntegerField()
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    average_quantity_per_item = serializers.DecimalField(max_digits=10, decimal_places=2)
    average_unit_price = serializers.DecimalField(max_digits=12, decimal_places=2)
    top_products = serializers.ListField()


class OrderItemBulkUpdateSerializer(serializers.Serializer):
    """Serializer for bulk order item updates"""
    
    updates = serializers.ListField(
        child=serializers.DictField(
            child=serializers.CharField()
        ),
        help_text="List of {order_item_id: {field: value}} updates"
    )

    def validate_updates(self, value):
        """Validate bulk updates"""
        if not value:
            raise serializers.ValidationError("At least one update is required.")
        
        validated_updates = []
        item_ids = []
        
        for update in value:
            if 'order_item_id' not in update:
                raise serializers.ValidationError(
                    "Each update must contain 'order_item_id'."
                )
            
            order_item_id = update['order_item_id']
            item_ids.append(order_item_id)
            
            # Validate update fields
            allowed_fields = ['quantity', 'unit_price', 'customization_notes']
            update_fields = {k: v for k, v in update.items() if k != 'order_item_id'}
            
            if not update_fields:
                raise serializers.ValidationError(
                    f"No valid fields to update for item {order_item_id}."
                )
            
            for field in update_fields.keys():
                if field not in allowed_fields:
                    raise serializers.ValidationError(
                        f"Field '{field}' is not allowed for bulk update."
                    )
            
            # Validate field values
            if 'quantity' in update_fields:
                try:
                    quantity = int(update_fields['quantity'])
                    if quantity <= 0:
                        raise ValueError
                    update_fields['quantity'] = quantity
                except (ValueError, TypeError):
                    raise serializers.ValidationError(
                        f"Invalid quantity for item {order_item_id}."
                    )
            
            if 'unit_price' in update_fields:
                try:
                    unit_price = float(update_fields['unit_price'])
                    if unit_price < 0:
                        raise ValueError
                    update_fields['unit_price'] = unit_price
                except (ValueError, TypeError):
                    raise serializers.ValidationError(
                        f"Invalid unit price for item {order_item_id}."
                    )
            
            validated_updates.append({
                'order_item_id': order_item_id,
                'fields': update_fields
            })
        
        # Check for duplicates
        if len(item_ids) != len(set(item_ids)):
            raise serializers.ValidationError("Duplicate order item IDs found in updates.")
        
        # Verify all order items exist and are active
        existing_items = OrderItem.objects.filter(
            id__in=item_ids,
            is_active=True
        ).values_list('id', flat=True)
        
        existing_ids = [str(item_id) for item_id in existing_items]
        missing_ids = [item_id for item_id in item_ids if item_id not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Order items not found or inactive: {', '.join(missing_ids)}"
            )
        
        return validated_updates


class OrderItemQuantityUpdateSerializer(serializers.Serializer):
    """Serializer for updating order item quantity"""
    
    quantity = serializers.IntegerField(min_value=1, help_text="New quantity")

    def validate_quantity(self, value):
        """Validate quantity with stock check"""
        # This validation will be context-dependent and handled in the view
        return value
    