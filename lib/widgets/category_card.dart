import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryCardStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;

  const CategoryCardStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
  });
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final CategoryCardStyle? style;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepPurple;
    
    final defaultStyle = CategoryCardStyle(
      backgroundColor: Colors.white,
      textColor: primaryColor,
      iconColor: primaryColor,
      borderColor: Colors.grey[300]!,
    );

    final effectiveStyle = style ?? defaultStyle;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: effectiveStyle.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: effectiveStyle.borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: effectiveStyle.backgroundColor == Colors.white
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.8),
                    ],
                  ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveStyle.backgroundColor == Colors.white
                      ? primaryColor.withOpacity(0.1)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: effectiveStyle.backgroundColor == Colors.white
                        ? primaryColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveStyle.backgroundColor == Colors.white
                          ? primaryColor.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  color: effectiveStyle.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: effectiveStyle.textColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (category.jobCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: effectiveStyle.backgroundColor == Colors.white
                        ? primaryColor.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: effectiveStyle.backgroundColor == Colors.white
                          ? primaryColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${category.jobCount} jobs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: effectiveStyle.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'design':
        return Icons.palette;
      case 'marketing':
        return Icons.trending_up;
      case 'sales':
        return Icons.point_of_sale;
      case 'finance':
        return Icons.account_balance;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'engineering':
        return Icons.engineering;
      case 'customer service':
        return Icons.support_agent;
      case 'human resources':
        return Icons.people;
      case 'legal':
        return Icons.gavel;
      case 'consulting':
        return Icons.business;
      case 'research':
        return Icons.science;
      case 'writing':
        return Icons.edit;
      case 'translation':
        return Icons.translate;
      case 'data':
        return Icons.analytics;
      case 'product':
        return Icons.inventory;
      case 'operations':
        return Icons.settings;
      case 'quality assurance':
        return Icons.verified;
      default:
        return Icons.work;
    }
  }
} 