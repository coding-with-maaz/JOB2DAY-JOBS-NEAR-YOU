import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../widgets/job_card.dart';
import '../widgets/network_aware_widget.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/new_feature_badge.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../widgets/google_ads/dynamic_ad_config.dart';
import '../pages/job_details_page.dart';

class TodayJobsPage extends StatefulWidget {
  const TodayJobsPage({super.key});

  @override
  State<TodayJobsPage> createState() => _TodayJobsPageState();
}

class _TodayJobsPageState extends State<TodayJobsPage> {
  final JobService _jobService = JobService();
  final ScrollController _scrollController = ScrollController();
  
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;
  int _totalJobs = 0;

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

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _scrollController.addListener(_onScroll);
    

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      if (currentScroll >= maxScroll - 200) {
        if (!_isLoading && _hasMore) {
          _loadMoreJobs();
        }
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(
              _error?.toLowerCase().contains('connection') ?? false
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline,
              color: _error?.toLowerCase().contains('connection') ?? false
                  ? Colors.orange
                  : Colors.red,
              size: 64,
          ),
          const SizedBox(height: 16),
          Text(
              _error?.toLowerCase().contains('connection') ?? false
                  ? 'Connection Error'
                  : 'Error loading jobs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
              _error?.toLowerCase().contains('connection') ?? false
                  ? 'Please check your internet connection and try again'
                  : _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_error?.toLowerCase().contains('connection') ?? false) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentPage = 1;
                        _jobs.clear();
                        _hasMore = true;
                      });
                      _loadJobs();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Check Settings'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
          ),
        ],
              ],
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
          backgroundColor: const Color(0xFFFFF7F4),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                  Color(0xFF6D5BFF),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Today\'s Jobs',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            NewFeatureBadge(),
                          ],
                        ),

                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _currentPage = 1;
                            _jobs.clear();
                            _hasMore = true;
                          });
                          await _loadJobs();
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subtitle
                              const Text(
                                'Latest job opportunities posted in the last 24 hours',
                                style: TextStyle(
                                  color: Color(0xFF3C3C43),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Sort Indicator and Job Count
                              Row(
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
                                  if (_jobs.isNotEmpty)
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
                              const SizedBox(height: 20),
                              // Jobs List
                              if (_isLoading && _jobs.isEmpty)
                                Container(
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
                                        'Loading today\'s jobs...',
                                        style: TextStyle(
                                          color: Color(0xFF3C3C43),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_error != null && _jobs.isEmpty)
                                _buildErrorWidget()
                              else if (_jobs.isEmpty)
                                Container(
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
                                        Icons.today_rounded,
                                        size: 64,
                                        color: Color(0xFF3C3C43),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No jobs posted today',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    ...List.generate(_jobs.length, (index) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Stack(
                                        children: [
                                          JobCard(
                                            job: _jobs[index],
                                            onTap: () async {
                                              // Direct navigation - no interstitial for minor navigation
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => JobDetailsPage(jobSlug: _jobs[index].slug),
                                                ),
                                              );
                                            },
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
                                      ),
                                    )),
                                    if (_hasMore && _isLoading)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    if (_hasMore && !_isLoading)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Scroll to load more',
                                            style: TextStyle(
                                              color: const Color(0xFF3C3C43),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
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
                  ),
                ],
              ),
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

  Future<void> _loadJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading today\'s jobs...');
      print('Page: $_currentPage, Limit: $_limit');
      
      final response = await _jobService.getTodayJobs(
        page: _currentPage,
        limit: _limit,
        sort: 'newest',
      );

      if (!mounted) return;

      final List<Job> jobs = response['jobs'] as List<Job>;
      List<Job> filteredJobs = _filterLast24Hours(jobs);

      _totalJobs = filteredJobs.length;

      setState(() {
        _jobs = filteredJobs;
        _isLoading = false;
        _hasMore = filteredJobs.length > 0 && jobs.length == _limit;
      });
    } catch (e) {
      print('Error loading today\'s jobs: $e');
      if (!mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('connection') ||
          errorMessage.toLowerCase().contains('timeout') ||
          errorMessage.toLowerCase().contains('network')) {
        errorMessage = 'Please check your internet connection and try again';
      }

      setState(() {
        _isLoading = false;
        _error = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  errorMessage.toLowerCase().contains('connection') ? Icons.wifi_off_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: errorMessage.toLowerCase().contains('connection') ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadJobs,
              textColor: Colors.white,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading more today\'s jobs...');
      print('Page: ${_currentPage + 1}, Limit: $_limit');
      
      final response = await _jobService.getTodayJobs(
        page: _currentPage + 1,
        limit: _limit,
        sort: 'newest',
      );

      if (!mounted) return;

      final List<Job> jobs = response['jobs'] as List<Job>;
      List<Job> filteredJobs = _filterLast24Hours(jobs);

      setState(() {
        _jobs.addAll(filteredJobs);
        _currentPage++;
        _isLoading = false;
        _hasMore = filteredJobs.length > 0 && jobs.length == _limit;
      });
    } catch (e) {
      print('Error loading more today\'s jobs: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more today\'s jobs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


} 