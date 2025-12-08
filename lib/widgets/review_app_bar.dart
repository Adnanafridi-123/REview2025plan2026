import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ReviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const ReviewAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textWhite,
                    size: 18,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textWhite,
        ),
      ),
      centerTitle: true,
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: AppTheme.textWhite,
                  size: 20,
                ),
              ),
            ),
          ],
    );
  }
}

// Beautiful gradient background for Review screens - now uses main app gradient
class ReviewGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  
  const ReviewGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? const [
            AppTheme.bgTop,
            AppTheme.bgMiddle,
            AppTheme.bgBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}

// Reusable filter chip row
class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final Color activeColor;
  final Color activeTextColor;
  
  const FilterChipRow({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.activeColor = AppTheme.iconPurple,
    this.activeTextColor = Colors.white,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          
          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? activeColor 
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeTextColor : AppTheme.textWhite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Month filter horizontal list
class MonthFilterRow extends StatelessWidget {
  final int? selectedMonth;
  final Function(int?) onMonthSelected;
  
  const MonthFilterRow({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });
  
  static const List<String> monthNames = [
    'All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 13,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final month = isAll ? null : index;
          final isSelected = selectedMonth == month;
          
          return GestureDetector(
            onTap: () => onMonthSelected(month),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.iconPurple 
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                monthNames[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Empty state widget
class ReviewEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const ReviewEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppTheme.textWhite.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
