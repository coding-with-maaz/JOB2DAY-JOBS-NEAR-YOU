import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/job.dart';
import '../services/country_service.dart';
import '../widgets/hero_section.dart';
import '../widgets/jobs_list.dart';
import '../widgets/pagination.dart';
import '../widgets/job_card.dart';
import 'job_details_page.dart';
import '../widgets/network_aware_widget.dart';
import '../utils/date_formatter.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import 'package:flutter/services.dart';
import 'search_results_page.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/animated_resume_fab.dart';
import 'resume_maker_page.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../widgets/new_feature_badge.dart';

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

class CountryJobsPage extends StatefulWidget {
  final Country country;

  const CountryJobsPage({
    super.key,
    required this.country,
  });

  @override
  State<CountryJobsPage> createState() => _CountryJobsPageState();
}

class _CountryJobsPageState extends State<CountryJobsPage> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  final _countryService = CountryService();
  final _scrollController = ScrollController();
  
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedJobType;
  String? _searchQuery;
  Map<String, int> _statistics = {};
  int _totalJobs = 0;
  final int _limit = 10;
  int _totalPages = 1;
  bool _showTodayJobsOnly = false;

  @override
  void initState() {
    super.initState();
    _showInterstitialAd();
    _loadJobs();
  }

  Future<void> _showInterstitialAd() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await InterstitialAdManager.showAdOnPage('CountryJobsPage');
      // Optionally log or handle result
    } catch (e) {
      // Optionally log error
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _countryService.getCountryJobs(
        widget.country.slug!,
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        jobType: _selectedJobType,
      );

      // Debug logging
      print('DEBUG: Country jobs loaded');
      print('DEBUG: Total jobs from API: ${result.totalJobs}');
      print('DEBUG: Jobs count: ${result.jobs.length}');
      print('DEBUG: Statistics: ${result.statistics}');
      print('DEBUG: Has more: ${result.hasMore}');

      setState(() {
        _jobs = result.jobs;
        _hasMore = result.hasMore;
        _statistics = result.statistics;
        _totalJobs = result.totalJobs;
        _totalPages = (_totalJobs / _limit).ceil();
        _isLoading = false;
      });

      // Debug logging after setState
      print('DEBUG: After setState - _totalJobs: $_totalJobs');
      print('DEBUG: After setState - _statistics: $_statistics');
    } catch (e) {
      print('DEBUG: Error loading jobs: $e');
      setState(() {
        _errorMessage = 'Failed to load jobs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadJobs();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page on new search
    });
    _loadJobs();
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

  Widget _buildStatItem(String label, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3C3C43),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
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
          try {
            // Show interstitial ad before navigation
            print('CountryJobsPage: Attempting to show interstitial ad for JobView');
            final success = await InterstitialAdManager.showAdOnPage('CountryJobsPage');
            print('CountryJobsPage: Interstitial ad show result for JobView: $success');
            
            if (!mounted) return;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsPage(jobSlug: job.slug),
              ),
            );
          } catch (e) {
            print('CountryJobsPage: Error showing interstitial ad for JobView: $e');
            // Navigate even if ad fails
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsPage(jobSlug: job.slug),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company Logo and Job Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: job.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              job.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            color: Colors.white,
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
                          job.title.isNotEmpty ? job.title : 'Untitled Position',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company?['name'] ?? 
                          job.employer?['companyName'] ?? 
                          job.companyName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (job.isFeatured)
                    Container(
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
                              fontSize: 11,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              
              // Job Type and Location
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_outline, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job.jobType.isNotEmpty == true ? job.jobType : 'Not Specified',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[700]!.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job.location.isNotEmpty == true ? job.location : 'Location Not Specified',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Salary and Posted Time
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (job.salary.isNotEmpty == true)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[700]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[700]!.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job.salary,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job.createdAt != null 
                                  ? 'Posted ${DateFormatter.format(job.createdAt)}'
                                  : 'Posted date not available',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _onFilterTap() {
    const primaryColor = Color(0xFF1976D2);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Jobs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedJobType,
              decoration: InputDecoration(
                labelText: 'Job Type',
                labelStyle: TextStyle(color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'full-time', child: Text('Full Time')),
                DropdownMenuItem(value: 'part-time', child: Text('Part Time')),
                DropdownMenuItem(value: 'contract', child: Text('Contract')),
                DropdownMenuItem(value: 'internship', child: Text('Internship')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedJobType = value;
                });
                _loadJobs();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            controller: _scrollController,
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
                                    'Jobs in ${widget.country.name}',
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
                        const SizedBox(height: 16),
                        Text(
                          'Discover job opportunities in ${widget.country.name} from top employers.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
                              hintText: 'Search jobs in ${widget.country.name}...',
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
                            onChanged: _onSearchChanged,
                            onSubmitted: (value) {
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
                                  _loadJobs(); // Reload all jobs
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
            if (_isLoading && _jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  ),
                ),
              )
            else if (_errorMessage != null && _jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: primaryColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading jobs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadJobs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search criteria',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
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
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    // childAspectRatio: 1.8, // Removed to allow ad to expand
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _jobs.length + (_jobs.length >= 2 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 2) {
                      return SizedBox(
                        width: 400,
                        height: 400,
                        child: NativeAdWidget(
                          onAdLoaded: () => print('Native ad loaded!'),
                          onAdFailedToLoad: () => print('Native ad failed!'),
                        ),
                      );
                    }
                    final jobIndex = index > 2 ? index - 1 : index;
                    if (jobIndex >= _jobs.length) return const SizedBox.shrink();
                    final job = _jobs[jobIndex];
                    return _showTodayJobsOnly 
                      ? Stack(
                          children: [
                            _buildJobCard(job),
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
                      : _buildJobCard(job);
                  },
                ),
              ),
              if (_totalPages > 1)
                Center(
                  child: Pagination(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    onPageChanged: _onPageChanged,
                  ),
                ),
            ],
          ],
          ),
          bottomNavigationBar: const BannerAdWidget(),
        ),
      ),
    );
  }
} 