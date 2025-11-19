import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/job.dart';
import '../models/category.dart';
import '../models/country.dart';
import '../widgets/job_card.dart';
import '../widgets/category_card.dart';
import '../services/job_service.dart';
import '../services/category_service.dart';
import '../services/country_service.dart';
import '../pages/job_details_page.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../pages/category_jobs_page.dart';
import '../pages/country_jobs_page.dart';
import '../pages/countries_page.dart';
import 'search_results_page.dart';
import '../pages/categories_page.dart';
import '../pages/jobs_page.dart';
import '../widgets/base_page.dart';
import '../widgets/hero_section.dart';
import '../widgets/styled_card.dart';
import '../widgets/network_aware_widget.dart';
import '../widgets/animated_bottom_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/no_internet_widget.dart';
import 'settings_page.dart';
import '../services/simple_notification_service.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'resume_maker_page.dart';
import '../widgets/animated_resume_fab.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final JobService _jobService = JobService();
  final CategoryService _categoryService = CategoryService();
  final CountryService _countryService = CountryService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isHeroVisible = true;
  static const double _heroSectionHeight = 220.0; // Adjust if your HeroSection is taller/shorter
  
  List<Job> _latestJobs = [];
  List<Category> _categories = [];
  List<Country> _countries = [];
  Map<String, dynamic> _activeFilters = {};
  
  bool _isLoading = true;
  String? _error;

  // Filter states
  bool _isLoadingFeatured = false;
  bool _isLoadingRecent = false;
  String? _featuredError;
  String? _recentError;
  List<Job> _featuredJobs = [];
  List<Job> _recentJobs = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _scrollController.addListener(_handleScroll);
    _loadData();
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
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFilterApply(Map<String, dynamic> filters) {
    print('_handleFilterApply called with filters: $filters');
    setState(() {
      _activeFilters = filters;
    });
    print('Active filters updated: $_activeFilters');
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Applying filters...'),
          ],
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
    
    print('Navigating to SearchResultsPage with filters');
    // Navigate to SearchResultsPage with the applied filters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: _searchController.text.isNotEmpty ? _searchController.text : '',
          initialJobType: filters['jobType'] as String?,
          initialLocation: filters['location'] as String?,
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading latest jobs, categories, and countries...');
      final latestJobs = await _jobService.getTodayJobs(
        sort: 'createdAt:desc',
        limit: 3,
      );
      final categoriesResult = await _categoryService.getCategories();
      final countries = await _countryService.getCountries();
      
      if (!mounted) return;
      
      setState(() {
        _latestJobs = latestJobs['jobs'] as List<Job>;
        _latestJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _categories = categoriesResult['categories'] as List<Category>;
        _countries = countries;
        _isLoading = false;
      });
      
      _animationController.forward();
      
      print('Loaded ${_latestJobs.length} latest jobs, ${_categories.length} categories, and ${_countries.length} countries');
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Widget _buildErrorWidget() {
    return Container(
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
          Icon(
            Icons.error_outline,
            color: const Color(0xFF1A1A1A),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
              onPressed: _loadData,
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
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('Loading data...'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onViewAll, String viewAllLabel, {double fontSize = 22, double subtitleFontSize = 14}) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF3C3C43),
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
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
              child: TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF1A1A1A), size: 20),
                label: Text(
                  viewAllLabel.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    print('_showFilterBottomSheet called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterBottomSheet(
        onApply: (jobType, location) {
          print('Filter applied - JobType: $jobType, Location: $location');
          _handleFilterApply({
            'jobType': jobType,
            'location': location,
          });
        },
        selectedJobType: _activeFilters['jobType'] as String?,
        selectedLocation: _activeFilters['location'] as String?,
      ),
    );
  }

  void _navigateToJobDetails(Job job) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsPage(jobSlug: job.slug),
      ),
    );
  }

  void _navigateToCategoryJobs(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: category.name,
          initialLocation: null,
        ),
      ),
    );
  }

  void _navigateToSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: query,
        ),
      ),
    );
  }

  void _navigateToAllJobs() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: '',
        ),
      ),
    );
  }

  Future<void> _loadFeaturedJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFeatured = true;
      _featuredError = null;
    });

    try {
      final jobs = await _jobService.getFeaturedJobs();
      if (!mounted) return;

      setState(() {
        _featuredJobs = jobs;
        _isLoadingFeatured = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFeatured = false;
        _featuredError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading featured jobs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadFeaturedJobs,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadRecentJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRecent = true;
      _recentError = null;
    });

    try {
      final response = await _jobService.getJobs(
        page: 1,
        limit: 10,
        sortBy: 'newest',
      );
      
      if (!mounted) return;

      setState(() {
        _recentJobs = response['jobs'] as List<Job>;
        _isLoadingRecent = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingRecent = false;
        _recentError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recent jobs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadRecentJobs,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search jobs...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                print('[DEBUG] Search submitted in home_page.dart with value: ' + value);
                if (value.isNotEmpty) {
                  _navigateToSearchResults(value);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement advanced search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textSecondaryColor), // Secondary text color
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: unifiedChipTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1), // Light purple background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        skill,
        style: unifiedChipTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildJobCard(Job job) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade200, Colors.grey.shade300], // Subtle grey gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: job.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            job.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business,
                              color: Colors.grey[600], // Softer icon color
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.business,
                          color: Colors.grey[600], // Softer icon color
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.isFeatured)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.companyName,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondaryColor, // Secondary text color
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.location_on, job.location),
                          _buildInfoChip(Icons.work, job.jobType),
                          _buildInfoChip(Icons.attach_money, job.salary),
                          _buildInfoChip(Icons.access_time, 'Posted ${_formatDate(job.createdAt)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textSecondaryColor), // Secondary text color
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.skills.map((skill) => _buildSkillChip(skill)).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${job.views} views',
                  style: TextStyle(color: textSecondaryColor), // Secondary text color
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailsPage(jobSlug: job.slug),
                      ),
                    );
                  },
                  icon: Icon(Icons.arrow_forward, color: primaryColor), // Purple icon
                  label: Text('View Details', style: TextStyle(color: primaryColor)), // Purple text
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent, // Transparent background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: primaryColor), // Purple border
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryCard(Country country, double radius, double chipFontSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB0B0B0).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsPage(
                  initialQuery: '',
                  initialLocation: country.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFCEEEE),
                            Color(0xFFE8D5D5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFCEEEE).withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.public,
                        color: Color(0xFF1A1A1A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            country.name,
                            style: const TextStyle(
                              fontSize: 14,
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEEEE),
                    borderRadius: BorderRadius.circular(6),
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
                      fontSize: 10,
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
  Widget build(BuildContext context) {
    // Responsive helpers
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final textScale = media.textScaleFactor;
    final isTablet = width > 600;
    final isLarge = width > 900;
    final horizontalPadding = width * 0.04; // 4vw
    final cardRadius = isLarge ? 24.0 : isTablet ? 18.0 : 12.0;
    final sectionSpacing = isLarge ? 40.0 : isTablet ? 28.0 : 20.0;
    final headerFontSize = isLarge ? 32.0 : isTablet ? 26.0 : 22.0;
    final subtitleFontSize = isLarge ? 18.0 : isTablet ? 16.0 : 14.0;
    final chipFontSize = isLarge ? 16.0 : isTablet ? 15.0 : 13.0;
    final cardPadding = isLarge ? 28.0 : isTablet ? 20.0 : 14.0;
    final minTouch = 48.0;

    return NetworkAwareWidget(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: true, // Allow content to extend behind status bar
          floatingActionButton: null,
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero, // Remove default padding to allow hero section to extend behind status bar
              children: [
                // Hero Section with status bar extension
                Stack(
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
                    print('Search submitted called');
                    print('Search text: "${_searchController.text}"');
                    print('Search text is empty: ${_searchController.text.isEmpty}');
                    print('Widget mounted: $mounted');
                    print('Context: $context');
                    
                    if (!mounted) {
                      print('Widget not mounted, returning');
                      return;
                    }
                    
                    if (_searchController.text.isNotEmpty) {
                      print('Navigating to search results page');
                      print('Initial query: ${_searchController.text}');
                      print('Initial job type: ${_activeFilters['jobType']}');
                      print('Initial location: ${_activeFilters['location']}');
                      
                      // Show loading feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Searching for "${_searchController.text}"...'),
                            ],
                          ),
                          backgroundColor: primaryColor,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      
                      // Navigate to SearchResultsPage
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              print('Building SearchResultsPage');
                              return SearchResultsPage(
                                initialQuery: _searchController.text,
                                initialJobType: _activeFilters['jobType'] as String?,
                                initialLocation: _activeFilters['location'] as String?,
                              );
                            },
                          ),
                        );
                        print('Navigation call completed');
                      } catch (e) {
                        print('Navigation error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Navigation error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      print('Search text is empty, showing error');
                      // Show error if search is empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a search term'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onFilterTap: _showFilterBottomSheet,
                ),
                  ],
                ),
                // Resume Maker Button below Hero Section, above Top Countries
                const SizedBox(height: 16),
                Center(
                  child: AnimatedResumeFab(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResumeMakerPage(),
                        ),
                      );
                    },
                    showNewBadge: true, // Explicitly show the NEW badge
                  ),
                ),
                const SizedBox(height: 16),
                // Countries Section (Responsive horizontal list)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: StyledCard(
                    margin: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    showBorder: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Top Countries',
                          'Explore jobs by country',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CountriesPage()),
                          ),
                          'View All Countries',
                          fontSize: headerFontSize,
                          subtitleFontSize: subtitleFontSize,
                        ),
                        SizedBox(height: 8),
                        if (_countries.isEmpty)
                          Container(
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
                                Icon(
                                  Icons.public_off,
                                  size: 48,
                                  color: Color(0xFF3C3C43),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No countries available',
                                  style: TextStyle(
                                    color: Color(0xFF3C3C43),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: isLarge ? 140 : isTablet ? 120 : 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _countries.length > (isLarge ? 8 : isTablet ? 6 : 4) ? (isLarge ? 8 : isTablet ? 6 : 4) : _countries.length,
                              itemBuilder: (context, index) {
                                final country = _countries[index];
                                return Container(
                                  width: isLarge ? 200 : isTablet ? 140 : 100,
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildCountryCard(country, cardRadius, chipFontSize),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Loading and Error States
                if (_isLoading)
                  Container(
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
                          'Loading data...',
                          style: TextStyle(
                            color: Color(0xFF3C3C43),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_error != null)
                  _buildErrorWidget()
                else ...[
                  // Latest Jobs Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Latest Jobs',
                          'Discover the most recent job opportunities',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JobsPage()),
                          ),
                          'View All Jobs',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Latest Jobs List
                  if (_latestJobs.isEmpty)
                    Container(
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
                          Icon(
                            Icons.work_off,
                            size: 48,
                            color: Color(0xFF3C3C43),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No latest jobs available',
                            style: TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _latestJobs.length,
                      itemBuilder: (context, index) {
                        final job = _latestJobs[index];
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                            child: JobCard(
                              job: job,
                              onTap: () {
                                _navigateToJobDetails(job);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  // Categories Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Popular Categories',
                          'Explore jobs by category',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoriesPage()),
                          ),
                          'View All Categories',
                          fontSize: 20,
                          subtitleFontSize: 13,
                        ),
                        const SizedBox(height: 8),
                          if (_categories.isEmpty)
                            Container(
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
                                  Icon(
                                    Icons.category_outlined,
                                    size: 48,
                                    color: Color(0xFF3C3C43),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No categories available',
                                    style: TextStyle(
                                      color: Color(0xFF3C3C43),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: CategoryCard(
                                      category: category,
                                      onTap: () {
                                        _navigateToCategoryJobs(category);
                                      },
                                      style: CategoryCardStyle(
                                        backgroundColor: index % 2 == 0 
                                            ? const Color(0xFFFCEEEE)
                                            : Colors.white,
                                        textColor: const Color(0xFF1A1A1A),
                                        iconColor: const Color(0xFF1A1A1A),
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
                  // Add bottom padding to account for sticky banner ad
                  // const SizedBox(height: 60), // Height for banner ad
                ],
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
              Container(
                color: backgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    // Removed: BannerAdWidget(),
                    // Removed: StickyBannerAdWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDebugInfo() async {
    final notificationService = SimpleNotificationService.instance;
    final deviceToken = notificationService.deviceToken;
    final isInitialized = notificationService.isInitialized;
    final areEnabled = await notificationService.areNotificationsEnabled();
    final settings = await notificationService.getNotificationSettings();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Initialized: $isInitialized'),
              const SizedBox(height: 8),
              Text('Notifications Enabled: $areEnabled'),
              const SizedBox(height: 8),
              Text('Authorization Status: ${settings.authorizationStatus}'),
              const SizedBox(height: 8),
              Text('Device Token: ${deviceToken ?? 'Not available'}'),
              const SizedBox(height: 16),
              const Text('To test notifications:'),
              const Text('1. Make sure you have granted notification permissions'),
              const Text('2. Send a test notification from Firebase Console'),
              const Text('3. Check the logs for any errors'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _testLocalNotification();
            },
            child: const Text('Test Local'),
          ),
        ],
      ),
    );
  }

  Future<void> _testLocalNotification() async {
    try {
      final notificationService = SimpleNotificationService.instance;
      if (notificationService.isInitialized) {
        // Use the public test method
        await notificationService.testLocalNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification service not initialized')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}