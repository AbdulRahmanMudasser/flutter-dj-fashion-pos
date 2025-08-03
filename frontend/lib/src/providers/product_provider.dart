import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import '../models/category/category_model.dart';
import '../models/product/product_model.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // State variables
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  ProductStatistics? _statistics;

  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasMore = false;

  // Filters
  ProductFilters _currentFilters = const ProductFilters();

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  ProductStatistics? get statistics => _statistics;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;
  ProductFilters get currentFilters => _currentFilters;

  // Available options for dropdowns
  final List<String> availableColors = [
    'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple', 'Pink', 'Black',
    'White', 'Brown', 'Gray', 'Navy', 'Maroon', 'Gold', 'Silver', 'Beige'
  ];

  final List<String> availableFabrics = [
    'Cotton', 'Silk', 'Chiffon', 'Georgette', 'Net', 'Velvet', 'Satin',
    'Organza', 'Crepe', 'Linen', 'Jacquard', 'Brocade', 'Lawn', 'Khaddar'
  ];

  final List<String> availablePieces = [
    'Blouse', 'Lehenga', 'Dupatta', 'Shirt', 'Trouser', 'Kurta', 'Palazzo',
    'Scarf', 'Veil', 'Jacket', 'Waistcoat', 'Sharara', 'Gharara'
  ];

  final List<String> stockLevels = [
    'HIGH_STOCK', 'MEDIUM_STOCK', 'LOW_STOCK', 'OUT_OF_STOCK'
  ];

  final List<String> sortOptions = [
    'name', 'price', 'quantity', 'created_at', 'updated_at'
  ];

  /// Initialize provider - load data
  Future<void> initialize() async {
    await loadCategories();
    await loadProducts();
    await loadStatistics();
  }

  /// Load categories for dropdown
  Future<void> loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      if (response.success && response.data != null) {
        _categories = response.data!.categories;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load products with pagination and filters
  Future<void> loadProducts({
    int page = 1,
    bool append = false,
    bool showInactive = false,
  }) async {
    if (!append) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _productService.getProducts(
        page: page,
        pageSize: 20,
        filters: _currentFilters,
        showInactive: showInactive,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (append) {
          _products.addAll(data.products);
        } else {
          _products = data.products;
        }

        _currentPage = data.pagination.currentPage;
        _totalPages = data.pagination.totalPages;
        _totalCount = data.pagination.totalCount;
        _hasMore = data.pagination.hasNext;

        _applyLocalFilters();
        _errorMessage = null;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_hasMore && !_isLoading) {
      await loadProducts(page: _currentPage + 1, append: true);
    }
  }

  /// Refresh products
  Future<void> refreshProducts() async {
    _currentPage = 1;
    await loadProducts();
    await loadStatistics();
  }

  /// Load product statistics
  Future<void> loadStatistics() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      final response = await _productService.getProductStatistics();
      if (response.success && response.data != null) {
        _statistics = response.data!;
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _currentFilters = _currentFilters.copyWith(search: query.isEmpty ? null : query);
    _applyLocalFilters();

    // Optionally trigger API search for better results
    if (query.length > 2 || query.isEmpty) {
      _debounceSearch();
    }
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      loadProducts();
    });
  }

  /// Apply filters
  void applyFilters(ProductFilters filters) {
    _currentFilters = filters;
    loadProducts();
  }

  /// Clear filters
  void clearFilters() {
    _currentFilters = const ProductFilters();
    _searchQuery = '';
    loadProducts();
  }

  /// Apply local filters (for cached data)
  void _applyLocalFilters() {
    _filteredProducts = _products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.detail.toLowerCase().contains(query) &&
            !product.color.toLowerCase().contains(query) &&
            !product.fabric.toLowerCase().contains(query) &&
            !product.piecesText.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// Add new product
  Future<bool> addProduct({
    required String name,
    required String detail,
    required double price,
    required String color,
    required String fabric,
    required List<String> pieces,
    required int quantity,
    required String categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _productService.createProduct(
        name: name,
        detail: detail,
        price: price,
        color: color,
        fabric: fabric,
        pieces: pieces,
        quantity: quantity,
        categoryId: categoryId,
      );

      if (response.success && response.data != null) {
        _products.insert(0, response.data!); // Add to beginning
        _applyLocalFilters();
        await loadStatistics(); // Refresh stats
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to add product: $e';
      debugPrint('Error adding product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing product
  Future<bool> updateProduct({
    required String id,
    String? name,
    String? detail,
    double? price,
    String? color,
    String? fabric,
    List<String>? pieces,
    int? quantity,
    String? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _productService.updateProduct(
        id: id,
        name: name,
        detail: detail,
        price: price,
        color: color,
        fabric: fabric,
        pieces: pieces,
        quantity: quantity,
        categoryId: categoryId,
      );

      if (response.success && response.data != null) {
        final index = _products.indexWhere((product) => product.id == id);
        if (index != -1) {
          _products[index] = response.data!;
          _applyLocalFilters();
          await loadStatistics(); // Refresh stats
        }
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      debugPrint('Error updating product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _productService.deleteProduct(id);

      if (response.success) {
        _products.removeWhere((product) => product.id == id);
        _applyLocalFilters();
        await loadStatistics(); // Refresh stats
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      debugPrint('Error deleting product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update product quantity
  Future<bool> updateProductQuantity(String id, int newQuantity) async {
    try {
      final response = await _productService.updateProductQuantity(
        productId: id,
        newQuantity: newQuantity,
      );

      if (response.success) {
        final index = _products.indexWhere((product) => product.id == id);
        if (index != -1) {
          _products[index] = _products[index].copyWith(
            quantity: newQuantity,
            updatedAt: DateTime.now(),
          );
          _applyLocalFilters();
          await loadStatistics(); // Refresh stats
        }
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity: $e';
      debugPrint('Error updating quantity: $e');
      return false;
    }
  }

  /// Bulk update quantities
  Future<bool> bulkUpdateQuantities(Map<String, int> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updateItems = updates.entries.map((entry) =>
          QuantityUpdateItem(productId: entry.key, quantity: entry.value)
      ).toList();

      final response = await _productService.bulkUpdateQuantities(updates: updateItems);

      if (response.success) {
        // Update local cache
        for (final entry in updates.entries) {
          final index = _products.indexWhere((product) => product.id == entry.key);
          if (index != -1) {
            _products[index] = _products[index].copyWith(
              quantity: entry.value,
              updatedAt: DateTime.now(),
            );
          }
        }
        _applyLocalFilters();
        await loadStatistics(); // Refresh stats
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to bulk update: $e';
      debugPrint('Error bulk updating: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    try {
      final response = await _productService.getLowStockProducts(threshold: threshold);
      if (response.success && response.data != null) {
        return response.data!.products;
      }
    } catch (e) {
      debugPrint('Error getting low stock products: $e');
    }
    return [];
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _productService.getProductsByCategory(categoryId: categoryId);
      if (response.success && response.data != null) {
        return response.data!.products;
      }
    } catch (e) {
      debugPrint('Error getting products by category: $e');
    }
    return [];
  }

  /// Duplicate product
  Future<bool> duplicateProduct(String id, {String? newName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _productService.duplicateProduct(
        productId: id,
        newName: newName,
      );

      if (response.success && response.data != null) {
        _products.insert(0, response.data!); // Add to beginning
        _applyLocalFilters();
        await loadStatistics(); // Refresh stats
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to duplicate product: $e';
      debugPrint('Error duplicating product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get product statistics as map (for compatibility with existing UI)
  Map<String, dynamic> get productStats {
    if (_statistics == null) {
      return {
        'total': 0,
        'inStock': 0,
        'lowStock': 0,
        'outOfStock': 0,
        'totalValue': '0',
        'averagePrice': '0',
      };
    }

    final stats = _statistics!;
    final inStockCount = stats.stockStatusSummary.inStock + stats.stockStatusSummary.mediumStock;
    final averagePrice = stats.totalProducts > 0
        ? stats.totalInventoryValue / stats.totalProducts
        : 0.0;

    return {
      'total': stats.totalProducts,
      'inStock': inStockCount,
      'lowStock': stats.lowStockCount,
      'outOfStock': stats.outOfStockCount,
      'totalValue': stats.totalInventoryValue.toStringAsFixed(0),
      'averagePrice': averagePrice.toStringAsFixed(0),
    };
  }

  /// Export product data
  List<Map<String, dynamic>> exportProductData() {
    return _products.map((product) => {
      'Product ID': product.id,
      'Name': product.name,
      'Detail': product.detail,
      'Price': product.price.toStringAsFixed(2),
      'Color': product.color,
      'Fabric': product.fabric,
      'Pieces': product.piecesText,
      'Quantity': product.quantity.toString(),
      'Stock Status': product.stockStatusText,
      'Category': product.categoryName ?? '',
      'Created Date': product.createdAt.toString().split(' ')[0],
      'Updated Date': product.updatedAt?.toString().split(' ')[0] ?? '',
      'Total Value': product.totalValue.toStringAsFixed(2),
    }).toList();
  }

  /// Get products that need attention (low/out of stock)
  List<Product> get productsNeedingAttention {
    return _products.where((product) =>
    product.isLowStock || product.isOutOfStock
    ).toList();
  }

  /// Get inventory summary
  Map<String, dynamic> get inventorySummary {
    final totalProducts = _products.length;
    final totalQuantity = _products.fold<int>(0, (sum, product) => sum + product.quantity);
    final totalValue = _products.fold<double>(0, (sum, product) => sum + product.totalValue);
    final averageValue = totalProducts > 0 ? totalValue / totalProducts : 0.0;
    final inStockProducts = _products.where((p) => !p.isOutOfStock).length;

    return {
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      'averageValue': averageValue,
      'stockHealthPercentage': totalProducts > 0 ? (inStockProducts / totalProducts * 100) : 0,
    };
  }

  /// Get product statistics by category
  Map<String, dynamic> getProductStatsByCategory() {
    final Map<String, int> colorStats = {};
    final Map<String, int> fabricStats = {};
    final Map<String, double> colorValue = {};
    final Map<String, double> fabricValue = {};

    for (final product in _products) {
      // Color statistics
      colorStats[product.color] = (colorStats[product.color] ?? 0) + 1;
      colorValue[product.color] = (colorValue[product.color] ?? 0) + product.totalValue;

      // Fabric statistics
      fabricStats[product.fabric] = (fabricStats[product.fabric] ?? 0) + 1;
      fabricValue[product.fabric] = (fabricValue[product.fabric] ?? 0) + product.totalValue;
    }

    return {
      'colorStats': colorStats,
      'fabricStats': fabricStats,
      'colorValue': colorValue,
      'fabricValue': fabricValue,
    };
  }

  /// Filter products locally
  List<Product> filterProducts({
    String? color,
    String? fabric,
    double? minPrice,
    double? maxPrice,
    int? minQuantity,
    int? maxQuantity,
    bool? isLowStock,
    bool? isOutOfStock,
    String? categoryId,
  }) {
    return _products.where((product) {
      if (color != null && product.color != color) return false;
      if (fabric != null && product.fabric != fabric) return false;
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      if (minQuantity != null && product.quantity < minQuantity) return false;
      if (maxQuantity != null && product.quantity > maxQuantity) return false;
      if (isLowStock != null && product.isLowStock != isLowStock) return false;
      if (isOutOfStock != null && product.isOutOfStock != isOutOfStock) return false;
      if (categoryId != null && product.categoryId != categoryId) return false;
      return true;
    }).toList();
  }

  /// Sort products
  void sortProducts(String sortBy, {bool ascending = true}) {
    _products.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
          comparison = (a.updatedAt ?? a.createdAt).compareTo(b.updatedAt ?? b.createdAt);
          break;
        case 'total_value':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }

      return ascending ? comparison : -comparison;
    });

    _applyLocalFilters();
  }

  /// Get recent products
  List<Product> get recentProducts {
    final recent = List<Product>.from(_products);
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recent.take(10).toList();
  }

  /// Get top value products
  List<Product> get topValueProducts {
    final sortedProducts = List<Product>.from(_products);
    sortedProducts.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return sortedProducts.take(5).toList();
  }

  /// Get products by status
  Map<String, List<Product>> get productsByStatus => {
    'inStock': _products.where((p) => p.isHighStock || p.isMediumStock).toList(),
    'lowStock': _products.where((p) => p.isLowStock).toList(),
    'outOfStock': _products.where((p) => p.isOutOfStock).toList(),
  };

  /// Get product analytics
  Map<String, dynamic> get productAnalytics {
    final totalInventoryValue = _products.fold<double>(0, (sum, product) => sum + product.totalValue);
    final averageQuantity = _products.isNotEmpty
        ? _products.fold<int>(0, (sum, product) => sum + product.quantity) / _products.length
        : 0.0;

    final inStockProducts = _products.where((p) => !p.isOutOfStock).toList();
    final stockTurnoverRate = _products.isNotEmpty
        ? (inStockProducts.length / _products.length * 100)
        : 0.0;

    final outOfStockProducts = _products.where((p) => p.isOutOfStock).toList();
    final outOfStockRate = _products.isNotEmpty
        ? (outOfStockProducts.length / _products.length * 100)
        : 0.0;

    return {
      'totalInventoryValue': totalInventoryValue,
      'averageQuantity': averageQuantity,
      'stockTurnoverRate': stockTurnoverRate,
      'outOfStockRate': outOfStockRate,
      'totalProductValue': _products.fold<double>(0, (sum, product) => sum + product.price),
      'lowStockValue': _products.where((p) => p.isLowStock).fold<double>(0, (sum, product) => sum + product.totalValue),
    };
  }

  /// Clear all data
  void clearData() {
    _products.clear();
    _filteredProducts.clear();
    _categories.clear();
    _statistics = null;
    _searchQuery = '';
    _currentFilters = const ProductFilters();
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _hasMore = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh data from server
  Future<void> refreshFromServer() async {
    clearData();
    await initialize();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
