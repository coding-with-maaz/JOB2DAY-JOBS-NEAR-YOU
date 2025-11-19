import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AnimatedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Increased height to accommodate content
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.bottomNavBorder,
            width: 1,
          ),
        ),
        boxShadow: AppColors.bottomNavShadowList,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildNavItem(context, 0, Icons.home_rounded, 'Home')),
            Expanded(child: _buildNavItem(context, 1, Icons.work_rounded, 'Jobs')),
            Expanded(child: _buildNavItem(context, 2, Icons.category_rounded, 'Categories')),
            Expanded(child: _buildNavItem(context, 3, Icons.public_rounded, 'Countries')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
          duration: AppColors.animationDuration,
        curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Reduced vertical padding
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.activeTabBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
          boxShadow: isSelected ? AppColors.activeTabShadowList : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with splash effect
            Container(
              width: isSelected ? 48 : 40, // Reduced container sizes
              height: isSelected ? 48 : 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.splashColor.withOpacity(AppColors.opacity18)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
              icon,
                color: isSelected 
                    ? AppColors.activeIcon
                    : AppColors.inactiveIcon,
                size: isSelected ? 30 : 24, // Reduced icon sizes
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            // Label
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected 
                      ? AppColors.activeText
                      : AppColors.inactiveText,
                  fontSize: 9, // Reduced font size
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1), // Reduced spacing
            // Active indicator
            AnimatedContainer(
              duration: AppColors.animationDuration,
              height: 2, // Reduced height
              width: isSelected ? 12 : 0, // Reduced width
              decoration: BoxDecoration(
                color: AppColors.activeText,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 