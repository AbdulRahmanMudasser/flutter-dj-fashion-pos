import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String detail;
  final double price;
  final String color;
  final String fabric;
  final List<String> pieces;
  final int quantity;
  final String? categoryId;
  final String? categoryName;
  final String stockStatus;
  final String stockStatusDisplay;
  final double totalValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final int? createdById;
  final String? createdByEmail;

  const Product({
    required this.id,
    required this.name,
    required this.detail,
    required this.price,
    required this.color,
    required this.fabric,
    required this.pieces,
    required this.quantity,
    this.categoryId,
    this.categoryName,
    required this.stockStatus,
    required this.stockStatusDisplay,
    required this.totalValue,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdById,
    this.createdByEmail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      detail: json['detail'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      color: json['color'] as String,
      fabric: json['fabric'] as String,
      pieces: List<String>.from(json['pieces'] as List? ?? []),
      quantity: json['quantity'] as int? ?? 0,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      stockStatus: json['stock_status'] as String? ?? 'UNKNOWN',
      stockStatusDisplay: json['stock_status_display'] as String? ?? 'Unknown',
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdById: json['created_by_id'] as int?,
      createdByEmail: json['created_by_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'detail': detail,
      'price': price,
      'color': color,
      'fabric': fabric,
      'pieces': pieces,
      'quantity': quantity,
      'category_id': categoryId,
      'category_name': categoryName,
      'stock_status': stockStatus,
      'stock_status_display': stockStatusDisplay,
      'total_value': totalValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_by_id': createdById,
      'created_by_email': createdByEmail,
    };
  }

  // Helper getters
  String get formattedPrice => 'PKR ${price.toStringAsFixed(0)}';
  String get formattedTotalValue => 'PKR ${totalValue.toStringAsFixed(0)}';

  bool get isOutOfStock => stockStatus == 'OUT_OF_STOCK';
  bool get isLowStock => stockStatus == 'LOW_STOCK';
  bool get isMediumStock => stockStatus == 'MEDIUM_STOCK';
  bool get isHighStock => stockStatus == 'HIGH_STOCK';

  Color get stockStatusColor {
    switch (stockStatus) {
      case 'OUT_OF_STOCK':
        return Colors.red;
      case 'LOW_STOCK':
        return Colors.orange;
      case 'MEDIUM_STOCK':
        return Colors.yellow[700]!;
      case 'HIGH_STOCK':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get stockStatusText => stockStatusDisplay;
  String get piecesText => pieces.join(', ');

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? detail,
    double? price,
    String? color,
    String? fabric,
    List<String>? pieces,
    int? quantity,
    String? categoryId,
    String? categoryName,
    String? stockStatus,
    String? stockStatusDisplay,
    double? totalValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? createdById,
    String? createdByEmail,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      price: price ?? this.price,
      color: color ?? this.color,
      fabric: fabric ?? this.fabric,
      pieces: pieces ?? this.pieces,
      quantity: quantity ?? this.quantity,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stockStatus: stockStatus ?? this.stockStatus,
      stockStatusDisplay: stockStatusDisplay ?? this.stockStatusDisplay,
      totalValue: totalValue ?? this.totalValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      createdByEmail: createdByEmail ?? this.createdByEmail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product(id: $id, name: $name, quantity: $quantity)';
}

// Product API Response Models
class ProductsListResponse {
  final List<Product> products;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  ProductsListResponse({
    required this.products,
    required this.pagination,
    this.filtersApplied,
  });

  factory ProductsListResponse.fromJson(Map<String, dynamic> json) {
    return ProductsListResponse(
      products: (json['products'] as List? ?? [])
          .map((productJson) => Product.fromJson(productJson))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters_applied': filtersApplied,
    };
  }
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'page_size': pageSize,
      'total_count': totalCount,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}

class ProductCreateRequest {
  final String name;
  final String detail;
  final double price;
  final String color;
  final String fabric;
  final List<String> pieces;
  final int quantity;
  final String category; // Category UUID

  ProductCreateRequest({
    required this.name,
    required this.detail,
    required this.price,
    required this.color,
    required this.fabric,
    required this.pieces,
    required this.quantity,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'detail': detail,
      'price': price,
      'color': color,
      'fabric': fabric,
      'pieces': pieces,
      'quantity': quantity,
      'category': category,
    };
  }
}

class ProductUpdateRequest {
  final String? name;
  final String? detail;
  final double? price;
  final String? color;
  final String? fabric;
  final List<String>? pieces;
  final int? quantity;
  final String? category; // Category UUID

  ProductUpdateRequest({
    this.name,
    this.detail,
    this.price,
    this.color,
    this.fabric,
    this.pieces,
    this.quantity,
    this.category,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (detail != null) data['detail'] = detail;
    if (price != null) data['price'] = price;
    if (color != null) data['color'] = color;
    if (fabric != null) data['fabric'] = fabric;
    if (pieces != null) data['pieces'] = pieces;
    if (quantity != null) data['quantity'] = quantity;
    if (category != null) data['category'] = category;
    return data;
  }
}

class ProductFilters {
  final String? search;
  final String? categoryId;
  final String? color;
  final String? fabric;
  final String? stockLevel;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final String sortOrder;

  const ProductFilters({
    this.search,
    this.categoryId,
    this.color,
    this.fabric,
    this.stockLevel,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'name',
    this.sortOrder = 'asc',
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (categoryId != null && categoryId!.isNotEmpty) params['category_id'] = categoryId!;
    if (color != null && color!.isNotEmpty) params['color'] = color!;
    if (fabric != null && fabric!.isNotEmpty) params['fabric'] = fabric!;
    if (stockLevel != null && stockLevel!.isNotEmpty) params['stock_level'] = stockLevel!;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    params['sort_by'] = sortBy;
    params['sort_order'] = sortOrder;

    return params;
  }

  ProductFilters copyWith({
    String? search,
    String? categoryId,
    String? color,
    String? fabric,
    String? stockLevel,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      fabric: fabric ?? this.fabric,
      stockLevel: stockLevel ?? this.stockLevel,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ProductStatistics {
  final int totalProducts;
  final double totalInventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final List<CategoryStats> categoryBreakdown;
  final StockStatusSummary stockStatusSummary;

  const ProductStatistics({
    required this.totalProducts,
    required this.totalInventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categoryBreakdown,
    required this.stockStatusSummary,
  });

  factory ProductStatistics.fromJson(Map<String, dynamic> json) {
    return ProductStatistics(
      totalProducts: json['total_products'] as int? ?? 0,
      totalInventoryValue: (json['total_inventory_value'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      outOfStockCount: json['out_of_stock_count'] as int? ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List? ?? [])
          .map((item) => CategoryStats.fromJson(item))
          .toList(),
      stockStatusSummary: StockStatusSummary.fromJson(
          json['stock_status_summary'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'total_inventory_value': totalInventoryValue,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'category_breakdown': categoryBreakdown.map((item) => item.toJson()).toList(),
      'stock_status_summary': stockStatusSummary.toJson(),
    };
  }
}

class CategoryStats {
  final String categoryName;
  final int count;
  final int totalQuantity;
  final double? totalValue;

  const CategoryStats({
    required this.categoryName,
    required this.count,
    required this.totalQuantity,
    this.totalValue,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      categoryName: json['category__name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalQuantity: json['total_quantity'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category__name': categoryName,
      'count': count,
      'total_quantity': totalQuantity,
      'total_value': totalValue,
    };
  }
}

class StockStatusSummary {
  final int inStock;
  final int mediumStock;
  final int lowStock;
  final int outOfStock;

  const StockStatusSummary({
    required this.inStock,
    required this.mediumStock,
    required this.lowStock,
    required this.outOfStock,
  });

  factory StockStatusSummary.fromJson(Map<String, dynamic> json) {
    return StockStatusSummary(
      inStock: json['in_stock'] as int? ?? 0,
      mediumStock: json['medium_stock'] as int? ?? 0,
      lowStock: json['low_stock'] as int? ?? 0,
      outOfStock: json['out_of_stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in_stock': inStock,
      'medium_stock': mediumStock,
      'low_stock': lowStock,
      'out_of_stock': outOfStock,
    };
  }
}

class BulkQuantityUpdate {
  final List<QuantityUpdateItem> updates;

  BulkQuantityUpdate({required this.updates});

  Map<String, dynamic> toJson() {
    return {
      'updates': updates.map((item) => item.toJson()).toList(),
    };
  }
}

class QuantityUpdateItem {
  final String productId;
  final int quantity;

  QuantityUpdateItem({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity.toString(),
    };
  }
}
