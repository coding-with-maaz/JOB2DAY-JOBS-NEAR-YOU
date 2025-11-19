import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onFilterTap;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final bool showFilterButton;
  final bool showSearchBar;
  final String searchHint;

  const HeroSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onFilterTap,
    required this.searchController,
    required this.onSearchChanged,
    this.onSearchSubmitted,
    this.showFilterButton = true,
    this.showSearchBar = true,
    this.searchHint = 'Search jobs...',
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const primaryColor = Colors.deepPurple;
    
    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16, // Keep content below status bar
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (showSearchBar) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      onSubmitted: (_) {
                        print('TextField onSubmitted called');
                        print('onSearchSubmitted is null: ${onSearchSubmitted == null}');
                        onSearchSubmitted?.call();
                      },
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.search,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showFilterButton)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Button
                          Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  print('Search button tapped in HeroSection');
                                  print('onSearchSubmitted is null: ${onSearchSubmitted == null}');
                                  if (onSearchSubmitted != null) {
                                    onSearchSubmitted!();
                                  } else {
                                    print('onSearchSubmitted callback is null!');
                                  }
                                },
                      child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.search,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Filter Button - Commented out
                          /*
                          Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  print('Filter button tapped in HeroSection');
                                  print('onFilterTap is null: ${onFilterTap == null}');
                                  if (onFilterTap != null) {
                                    onFilterTap!();
                                  } else {
                                    print('onFilterTap callback is null!');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                            Icons.filter_list,
                            color: primaryColor,
                            size: 22,
                      ),
                                ),
                              ),
                          ),
                        ),
                          */
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 