import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/advance_payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class DeleteAdvancePaymentDialog extends StatefulWidget {
  final AdvancePayment payment;

  const DeleteAdvancePaymentDialog({
    super.key,
    required this.payment,
  });

  @override
  State<DeleteAdvancePaymentDialog> createState() => _DeleteAdvancePaymentDialogState();
}

class _DeleteAdvancePaymentDialogState extends State<DeleteAdvancePaymentDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final provider = Provider.of<AdvancePaymentProvider>(context, listen: false);

    await provider.deleteAdvancePayment(widget.payment.id);

    if (mounted) {
      _showSuccessSnackbar();
      Navigator.of(context).pop();
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
              'Advance payment deleted successfully!',
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(_shakeAnimation.value * 2 * (1 - _scaleAnimation.value), 0),
                child: Container(
                  width: context.dialogWidth,
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 85.w,
                      small: 75.w,
                      medium: 65.w,
                      large: 55.w,
                      ultrawide: 45.w,
                    ),
                    maxHeight: 85.h,
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
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildContent(isCompact: true),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildContent(isCompact: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildContent(isCompact: false),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
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
              Icons.warning_rounded,
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
                  context.shouldShowCompactLayout ? 'Delete Payment' : 'Delete Advance Payment',
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
                    'This action cannot be undone',
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

  Widget _buildContent({required bool isCompact}) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: ResponsiveBreakpoints.responsive(
                context,
                tablet: 5.w,
                small: 5.w,
                medium: 5.w,
                large: 5.w,
                ultrawide: 5.w,
              ),
              height: ResponsiveBreakpoints.responsive(
                context,
                tablet: 5.w,
                small: 5.w,
                medium: 5.w,
                large: 5.w,
                ultrawide: 5.w,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                size: context.iconSize('xl'),
                color: Colors.red,
              ),
            ),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            isCompact
                ? 'Are you sure you want to delete this payment?'
                : 'Are you absolutely sure you want to delete this advance payment record?',
            style: GoogleFonts.inter(
              fontSize: context.bodyFontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding,
                        vertical: context.smallPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        widget.payment.id,
                        style: GoogleFonts.inter(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        widget.payment.laborName,
                        style: GoogleFonts.inter(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount:',
                            style: GoogleFonts.inter(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'PKR ${widget.payment.amount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date:',
                            style: GoogleFonts.inter(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${widget.payment.date.day}/${widget.payment.date.month}/${widget.payment.date.year}',
                            style: GoogleFonts.inter(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description:',
                        style: GoogleFonts.inter(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.payment.description,
                        style: GoogleFonts.inter(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.cardPadding),
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: context.iconSize('small'),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    isCompact
                        ? 'This will permanently delete the payment record.'
                        : 'This will permanently delete the advance payment record and all associated data. This action cannot be undone.',
                    style: GoogleFonts.inter(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
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
    );
  }

  Widget _buildCompactButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: 'Cancel',
          onPressed: _handleCancel,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: AppTheme.pureWhite,
        ),
        SizedBox(height: context.cardPadding),
        Consumer<AdvancePaymentProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: 'Delete Payment',
              onPressed: provider.isLoading ? null : _handleDelete,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.delete_forever_rounded,
              backgroundColor: Colors.red,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: 'Cancel',
            onPressed: _handleCancel,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: AppTheme.pureWhite,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 1,
          child: Consumer<AdvancePaymentProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Delete',
                onPressed: provider.isLoading ? null : _handleDelete,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.delete_forever_rounded,
                backgroundColor: Colors.red,
              );
            },
          ),
        ),
      ],
    );
  }
}