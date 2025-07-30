import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/sales/product_options_menu.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/providers/product_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import 'add_to_cart_dialog.dart';
import 'custom_order_dialog.dart';
import 'existing_orders_dialog.dart';
import 'customize_and_add_dialog.dart';

class ProductGrid extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;

  const ProductGrid({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      child: Consumer<SalesProvider>(
        builder: (context, provider, child) {
          final filteredProducts = _getFilteredProducts(provider);

          if (provider.isLoading) {
            return Center(
              child: SizedBox(
                width: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 8.w,
                  small: 6.w,
                  medium: 5.w,
                  large: 4.w,
                  ultrawide: 3.w,
                ),
                height: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 8.w,
                  small: 6.w,
                  medium: 5.w,
                  large: 4.w,
                  ultrawide: 3.w,
                ),
                child: const CircularProgressIndicator(
                  color: AppTheme.primaryMaroon,
                  strokeWidth: 3,
                ),
              ),
            );
          }

          if (filteredProducts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Calculate fixed card width for horizontal scrolling
          final cardWidth = ResponsiveBreakpoints.responsive(
            context,
            tablet: 180.0,
            small: 200.0,
            medium: 220.0,
            large: 240.0,
            ultrawide: 260.0,
          );

          final cardHeight = ResponsiveBreakpoints.responsive(
            context,
            tablet: 240.0,
            small: 320.0,
            medium: 310.0,
            large: 310.0,
            ultrawide: 340.0,
          );

          // Calculate how many rows we need based on products
          final productsPerRow = ResponsiveBreakpoints.responsive(
            context,
            tablet: 3,
            small: 4,
            medium: 5,
            large: 6,
            ultrawide: 7,
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: context.cardPadding),
            child: SizedBox(
              width: (cardWidth + context.cardPadding) * productsPerRow,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: productsPerRow,
                  childAspectRatio: cardWidth / cardHeight,
                  crossAxisSpacing: context.cardPadding,
                  mainAxisSpacing: context.cardPadding,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _buildEnhancedProductCard(context, product, provider),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<Product> _getFilteredProducts(SalesProvider provider) {
    var products = provider.products;

    // Apply category filter
    if (selectedCategory != 'All') {
      products = products.where((product) => product.fabric == selectedCategory).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      products = products.where((product) =>
      product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.detail.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.color.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.fabric.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.piecesText.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    return products;
  }

  Widget _buildEnhancedProductCard(BuildContext context, Product product, SalesProvider provider) {
    final isOutOfStock = product.quantity <= 0;
    final isLowStock = product.quantity <= 5 && product.quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur('light'),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOutOfStock ? null : () => _showEnhancedAddToCartDialog(context, product, provider),
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.all(context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Actions
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(product.fabric),
                              size: context.iconSize('xl'),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: context.smallPadding / 2),
                            Text(
                              product.fabric,
                              style: GoogleFonts.inter(
                                fontSize: context.captionFontSize,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Actions Row
                      if (!isOutOfStock)
                        Positioned(
                          top: context.smallPadding / 2,
                          left: context.smallPadding / 2,
                          right: context.smallPadding / 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Discount Badge
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showDiscountDialog(context, product, provider),
                                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.smallPadding / 2,
                                      vertical: context.smallPadding / 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_offer_rounded,
                                          color: AppTheme.pureWhite,
                                          size: context.iconSize('small') * 0.8,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          '%',
                                          style: GoogleFonts.inter(
                                            fontSize: context.captionFontSize * 0.7,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.pureWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Stock Status Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.smallPadding / 2,
                                  vertical: context.smallPadding / 4,
                                ),
                                decoration: BoxDecoration(
                                  color: product.stockStatusColor,
                                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                ),
                                child: Text(
                                  product.quantity.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: context.captionFontSize * 0.8,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Existing Order Indicator
                      Positioned(
                        bottom: context.smallPadding / 2,
                        right: context.smallPadding / 2,
                        child: _buildExistingOrderIndicator(context, product, provider),
                      ),

                      // Out of Stock Overlay
                      if (isOutOfStock)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(context.borderRadius('small')),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: context.iconSize('large'),
                                  color: AppTheme.pureWhite,
                                ),
                                SizedBox(height: context.smallPadding / 2),
                                Text(
                                  'Out of Stock',
                                  style: GoogleFonts.inter(
                                    fontSize: context.captionFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: context.smallPadding),

                // Product Details
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name with Category Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.inter(
                                fontSize: context.bodyFontSize * 0.9,
                                fontWeight: FontWeight.w600,
                                color: isOutOfStock ? Colors.grey[500] : AppTheme.charcoalGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isOutOfStock)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.smallPadding / 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(product.fabric).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                              ),
                              child: Text(
                                _getCategoryAbbreviation(product.fabric),
                                style: GoogleFonts.inter(
                                  fontSize: context.captionFontSize * 0.8,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(product.fabric),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: context.smallPadding / 2),

                      // Color, Pieces, and Custom Options
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getColorFromName(product.color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: context.smallPadding / 2),
                          Expanded(
                            child: Text(
                              '${product.color} • ${product.pieces.length} pcs',
                              style: GoogleFonts.inter(
                                fontSize: context.captionFontSize * 0.9,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isCustomizable(product))
                            Icon(
                              Icons.tune_rounded,
                              size: context.iconSize('small') * 0.8,
                              color: AppTheme.primaryMaroon,
                            ),
                        ],
                      ),

                      SizedBox(height: context.smallPadding / 2),

                      // Price with Original Price if Discounted
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PKR ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: isOutOfStock ? Colors.grey[500] : AppTheme.primaryMaroon,
                            ),
                          ),
                          // Show original price if there's a standard discount
                          if (_hasStandardDiscount(product) && !isOutOfStock)
                            Text(
                              'PKR ${_getOriginalPrice(product).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: context.captionFontSize,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Action Buttons Row
                      if (!isOutOfStock)
                        Row(
                          children: [
                            // Quick Add Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _quickAddToCart(context, product, provider),
                                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.smallPadding / 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                      border: Border.all(
                                        color: AppTheme.primaryMaroon.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_shopping_cart_rounded,
                                          size: context.iconSize('small'),
                                          color: AppTheme.primaryMaroon,
                                        ),
                                        SizedBox(width: context.smallPadding / 3),
                                        Text(
                                          'Add',
                                          style: GoogleFonts.inter(
                                            fontSize: context.captionFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryMaroon,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: context.smallPadding / 2),

                            // Options Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showProductOptionsMenu(context, product, provider),
                                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                child: Container(
                                  padding: EdgeInsets.all(context.smallPadding / 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                  ),
                                  child: Icon(
                                    Icons.more_horiz_rounded,
                                    size: context.iconSize('small'),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Low Stock Warning
                      if (isLowStock)
                        Container(
                          margin: EdgeInsets.only(top: context.smallPadding / 2),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.smallPadding / 2,
                            vertical: context.smallPadding / 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(context.borderRadius('small')),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: context.iconSize('small') * 0.8,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: context.smallPadding / 3),
                              Text(
                                'Low Stock',
                                style: GoogleFonts.inter(
                                  fontSize: context.captionFontSize * 0.8,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingOrderIndicator(BuildContext context, Product product, SalesProvider provider) {
    // Check if this product is in any existing orders
    final hasExistingOrders = _hasExistingOrders(product, provider);

    if (!hasExistingOrders) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showExistingOrdersDialog(context, product, provider),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.smallPadding / 2,
            vertical: context.smallPadding / 4,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_rounded,
                color: AppTheme.pureWhite,
                size: context.iconSize('small') * 0.8,
              ),
              SizedBox(width: 2),
              Text(
                _getExistingOrderCount(product, provider).toString(),
                style: GoogleFonts.inter(
                  fontSize: context.captionFontSize * 0.7,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 8.w,
              small: 8.w,
              medium: 6.w,
              large: 5.w,
              ultrawide: 4.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 8.w,
              small: 8.w,
              medium: 6.w,
              large: 5.w,
              ultrawide: 4.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: context.iconSize('xl'),
              color: Colors.grey[400],
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            searchQuery.isNotEmpty || selectedCategory != 'All'
                ? 'No Products Found'
                : 'No Products Available',
            style: GoogleFonts.playfairDisplay(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80.w,
                small: 70.w,
                medium: 60.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
            ),
            child: Text(
              searchQuery.isNotEmpty || selectedCategory != 'All'
                  ? 'Try adjusting your search or filter criteria'
                  : 'Add products to your inventory to start selling',
              style: GoogleFonts.inter(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (searchQuery.isNotEmpty || selectedCategory != 'All') ...[
            SizedBox(height: context.mainPadding),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // This would clear filters - handled by parent
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.cardPadding,
                    vertical: context.cardPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryMaroon,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear_all_rounded,
                        color: AppTheme.primaryMaroon,
                        size: context.iconSize('medium'),
                      ),
                      SizedBox(width: context.smallPadding),
                      Text(
                        'Clear Filters',
                        style: GoogleFonts.inter(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper Methods
  IconData _getCategoryIcon(String fabric) {
    switch (fabric.toLowerCase()) {
      case 'silk':
        return Icons.auto_awesome_rounded;
      case 'cotton':
        return Icons.eco_rounded;
      case 'chiffon':
        return Icons.air_rounded;
      case 'georgette':
        return Icons.waves_rounded;
      case 'velvet':
        return Icons.grade_rounded;
      case 'net':
        return Icons.blur_on_rounded;
      case 'lawn':
        return Icons.local_florist_rounded;
      default:
        return Icons.checkroom_outlined;
    }
  }

  Color _getCategoryColor(String fabric) {
    switch (fabric.toLowerCase()) {
      case 'silk':
        return Colors.purple;
      case 'cotton':
        return Colors.green;
      case 'chiffon':
        return Colors.blue;
      case 'georgette':
        return Colors.teal;
      case 'velvet':
        return Colors.indigo;
      case 'net':
        return Colors.cyan;
      case 'lawn':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryAbbreviation(String fabric) {
    switch (fabric.toLowerCase()) {
      case 'silk':
        return 'SLK';
      case 'cotton':
        return 'CTN';
      case 'chiffon':
        return 'CHF';
      case 'georgette':
        return 'GEO';
      case 'velvet':
        return 'VLV';
      case 'net':
        return 'NET';
      case 'lawn':
        return 'LWN';
      default:
        return 'OTH';
    }
  }

  bool _isCustomizable(Product product) {
    // Bridal and formal wear are typically customizable
    return product.name.toLowerCase().contains('bridal') ||
        product.name.toLowerCase().contains('wedding') ||
        product.name.toLowerCase().contains('formal') ||
        product.price > 50000; // High-value items are usually customizable
  }

  bool _hasStandardDiscount(Product product) {
    // This would typically check if there's a current promotion
    return false; // Placeholder
  }

  double _getOriginalPrice(Product product) {
    // This would calculate the original price before discount
    return product.price * 1.1; // Placeholder
  }

  bool _hasExistingOrders(Product product, SalesProvider provider) {
    // Check if this product appears in any existing orders
    return _getExistingOrderCount(product, provider) > 0;
  }

  int _getExistingOrderCount(Product product, SalesProvider provider) {
    // This would check against actual orders from OrderProvider
    // For now, we'll simulate some existing orders
    if (product.name.toLowerCase().contains('bridal')) return 2;
    if (product.name.toLowerCase().contains('wedding')) return 1;
    return 0;
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'navy':
        return Colors.indigo;
      case 'maroon':
        return Colors.red[900]!;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey[400]!;
      case 'beige':
        return Colors.brown[200]!;
      default:
        return Colors.grey;
    }
  }

  // Action Methods
  void _quickAddToCart(BuildContext context, Product product, SalesProvider provider) {
    provider.addToCart(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                '${product.name} added to cart',
                style: GoogleFonts.inter(color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _showEnhancedAddToCartDialog(BuildContext context, Product product, SalesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => EnhancedAddToCartDialog(product: product),
    );
  }

  void _showDiscountDialog(BuildContext context, Product product, SalesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(product: product),
    );
  }

  void _showExistingOrdersDialog(BuildContext context, Product product, SalesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ExistingOrdersDialog(product: product),
    );
  }

  void _showProductOptionsMenu(BuildContext context, Product product, SalesProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductOptionsMenu(
        product: product,
        onCustomizeAndAdd: () => _showCustomizeAndAddDialog(context, product),
        onCreateCustomOrder: () => _showCreateCustomOrderDialog(context, product),
        onApplyDiscount: () => _showDiscountDialog(context, product, provider),
      ),
    );
  }

  void _showCustomizeAndAddDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => CustomizeAndAddDialog(product: product),
    );
  }

  void _showCreateCustomOrderDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => CreateCustomOrderDialog(product: product),
    );
  }
}

// Discount Dialog (updated to work with new structure)
class DiscountDialog extends StatefulWidget {
  final Product product;

  const DiscountDialog({super.key, required this.product});

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _percentageController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isPercentage = true;
  double _calculatedDiscount = 0.0;

  @override
  void dispose() {
    _percentageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    setState(() {
      if (_isPercentage) {
        final percentage = double.tryParse(_percentageController.text) ?? 0.0;
        _calculatedDiscount = (widget.product.price * percentage) / 100;
        _amountController.text = _calculatedDiscount.toStringAsFixed(0);
      } else {
        _calculatedDiscount = double.tryParse(_amountController.text) ?? 0.0;
        final percentage = (_calculatedDiscount / widget.product.price) * 100;
        _percentageController.text = percentage.toStringAsFixed(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = widget.product.price - _calculatedDiscount;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: 85.w,
            small: 75.w,
            medium: 65.w,
            large: 55.w,
            ultrawide: 45.w,
          ),
        ),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: context.shadowBlur('heavy'),
              offset: Offset(0, context.cardPadding),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadius('large')),
                  topRight: Radius.circular(context.borderRadius('large')),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: AppTheme.pureWhite,
                      size: context.iconSize('large'),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Discount',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: context.headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                        Text(
                          widget.product.name,
                          style: GoogleFonts.inter(
                            fontSize: context.subtitleFontSize,
                            color: AppTheme.pureWhite.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      child: Container(
                        padding: EdgeInsets.all(context.smallPadding),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppTheme.pureWhite,
                          size: context.iconSize('medium'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Discount Buttons
                  Text(
                    'Quick Discounts',
                    style: GoogleFonts.inter(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  SizedBox(height: context.smallPadding),
                  Row(
                    children: [5, 10, 15, 20, 25].map((discount) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: discount != 25 ? context.smallPadding / 2 : 0,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isPercentage = true;
                                  _percentageController.text = discount.toString();
                                });
                                _calculateDiscount();
                              },
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: context.smallPadding,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(context.borderRadius()),
                                ),
                                child: Text(
                                  '$discount%',
                                  style: GoogleFonts.inter(
                                    fontSize: context.captionFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: context.cardPadding),

                  // Price Summary
                  Container(
                    padding: EdgeInsets.all(context.cardPadding),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Original Price:',
                              style: GoogleFonts.inter(
                                fontSize: context.subtitleFontSize,
                                color: AppTheme.charcoalGray,
                              ),
                            ),
                            Text(
                              'PKR ${widget.product.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: context.subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                decoration: _calculatedDiscount > 0 ? TextDecoration.lineThrough : null,
                                color: AppTheme.charcoalGray,
                              ),
                            ),
                          ],
                        ),
                        if (_calculatedDiscount > 0) ...[
                          SizedBox(height: context.smallPadding / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount:',
                                style: GoogleFonts.inter(
                                  fontSize: context.subtitleFontSize,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Text(
                                '- PKR ${_calculatedDiscount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: context.subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.smallPadding / 2),
                          Divider(),
                          SizedBox(height: context.smallPadding / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Price:',
                                style: GoogleFonts.inter(
                                  fontSize: context.bodyFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoalGray,
                                ),
                              ),
                              Text(
                                'PKR ${discountedPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: context.bodyFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: context.cardPadding),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(context.borderRadius()),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: context.cardPadding / 1.5,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: context.bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.cardPadding),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(context.borderRadius()),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _calculatedDiscount > 0 ? () {
                                // Apply discount and add to cart
                                Provider.of<SalesProvider>(context, listen: false)
                                    .addToCartWithDiscount(
                                  widget.product,
                                  1,
                                  _calculatedDiscount,
                                );
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${widget.product.name} with ${_isPercentage ? _percentageController.text + "%" : "PKR " + _calculatedDiscount.toStringAsFixed(0)} discount',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } : null,
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: context.cardPadding / 1.5,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: AppTheme.pureWhite,
                                      size: context.iconSize('medium'),
                                    ),
                                    SizedBox(width: context.smallPadding),
                                    Text(
                                      'Add with Discount',
                                      style: GoogleFonts.inter(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}