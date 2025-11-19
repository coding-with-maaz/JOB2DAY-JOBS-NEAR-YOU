import 'package:flutter/material.dart';
import '../models/country.dart';
import '../services/country_service.dart';
import '../widgets/hero_section.dart';
import '../utils/logger.dart';
import 'country_jobs_page.dart';
import '../widgets/network_aware_widget.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
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

class CountriesPage extends StatefulWidget {
  const CountriesPage({super.key});

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final _searchController = TextEditingController();
  final _countryService = CountryService();
  final ScrollController _scrollController = ScrollController();
  bool _isHeroVisible = true;
  static const double _heroSectionHeight = 220.0; // Adjust if your HeroSection is taller/shorter
  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCountries();
    
  }

  void _handleScroll() {
    final isNowHeroVisible = _scrollController.offset < _heroSectionHeight;
    if (isNowHeroVisible != _isHeroVisible) {
      _isHeroVisible = isNowHeroVisible;
    }
  }

  Future<void> _loadCountries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      Logger.info('Loading countries...');
      final countries = await _countryService.getCountries();
      Logger.info('Loaded ${countries.length} countries');

      setState(() {
        _countries = countries;
        _filteredCountries = countries;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('Error loading countries: $e');
      Logger.error('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load countries: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()) ||
                (country.code?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  Widget _buildCountryCard(Country country) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Track visit and show ad if conditions are met (after 3 visits)
            await NavigationVisitService().trackVisitAndShowAd('Countries');
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CountryJobsPage(country: country),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFCEEEE),
                            Color(0xFFE8D5D5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                      child: const Icon(
                        Icons.public,
                        color: Color(0xFF1A1A1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            country.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (country.code != null)
                            Text(
                              country.code!,
                              style: const TextStyle(
                                color: Color(0xFF3C3C43),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEEEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFCEEEE).withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${country.jobCount} Jobs',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            onRefresh: _loadCountries,
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
                        title: 'Find Your Dream Job',
                        subtitle: 'Search through thousands of job listings',
                        searchController: _searchController,
                        onSearchChanged: (value) {},
                        onSearchSubmitted: () {
                          if (_searchController.text.isNotEmpty) {
                            _onSearchChanged(_searchController.text);
                          }
                        },
                        onFilterTap: null,
                        searchHint: 'Search countries...',
                      ),
                    ],
                  ),
                ),
                // Native Ad below Hero Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: NativeAdWidget(),
                  ),
                ),
                // Loading and Error States
                if (_isLoading)
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
                            'Loading countries...',
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
                else if (_errorMessage != null)
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
                            'Could not load countries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? 'Unknown error',
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
                              onPressed: _loadCountries,
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
                else if (_filteredCountries.isEmpty)
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
                            'No countries found matching "${_searchController.text}"',
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
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildCountryCard(_filteredCountries[index]);
                        },
                        childCount: _filteredCountries.length,
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