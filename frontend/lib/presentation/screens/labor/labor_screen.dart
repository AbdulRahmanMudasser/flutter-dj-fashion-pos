import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/labor/add_labor_dialog.dart';
import '../../widgets/labor/labor_filter_dialog.dart';
import '../../widgets/labor/labor_table.dart';
import '../../widgets/labor/delete_labor_dialog.dart';
import '../../widgets/labor/edit_labor_dialog.dart';
import '../../widgets/labor/view_labor_dialog.dart';

class LaborPage extends StatefulWidget {
  const LaborPage({super.key});

  @override
  State<LaborPage> createState() => _LaborPageState();
}

class _LaborPageState extends State<LaborPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LaborProvider>();
      provider.refreshLabors();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLaborDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddLaborDialog());
  }

  void _showEditLaborDialog(LaborModel labor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedEditLaborDialog(labor: labor),
    );
  }

  void _showDeleteLaborDialog(LaborModel labor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedDeleteLaborDialog(labor: labor),
    );
  }

  void _showViewLaborDialog(LaborModel labor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewLaborDetailsDialog(labor: labor),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const EnhancedLaborFilterDialog(),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<LaborProvider>();
    await provider.refreshLabors();
    await provider.loadStatistics();

    if (provider.hasError) {
      _showErrorSnackbar(provider.errorMessage ?? 'Failed to refresh labors');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleExport() async {
    try {
      final provider = context.read<LaborProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pureWhite),
                ),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Preparing export...',
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
        ),
      );

      await provider.exportData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                'Labor data export completed successfully',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to export data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<LaborProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryMaroon,
            child: Padding(
              padding: EdgeInsets.all(context.mainPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveBreakpoints.responsive(
                    context,
                    tablet: _buildTabletHeader(),
                    small: _buildMobileHeader(),
                    medium: _buildDesktopHeader(),
                    large: _buildDesktopHeader(),
                    ultrawide: _buildDesktopHeader(),
                  ),
                  SizedBox(height: context.mainPadding),
                  context.statsCardColumns == 2
                      ? _buildMobileStatsGrid(provider)
                      : _buildDesktopStatsRow(provider),
                  SizedBox(height: context.cardPadding * 0.5),
                  _buildSearchSection(provider),
                  SizedBox(height: context.cardPadding * 0.5),
                  _buildActiveFilters(provider),
                  Expanded(
                    child: EnhancedLaborTable(
                      onEdit: _showEditLaborDialog,
                      onDelete: _showDeleteLaborDialog,
                      onView: _showViewLaborDialog,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_outlined, size: 15.w, color: Colors.grey[400]),
              SizedBox(height: 3.h),
              Text(
                'Screen Too Small',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                'This application requires a minimum screen width of 750px for optimal experience. Please use a larger screen or rotate your device.',
                style: GoogleFonts.inter(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Labor Management',
                style: GoogleFonts.playfairDisplay(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                'Organize and manage your labor workforce with comprehensive tools',
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Labor Management',
          style: GoogleFonts.playfairDisplay(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          'Organize and manage labor workforce',
          style: GoogleFonts.inter(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(
          width: double.infinity,
          child: _buildAddButton(),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Labors',
          style: GoogleFonts.playfairDisplay(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          'Manage labor workforce',
          style: GoogleFonts.inter(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(
          width: double.infinity,
          child: _buildAddButton(),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddLaborDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding * 0.5,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? 'Add' : 'Add Labor',
                  style: GoogleFonts.inter(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStatsRow(LaborProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard('Total Labors', '${provider.totalLabors}', Icons.people, Colors.blue),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard('Active', '${provider.totalActiveLabors}', Icons.check_circle_rounded, Colors.green),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard('Inactive', '${provider.totalInactiveLabors}', Icons.cancel, Colors.orange),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            'New This Month',
            '${provider.statistics?.newLaborsThisMonth ?? 0}',
            Icons.fiber_new,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(LaborProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard('Total', '${provider.totalLabors}', Icons.people, Colors.blue),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard('Active', '${provider.totalActiveLabors}', Icons.check_circle_rounded, Colors.green),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard('Inactive', '${provider.totalInactiveLabors}', Icons.cancel, Colors.orange),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                'New',
                '${provider.statistics?.newLaborsThisMonth ?? 0}',
                Icons.fiber_new,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(icon, color: color, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 10.8.sp,
                      small: 11.2.sp,
                      medium: 11.5.sp,
                      large: 11.8.sp,
                      ultrawide: 12.2.sp,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(LaborProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(provider),
        small: _buildMobileSearchLayout(provider),
        medium: _buildDesktopSearchLayout(provider),
        large: _buildDesktopSearchLayout(provider),
        ultrawide: _buildDesktopSearchLayout(provider),
      ),
    );
  }

  Widget _buildDesktopSearchLayout(LaborProvider provider) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar(provider)),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildShowInactiveToggle(provider)),
        SizedBox(width: context.smallPadding),
        Expanded(flex: 1, child: _buildFilterButton(provider)),
        SizedBox(width: context.smallPadding),
        Expanded(flex: 1, child: _buildExportButton()),
      ],
    );
  }

  Widget _buildTabletSearchLayout(LaborProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildShowInactiveToggle(provider)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildFilterButton(provider)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildExportButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout(LaborProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildShowInactiveToggle(provider)),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildFilterButton(provider)),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildExportButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(LaborProvider provider) {
    if (_searchController.text != (provider.searchQuery ?? '')) {
      _searchController.text = provider.searchQuery ?? '';
    }

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.isEmpty) {
            provider.clearSearch();
          } else {
            provider.searchLabors(value);
          }
        },
        style: GoogleFonts.inter(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
        decoration: InputDecoration(
          hintText: context.isTablet
              ? 'Search labors...'
              : 'Search labors by name, CNIC, phone, designation...',
          hintStyle: GoogleFonts.inter(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
          suffixIcon: provider.searchQuery != null && provider.searchQuery!.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              provider.clearSearch();
            },
            icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.cardPadding / 2,
            vertical: context.cardPadding / 2,
          ),
        ),
      ),
    );
  }

  Widget _buildShowInactiveToggle(LaborProvider provider) {
    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: provider.showInactive ? AppTheme.primaryMaroon.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: provider.showInactive ? AppTheme.primaryMaroon.withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => provider.setShowInactive(!provider.showInactive),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.showInactive ? Icons.visibility : Icons.visibility_off,
              color: provider.showInactive ? AppTheme.primaryMaroon : Colors.grey[600],
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                provider.showInactive ? 'Hide Inactive' : 'Show Inactive',
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: provider.showInactive ? AppTheme.primaryMaroon : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(LaborProvider provider) {
    int filterCount = 0;
    if (provider.selectedCity != null) filterCount++;
    if (provider.selectedArea != null) filterCount++;
    if (provider.selectedDesignation != null) filterCount++;
    if (provider.selectedCaste != null) filterCount++;
    if (provider.selectedGender != null) filterCount++;
    if (provider.showInactive) filterCount++;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: filterCount > 0 ? AppTheme.accentGold.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: filterCount > 0 ? AppTheme.accentGold.withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterCount > 0 ? Icons.filter_alt : Icons.filter_list_rounded,
              color: filterCount > 0 ? AppTheme.accentGold : AppTheme.primaryMaroon,
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                filterCount > 0 ? 'Filters ($filterCount)' : 'Filter',
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: filterCount > 0 ? AppTheme.accentGold : AppTheme.primaryMaroon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: _handleExport,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: AppTheme.accentGold, size: context.iconSize('medium')),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                'Export',
                style: GoogleFonts.inter(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(LaborProvider provider) {
    final activeFilters = <String>[];

    if (provider.selectedCity != null) {
      activeFilters.add('City: ${provider.selectedCity}');
    }
    if (provider.selectedArea != null) {
      activeFilters.add('Area: ${provider.selectedArea}');
    }
    if (provider.selectedDesignation != null) {
      activeFilters.add('Designation: ${provider.selectedDesignation}');
    }
    if (provider.selectedCaste != null) {
      activeFilters.add('Caste: ${provider.selectedCaste}');
    }
    if (provider.selectedGender != null) {
      activeFilters.add('Gender: ${provider.selectedGender}');
    }
    if (provider.showInactive) {
      activeFilters.add('Show Inactive');
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding * 0.5),
      child: Wrap(
        spacing: context.smallPadding,
        runSpacing: context.smallPadding / 2,
        children: [
          ...activeFilters.map((filter) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.smallPadding,
              vertical: context.smallPadding / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
                SizedBox(width: context.smallPadding / 2),
                InkWell(
                  onTap: () => _clearSpecificFilter(filter, provider),
                  child: Icon(
                    Icons.close,
                    size: context.iconSize('small'),
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ],
            ),
          )),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.smallPadding,
              vertical: context.smallPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              onTap: provider.clearAllFilters,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSpecificFilter(String filterText, LaborProvider provider) {
    if (filterText.startsWith('City:')) {
      provider.setCityFilter(null);
    } else if (filterText.startsWith('Area:')) {
      provider.setAreaFilter(null);
    } else if (filterText.startsWith('Designation:')) {
      provider.setDesignationFilter(null);
    } else if (filterText.startsWith('Caste:')) {
      provider.setCasteFilter(null);
    } else if (filterText.startsWith('Gender:')) {
      provider.setGenderFilter(null);
    } else if (filterText == 'Show Inactive') {
      provider.setShowInactive(false);
    }
  }
}