import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/job_service.dart';
import '../widgets/job_card.dart';
import '../widgets/loading_indicator.dart';
import 'package:logger/logger.dart';
import '../widgets/network_aware_widget.dart';
import '../pages/job_details_page.dart';
import '../pages/search_results_page.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/new_feature_badge.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';

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

class CategoryJobsPage extends StatefulWidget {
  final Category category;

  const CategoryJobsPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryJobsPage> createState() => _CategoryJobsPageState();
}

class _CategoryJobsPageState extends State<CategoryJobsPage> {
  final CategoryService _categoryService = CategoryService();
  final JobService _jobService = JobService();
  final Logger _logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<Job> _jobs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  bool _showTodayJobsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMorePages = true;
      });
    }

    if (_isLoading || _isLoadingMore) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _jobs = [];
      } else {
        _isLoadingMore = true;
      }
      _hasError = false;
    });

    try {
      _logger.d('Loading jobs for category: ${widget.category.name}, page: $_currentPage');
      
      final result = await _categoryService.getCategoryJobs(
        widget.category.id,
        page: _currentPage,
        limit: 10,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      setState(() {
        if (refresh) {
          _jobs = result['jobs'] as List<Job>;
        } else {
          _jobs.addAll(result['jobs'] as List<Job>);
        }
        _hasMorePages = (result['jobs'] as List<Job>).length >= 10; // Assuming 10 jobs per page
        _isLoading = false;
        _isLoadingMore = false;
      });

      _logger.d('Loaded ${(result['jobs'] as List<Job>).length} jobs for category ${widget.category.name}');
    } catch (e) {
      _logger.e('Error loading jobs for category ${widget.category.name}: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load jobs. Please try again.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreJobs() async {
    if (!_hasMorePages || _isLoadingMore) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadJobs();
  }

  void _onSearch(String query) {
    print('DEBUG: _onSearch called with query: "$query"');
    // Remove automatic navigation - let the search button handle it
    // This method is now only used for the onSubmitted callback of the TextField
  }

  void _onLocationSearch(String location) {
    print('DEBUG: _onLocationSearch called with location: "$location"');
    // Remove automatic navigation - let the search button handle it
    // This method is now only used for the onSubmitted callback of the TextField
  }

  List<Job> _filterLast24Hours(List<Job> jobs) {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    
    print('Filtering jobs from last 24 hours...');
    print('Current time: $now');
    print('24 hours ago: $twentyFourHoursAgo');
    
    final filtered = jobs.where((job) {
      final isToday = job.createdAt.isAfter(twentyFourHoursAgo);
      print('Job: \'${job.title}\' createdAt: \'${job.createdAt}\' - Today: $isToday');
      return isToday;
    }).toList();
    
    // Sort by newest first
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('Found ${filtered.length} jobs from today out of ${jobs.length} total jobs');
    return filtered;
  }

  // Remove the old navigation methods as they're no longer needed

  void _performSearch() {
    final searchQuery = _searchController.text.trim();
    final locationQuery = _locationController.text.trim();
    
    if (searchQuery.isNotEmpty || locationQuery.isNotEmpty) {
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
              Text('Searching${searchQuery.isNotEmpty ? ' for "$searchQuery"' : ''}${locationQuery.isNotEmpty ? ' in $locationQuery' : ''}...'),
            ],
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Navigate to SearchResultsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: searchQuery,
            initialLocation: locationQuery.isNotEmpty ? locationQuery : null,
          initialJobType: null,
        ),
      ),
    );
    } else {
      // Show error if both fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job title or location to search'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
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
        body: ListView(
          padding: EdgeInsets.zero,
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
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  widget.category.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                NewFeatureBadge(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
            Container(
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search jobs in ${widget.category.name}...',
                            hintStyle: const TextStyle(color: textSecondaryColor),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCEEEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Color(0xFF1A1A1A),
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (value) {
                            // Trigger search when Enter is pressed
                            _performSearch();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location Input
                      Container(
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
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Search by location...',
                            hintStyle: const TextStyle(color: textSecondaryColor),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCEEEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF1A1A1A),
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (value) {
                            // Trigger search when Enter is pressed
                            _performSearch();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text(
                            'Search Jobs',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                                                  ),
                        ),
                        const SizedBox(height: 16),
                        // Today's Jobs Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showTodayJobsOnly = !_showTodayJobsOnly;
                                });
                                if (_showTodayJobsOnly) {
                                  final todayJobs = _filterLast24Hours(_jobs);
                                  setState(() {
                                    _jobs = todayJobs;
                                  });
                                } else {
                                  _loadJobs(refresh: true); // Reload all jobs
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _showTodayJobsOnly ? Icons.today : Icons.today_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Show Today\'s Jobs Only',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _showTodayJobsOnly ? Colors.white : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _showTodayJobsOnly ? 'ON' : 'OFF',
                                        style: TextStyle(
                                          color: _showTodayJobsOnly ? const Color(0xFF6A11CB) : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ),
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
                      'Loading jobs...',
                      style: TextStyle(
                        color: Color(0xFF3C3C43),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_hasError)
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
                      'Could not load jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        _errorMessage,
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
                        onPressed: () => _loadJobs(refresh: true),
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
              )
            else if (_jobs.isEmpty)
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Icon(
                        Icons.work_outline,
                      size: 64,
                      color: Color(0xFF3C3C43),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs found in ${widget.category.name}',
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
                        onPressed: () => _loadJobs(refresh: true),
                        icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
                        label: const Text(
                          'Refresh',
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
              )
            else ...[
              // Today's Jobs Count Indicator
              if (_showTodayJobsOnly && _jobs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: const Color(0xFF3C3C43),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sorted by newest first',
                            style: TextStyle(
                              color: const Color(0xFF3C3C43),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_jobs.length} today',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _jobs.length + (_jobs.length >= 2 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 2) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: NativeAdWidget(
                            onAdLoaded: () => print('Native ad loaded!'),
                            onAdFailedToLoad: () => print('Native ad failed!'),
                          ),
                        ),
                      );
                    }
                    final jobIndex = index > 2 ? index - 1 : index;
                    if (jobIndex >= _jobs.length) return const SizedBox.shrink();
                    final job = _jobs[jobIndex];
                    return _showTodayJobsOnly 
                      ? Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                onTap: () async {
                                  // Direct navigation - no interstitial for minor navigation
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JobDetailsPage(jobSlug: job.slug),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                            onTap: () async {
                              // Direct navigation - no interstitial for minor navigation
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JobDetailsPage(jobSlug: job.slug),
                                ),
                              );
                            },
                          ),
                        );
                  },
                ),
              ),
              if (_hasMorePages)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      onPressed: _loadMoreJobs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF1A1A1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                                ),
                              )
                            : const Text(
                                'Load More',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ), // <-- Scaffold
    ), // <-- AnnotatedRegion
  ); // <-- NetworkAwareWidget
  }
} 