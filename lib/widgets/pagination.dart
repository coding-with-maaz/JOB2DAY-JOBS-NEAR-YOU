import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Page Button
            if (currentPage > 1)
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: () => onPageChanged(currentPage - 1),
                isActive: false,
              ),
            
            // First Page
            if (currentPage > 2) ...[
              _buildPageButton(
                number: 1,
                onPressed: () => onPageChanged(1),
                isActive: false,
              ),
              if (currentPage > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],

            // Current Page and Adjacent Pages
            for (int i = _getStartPage(); i <= _getEndPage(); i++)
              _buildPageButton(
                number: i,
                onPressed: () => onPageChanged(i),
                isActive: i == currentPage,
              ),

            // Last Page
            if (currentPage < totalPages - 1) ...[
              if (currentPage < totalPages - 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              _buildPageButton(
                number: totalPages,
                onPressed: () => onPageChanged(totalPages),
                isActive: false,
              ),
            ],

            // Next Page Button
            if (currentPage < totalPages)
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: () => onPageChanged(currentPage + 1),
                isActive: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton({
    int? number,
    IconData? icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    final isIconButton = icon != null;
    const primaryColor = Color(0xFF1976D2);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: isActive 
            ? primaryColor 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isActive ? 4 : 1,
        shadowColor: primaryColor.withOpacity(0.3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: isIconButton ? 36 : 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? primaryColor : Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isIconButton
                  ? Icon(
                      icon,
                      size: 20,
                      color: isActive ? Colors.white : primaryColor,
                    )
                  : Text(
                      number.toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : primaryColor,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  int _getStartPage() {
    if (totalPages <= 5) return 1;
    if (currentPage <= 3) return 1;
    if (currentPage >= totalPages - 2) return totalPages - 4;
    return currentPage - 1;
  }

  int _getEndPage() {
    if (totalPages <= 5) return totalPages;
    if (currentPage <= 3) return 5;
    if (currentPage >= totalPages - 2) return totalPages;
    return currentPage + 1;
  }
} 