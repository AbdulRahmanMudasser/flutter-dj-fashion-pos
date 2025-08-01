import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedColor;
  String? _selectedFabric;
  List<String> _selectedPieces = [];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _detailController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedColor == null) {
        _showErrorSnackbar('Please select a color');
        return;
      }
      if (_selectedFabric == null) {
        _showErrorSnackbar('Please select a fabric');
        return;
      }
      if (_selectedPieces.isEmpty) {
        _showErrorSnackbar('Please select at least one piece');
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      await productProvider.addProduct(
        name: _nameController.text.trim(),
        detail: _detailController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        color: _selectedColor!,
        fabric: _selectedFabric!,
        pieces: _selectedPieces,
        quantity: int.parse(_quantityController.text.trim()),
      );

      if (mounted) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              'Product added successfully!',
              style: GoogleFonts.inter(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 90.w,
                    small: 85.w,
                    medium: 75.w,
                    large: 65.w,
                    ultrawide: 55.w,
                  ),
                  maxHeight: 90.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
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
                child: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildTabletLayout(),
                  small: _buildMobileLayout(),
                  medium: _buildDesktopLayout(),
                  large: _buildDesktopLayout(),
                  ultrawide: _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildFormContent(isCompact: true),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildFormContent(isCompact: true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildFormContent(isCompact: false),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
              Icons.inventory_rounded,
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
                  context.shouldShowCompactLayout ? 'Add Product' : 'Add New Product',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    'Create a new product entry',
                    style: GoogleFonts.inter(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
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
    );
  }

  Widget _buildFormContent({required bool isCompact}) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: 'Product Name',
              hint: isCompact ? 'Enter name' : 'Enter product name',
              controller: _nameController,
              prefixIcon: Icons.label_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a product name';
                }
                if (value!.length < 2) {
                  return 'Product name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: 'Product Detail',
              hint: isCompact ? 'Enter details' : 'Enter product description/details',
              controller: _detailController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter product details';
                }
                if (value!.length < 5) {
                  return 'Product detail must be at least 5 characters';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: 'Price',
                    hint: isCompact ? 'Enter price' : 'Enter price (PKR)',
                    controller: _priceController,
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter price';
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: 'Quantity',
                    hint: isCompact ? 'Enter qty' : 'Enter quantity',
                    controller: _quantityController,
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter quantity';
                      }
                      final quantity = int.tryParse(value!);
                      if (quantity == null || quantity < 0) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Color Selection
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: InputDecoration(
                    labelText: 'Color',
                    prefixIcon: Icon(Icons.color_lens_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                  ),
                  items: provider.availableColors
                      .map((color) => DropdownMenuItem<String>(
                    value: color,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColorFromName(color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        SizedBox(width: context.smallPadding),
                        Text(color),
                      ],
                    ),
                  ))
                      .toList(),
                  onChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a color';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            // Fabric Selection
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedFabric,
                  decoration: InputDecoration(
                    labelText: 'Fabric',
                    prefixIcon: Icon(Icons.texture_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                  ),
                  items: provider.availableFabrics
                      .map((fabric) => DropdownMenuItem<String>(
                    value: fabric,
                    child: Text(fabric),
                  ))
                      .toList(),
                  onChanged: (fabric) {
                    setState(() {
                      _selectedFabric = fabric;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a fabric';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            // Pieces Selection
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pieces',
                      style: GoogleFonts.inter(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    SizedBox(height: context.smallPadding),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                      ),
                      child: Wrap(
                        spacing: context.smallPadding,
                        runSpacing: context.smallPadding,
                        children: provider.availablePieces.map((piece) {
                          final isSelected = _selectedPieces.contains(piece);
                          return FilterChip(
                            label: Text(
                              piece,
                              style: GoogleFonts.inter(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? AppTheme.pureWhite : AppTheme.charcoalGray,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPieces.add(piece);
                                } else {
                                  _selectedPieces.remove(piece);
                                }
                              });
                            },
                            selectedColor: AppTheme.primaryMaroon,
                            checkmarkColor: AppTheme.pureWhite,
                            backgroundColor: AppTheme.lightGray,
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedPieces.isEmpty) ...[
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        'Please select at least one piece',
                        style: GoogleFonts.inter(
                          fontSize: context.captionFontSize,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            SizedBox(height: context.mainPadding),

            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactButtons(),
              small: _buildCompactButtons(),
              medium: _buildDesktopButtons(),
              large: _buildDesktopButtons(),
              ultrawide: _buildDesktopButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: 'Add Product',
              onPressed: provider.isLoading ? null : _handleSubmit,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.add_rounded,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: 'Cancel',
          onPressed: _handleCancel,
          isOutlined: true,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: 'Cancel',
            onPressed: _handleCancel,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Add Product',
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.add_rounded,
              );
            },
          ),
        ),
      ],
    );
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
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'gray':
        return Colors.grey;
      case 'navy':
        return Colors.indigo;
      case 'maroon':
        return const Color(0xFF800000);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return Colors.grey[400]!;
      case 'beige':
        return const Color(0xFFF5F5DC);
      default:
        return Colors.grey;
    }
  }
}