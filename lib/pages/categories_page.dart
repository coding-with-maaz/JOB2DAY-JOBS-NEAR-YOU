import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'category_jobs_page.dart';
import '../widgets/category_card.dart';
import '../widgets/base_page.dart';
import '../widgets/hero_section.dart';
import '../widgets/network_aware_widget.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../services/navigation_visit_service.dart';

// New color scheme constants
const primaryColor = Colors.deepPurple;
const backgroundColor = Color(0xFFFFF7F4);
const textPrimaryColor = Color(0xFF1A1A1A);
const textSecondaryColor = Color(0xFF3C3C43);
const activeTabColor = Color(0xFFFCEEEE);
const inactiveTabColor = Color(0xFFB0B0B0);

final ButtonStyle unifiedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  elevation: 2,
);

final TextStyle unifiedHeaderStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
  fontSize: 24,
  letterSpacing: 0.5,
  fontFamily: 'Poppins',
);

final ButtonStyle unifiedOutlinedButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: primaryColor,
  side: BorderSide(color: primaryColor, width: 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
);

final ButtonStyle unifiedTextButtonStyle = TextButton.styleFrom(
  foregroundColor: primaryColor,
  textStyle: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);

final TextStyle unifiedChipTextStyle = TextStyle(
  color: primaryColor,
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  bool _isHeroVisible = true;
  static const double _heroSectionHeight = 220.0; // Adjust if your HeroSection is taller/shorter
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  String? _error;
  int _totalCategories = 0;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMore = true;
  static bool _hasShownInterstitialThisSession = false;

  @override
  void initState() {
    super.initState();
    _logger.i('CategoriesPage initialized');
    _loadCategories();
    
    _scrollController.addListener(_handleScroll);
    _showInterstitialAdOnce();
  }

  void _handleScroll() {
    final isNowHeroVisible = _scrollController.offset < _heroSectionHeight;
    if (isNowHeroVisible != _isHeroVisible) {
      _isHeroVisible = isNowHeroVisible;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _logger.i('Loading categories...');
      final response = await _categoryService.getCategories(
        page: _currentPage,
        limit: _itemsPerPage,
      );
      
      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _categories = response['categories'] as List<Category>;
          _totalCategories = response['total'] as int;
        } else {
          _categories.addAll(response['categories'] as List<Category>);
        }
        _filteredCategories = _categories;
        _hasMore = _categories.length < _totalCategories;
        _isLoading = false;
      });

      _logger.i('Categories loaded: ${_categories.length}');
      for (var category in _categories) {
        _logger.d('Category: ${category.name}, Jobs: ${category.jobCount}, Slug: ${category.slug}');
      }
    } catch (e) {
      _logger.e('Error loading categories: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadCategories,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _filterCategories(String query) {
    _logger.i('Filtering categories with query: $query');
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          final nameMatch = category.name.toLowerCase().contains(query.toLowerCase());
          final descMatch = category.description.toLowerCase().contains(query.toLowerCase());
          return nameMatch || descMatch;
        }).toList();
      }
    });
    _logger.i('Filtered categories count: ${_filteredCategories.length}');
  }

  List<Category> get _trendingCategories {
    return [..._categories]
      ..sort((a, b) => b.jobCount.compareTo(a.jobCount))
      ..take(4)
      .toList();
  }

  Future<void> _loadMoreCategories() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadCategories();
  }

  Future<void> _showInterstitialAdOnce() async {
    if (!_hasShownInterstitialThisSession) {
      _hasShownInterstitialThisSession = true;
      await Future.delayed(const Duration(milliseconds: 500)); // Optional: let UI settle
      await InterstitialAdManager.showAdOnPage('CategoriesView');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkAwareWidget(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: true,
          body: RefreshIndicator(
            onRefresh: _loadCategories,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero Section with status bar extension
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Background gradient that extends behind status bar
                      Positioned(
                        top: -MediaQuery.of(context).padding.top,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurple,
                                Color(0xFF9C27B0),
                                Color(0xFFBA68C8),
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),
                      // Hero Section content
                      HeroSection(
                        title: 'All Categories',
                        subtitle: 'Search through thousands of job listings',
                        searchController: _searchController,
                        onSearchChanged: (value) {},
                        onSearchSubmitted: () {
                          if (_searchController.text.isNotEmpty) {
                            _filterCategories(_searchController.text);
                          }
                        },
                        onFilterTap: null,
                        searchHint: 'Search categories...',
                      ),
                    ],
                  ),
                ),
                // Trending Categories
                if (_searchController.text.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB0B0B0).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEEEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.trending_up, color: textPrimaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Trending Categories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                  fontSize: 20,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _trendingCategories.length,
                              itemBuilder: (context, index) {
                                final category = _trendingCategories[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: CategoryCard(
                                    category: category,
                                    onTap: () async {
                                      // Track visit and show ad if conditions are met (after 3 visits)
                                      await NavigationVisitService().trackVisitAndShowAd('Categories');
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryJobsPage(
                                            category: category,
                                          ),
                                        ),
                                      );
                                    },
                                    style: CategoryCardStyle(
                                      backgroundColor: index % 2 == 0 
                                          ? const Color(0xFFFCEEEE)
                                          : Colors.white,
                                      textColor: textPrimaryColor,
                                      iconColor: textPrimaryColor,
                                      borderColor: index % 2 == 0 
                                          ? const Color(0xFFFCEEEE)
                                          : const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Native Ad below Trending Categories
                if (_searchController.text.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: NativeAdWidget(),
                    ),
                  ),
                // All Categories
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB0B0B0).withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _searchController.text.isEmpty ? 'All Categories' : 'Search Results',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          Text(
                            ' (${_filteredCategories.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                              fontSize: 20,
                              fontFamily: 'Poppins',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Categories Grid
                if (_isLoading && _categories.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB0B0B0).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading categories...',
                            style: TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_error != null && _categories.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB0B0B0).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFF1A1A1A),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Could not load categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error ?? 'Unknown error',
                            style: const TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEEEE),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFCEEEE).withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _loadCategories,
                              icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
                              label: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredCategories.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB0B0B0).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Color(0xFF3C3C43),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No categories found matching "${_searchController.text}"',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _filteredCategories.length && _hasMore) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB0B0B0).withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEEEE),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFCEEEE).withOpacity(0.4),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loadMoreCategories,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: textPrimaryColor,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Load More',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          final category = _filteredCategories[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB0B0B0).withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CategoryCard(
                              category: category,
                              onTap: () async {
                                // Track visit and show ad if conditions are met (after 3 visits)
                                await NavigationVisitService().trackVisitAndShowAd('Categories');
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryJobsPage(category: category),
                                  ),
                                );
                              },
                              style: CategoryCardStyle(
                                backgroundColor: index % 2 == 0 
                                    ? const Color(0xFFFCEEEE)
                                    : Colors.white,
                                textColor: textPrimaryColor,
                                iconColor: textPrimaryColor,
                                borderColor: index % 2 == 0 
                                    ? const Color(0xFFFCEEEE)
                                    : const Color(0xFFE5E5E5),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredCategories.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BannerAdWidget(
                collapsible: true,
                collapsiblePlacement: 'bottom',
              ),
            ],
          ),
        ),
      ),
    );
  }
}