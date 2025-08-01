import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class AddLaborDialog extends StatefulWidget {
  const AddLaborDialog({super.key});

  @override
  State<AddLaborDialog> createState() => _AddLaborDialogState();
}

class _AddLaborDialogState extends State<AddLaborDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _casteController = TextEditingController();
  final _designationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _advanceController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime _selectedJoiningDate = DateTime.now();

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
    _cnicController.dispose();
    _phoneController.dispose();
    _casteController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<LaborProvider>(context, listen: false);

      await provider.addLabor(
        name: _nameController.text.trim(),
        cnic: _cnicController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        caste: _casteController.text.trim(),
        designation: _designationController.text.trim(),
        joiningDate: _selectedJoiningDate,
        salary: double.parse(_salaryController.text.trim()),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        gender: _selectedGender,
        age: int.parse(_ageController.text.trim()),
        advancePayment: double.parse(_advanceController.text.trim()),
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
              'Labor added successfully!',
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

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedJoiningDate) {
      setState(() {
        _selectedJoiningDate = picked;
      });
    }
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
                    tablet: 85.w,
                    small: 80.w,
                    medium: 70.w,
                    large: 60.w,
                    ultrawide: 50.w,
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
              Icons.person_add_rounded,
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
                  context.shouldShowCompactLayout ? 'Add Labor' : 'Add New Labor',
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
                    'Register a new worker',
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
              label: 'Name',
              hint: isCompact ? 'Enter name' : 'Enter full name',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a name';
                }
                if (value!.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (value.length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'CNIC',
              hint: isCompact ? 'Enter CNIC' : 'Enter CNIC (e.g., 42101-1234567-1)',
              controller: _cnicController,
              prefixIcon: Icons.credit_card,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a CNIC';
                }
                if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value!)) {
                  return 'Please enter a valid CNIC (XXXXX-XXXXXXX-X)';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Phone Number',
              hint: isCompact ? 'Enter phone' : 'Enter phone number (e.g., +923001234567)',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a phone number';
                }
                if (!RegExp(r'^\+92\d{9}$').hasMatch(value!)) {
                  return 'Please enter a valid phone number (+92XXXXXXXXX)';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Caste',
              hint: isCompact ? 'Enter caste' : 'Enter caste (optional)',
              controller: _casteController,
              prefixIcon: Icons.group_outlined,
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Designation',
              hint: isCompact ? 'Enter designation' : 'Enter designation (e.g., Tailor)',
              controller: _designationController,
              prefixIcon: Icons.work_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a designation';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: PremiumTextField(
                label: 'Joining Date',
                hint: 'Select joining date',
                controller: TextEditingController(
                    text:
                    '${_selectedJoiningDate.day}/${_selectedJoiningDate.month}/${_selectedJoiningDate.year}'),
                prefixIcon: Icons.calendar_today,
                enabled: false,
              ),
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Salary',
              hint: isCompact ? 'Enter salary' : 'Enter monthly salary (PKR)',
              controller: _salaryController,
              prefixIcon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a salary';
                }
                if (double.tryParse(value!) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid salary';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Area',
              hint: isCompact ? 'Enter area' : 'Enter area (e.g., Gulshan)',
              controller: _areaController,
              prefixIcon: Icons.location_on_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an area';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'City',
              hint: isCompact ? 'Enter city' : 'Enter city (e.g., Karachi)',
              controller: _cityController,
              prefixIcon: Icons.location_city_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a city';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_pin_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
              ),
              items: ['Male', 'Female', 'Other']
                  .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Age',
              hint: isCompact ? 'Enter age' : 'Enter age (e.g., 30)',
              controller: _ageController,
              prefixIcon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an age';
                }
                if (int.tryParse(value!) == null || int.parse(value) < 18) {
                  return 'Age must be at least 18';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: 'Advance Payment',
              hint: isCompact ? 'Enter advance' : 'Enter advance payment (PKR, optional)',
              controller: _advanceController,
              prefixIcon: Icons.payment_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return null;
                }
                if (double.tryParse(value!) == null || double.parse(value) < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
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
        Consumer<LaborProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: 'Add Labor',
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
          child: Consumer<LaborProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Add Labor',
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
}