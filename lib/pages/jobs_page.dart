import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../widgets/hero_section.dart';
import '../widgets/job_card.dart';
import '../widgets/pagination.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/network_aware_widget.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../widgets/new_feature_badge.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../services/navigation_visit_service.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final JobService _jobService = JobService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isHeroVisible = true;
  static const double _heroSectionHeight = 220.0; // Adjust if your HeroSection is taller/shorter
  
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;
  String? _searchQuery;
  String? _selectedJobType;
  String? _selectedLocation;
  String? _selectedExperience;
  String? _selectedSalaryRange;
  int _totalJobs = 0;
  int _totalPages = 0;
  bool _showTodayJobsOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadJobs();
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
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _jobService.getJobs(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        location: _selectedLocation,
        jobType: _selectedJobType,
        experience: _selectedExperience,
        salaryRange: _selectedSalaryRange,
      );

      if (!mounted) return;

      final List<Job> jobs = response['jobs'] as List<Job>;
      _totalJobs = response['total'] as int;
      _totalPages = (_totalJobs / _limit).ceil();

      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading jobs: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading jobs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadJobs,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = null;
      _selectedJobType = null;
      _selectedLocation = null;
      _selectedExperience = null;
      _selectedSalaryRange = null;
      _currentPage = 1;
      _searchController.clear();
      _locationController.clear();
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

  void _showSearchModal() {
    const primaryColor = Colors.deepPurple;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Advanced Search',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Main Search Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Job title, keywords, or company',
                                hintStyle: const TextStyle(color: Color(0xFF3C3C43)),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'City, state, or remote',
                                hintStyle: const TextStyle(color: Color(0xFF3C3C43)),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = _searchController.text;
                                _selectedLocation = _locationController.text;
                                _currentPage = 1;
                              });
                              _loadJobs();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFCEEEE),
                              foregroundColor: const Color(0xFF1A1A1A),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(70, 70),
                              maximumSize: const Size(70, 70),
                              elevation: 2,
                            ),
                            child: const Icon(Icons.search, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Enhanced Filters
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedJobType,
                                hint: const Text('Job Type', style: TextStyle(color: Color(0xFF3C3C43))),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                items: const [
                                  DropdownMenuItem(value: 'full-time', child: Text('Full-time')),
                                  DropdownMenuItem(value: 'part-time', child: Text('Part-time')),
                                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                                  DropdownMenuItem(value: 'internship', child: Text('Internship')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJobType = value;
                                    _currentPage = 1;
                                  });
                                  _loadJobs();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedExperience,
                                hint: const Text('Experience', style: TextStyle(color: Color(0xFF3C3C43))),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                items: const [
                                  DropdownMenuItem(value: 'entry', child: Text('Entry-level')),
                                  DropdownMenuItem(value: 'mid', child: Text('Mid-level')),
                                  DropdownMenuItem(value: 'senior', child: Text('Senior')),
                                  DropdownMenuItem(value: 'executive', child: Text('Executive')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExperience = value;
                                    _currentPage = 1;
                                  });
                                  _loadJobs();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSalaryRange,
                                hint: const Text('Salary', style: TextStyle(color: Color(0xFF3C3C43))),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                items: const [
                                  DropdownMenuItem(value: '0-50000', child: Text('Under \$50k')),
                                  DropdownMenuItem(value: '50000-75000', child: Text('\$50k - \$75k')),
                                  DropdownMenuItem(value: '75000-100000', child: Text('\$75k - \$100k')),
                                  DropdownMenuItem(value: '100000-150000', child: Text('\$100k - \$150k')),
                                  DropdownMenuItem(value: '150000+', child: Text('\$150k+')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSalaryRange = value;
                                    _currentPage = 1;
                                  });
                                  _loadJobs();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
                            label: const Text('Clear Filters', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFCEEEE),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFFFCEEEE)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Today's Jobs Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
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
                            Navigator.pop(context);
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
                                      color: const Color(0xFF1A1A1A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Show Today\'s Jobs Only',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _showTodayJobsOnly ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _showTodayJobsOnly ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      color: _showTodayJobsOnly ? Colors.white : const Color(0xFF1A1A1A),
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
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
                ),
              ),
            ],
          ),
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 700;
              final horizontalPadding = isWideScreen ? 48.0 : 16.0;
              final maxContentWidth = 900.0;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: ListView(
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
                          HeroSection(
                            title: 'All Jobs',
                            subtitle: 'Search through thousands of job listings',
                            trailing: Row(
                              children: [
                                NewFeatureBadge(),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.tune, color: Colors.white),
                                    onPressed: _showSearchModal,
                                  ),
                                ),
                              ],
                            ),
                            searchController: _searchController,
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _currentPage = 1;
                              });
                              _loadJobs();
                            },
                            onSearchSubmitted: () {
                              setState(() {
                                _searchQuery = _searchController.text;
                                _currentPage = 1;
                              });
                              _loadJobs();
                            },
                            onFilterTap: _showSearchModal,
                            searchHint: 'Search jobs...',
                          ),
                        ],
                      ),
                      if (_isLoading && _jobs.isEmpty)
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
                      else if (_error != null && _jobs.isEmpty)
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
                                  onPressed: _loadJobs,
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
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: Color(0xFF3C3C43),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No jobs found',
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
                      else ...[
                        // Today's Jobs Count Indicator
                        if (_showTodayJobsOnly && _jobs.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
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
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: isWideScreen
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 2.7,
                                  ),
                                  itemCount: _jobs.length + (_jobs.length >= 2 ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == 2) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: NativeAdWidget(),
                                      );
                                    }
                                    final jobIndex = index > 2 ? index - 1 : index;
                                    if (jobIndex >= _jobs.length) return const SizedBox.shrink();
                                    return _showTodayJobsOnly 
                                      ? Stack(
                                          children: [
                                            _buildJobCard(_jobs[jobIndex]),
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
                                      : _buildJobCard(_jobs[jobIndex]);
                                  },
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _jobs.length + (_jobs.length >= 2 ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == 2) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: NativeAdWidget(),
                                      );
                                    }
                                    final jobIndex = index > 2 ? index - 1 : index;
                                    if (jobIndex >= _jobs.length) return const SizedBox.shrink();
                                    return _showTodayJobsOnly 
                                      ? Stack(
                                          children: [
                                            _buildJobCard(_jobs[jobIndex]),
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
                                      : _buildJobCard(_jobs[jobIndex]);
                                  },
                                ),
                        ),
                        Center(
                          child: Pagination(
                            currentPage: _currentPage,
                            totalPages: _totalPages,
                            onPageChanged: _changePage,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
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

  Widget _buildJobCard(Job job) {
    return JobCard(
        job: job,
        onTap: () async {
          // Track visit and show ad if conditions are met (after 3 visits)
          await NavigationVisitService().trackVisitAndShowAd('JobsPage');
          
          Navigator.pushNamed(
            context,
            '/job-details',
            arguments: {'jobSlug': job.slug},
          );
        },
    );
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadJobs();
  }
} 