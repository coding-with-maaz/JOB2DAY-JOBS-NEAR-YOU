import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../widgets/job_card.dart';
import '../widgets/pagination.dart';
import '../widgets/loading_indicator.dart';
import '../pages/job_details_page.dart';
import '../widgets/network_aware_widget.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';

// Design system colors
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
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  elevation: 2,
);

final ButtonStyle unifiedOutlinedButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: primaryColor,
  side: BorderSide(color: primaryColor, width: 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
);

final TextStyle unifiedHeaderStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
  fontSize: 24,
  letterSpacing: 0.5,
  fontFamily: 'Poppins',
);

final TextStyle unifiedBodyStyle = TextStyle(
  color: textSecondaryColor,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
);

final InputDecoration unifiedInputDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  labelStyle: TextStyle(color: textSecondaryColor, fontFamily: 'Poppins'),
  hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7), fontFamily: 'Poppins'),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: activeTabColor, width: 1),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: activeTabColor, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: primaryColor, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
);

Widget buildPill(String text, {bool selected = false, void Function()? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? activeTabColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? primaryColor : activeTabColor.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? primaryColor : textSecondaryColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
      ),
    ),
  );
}

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final String? initialLocation;
  final String? initialJobType;

  const SearchResultsPage({
    super.key,
    required this.initialQuery,
    this.initialLocation,
    this.initialJobType,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final JobService _jobService = JobService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

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
  String _sortBy = 'newest';
  int _totalJobs = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _locationController.text = widget.initialLocation ?? '';
    _selectedJobType = widget.initialJobType;
    _searchQuery = widget.initialQuery;
    _selectedLocation = widget.initialLocation;
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _jobService.searchJobs(
        query: _searchQuery ?? '',
        page: _currentPage,
        limit: _limit,
        location: _selectedLocation,
        jobType: _selectedJobType,
        experience: _selectedExperience,
        minSalary: _selectedSalaryRange != null ? double.tryParse(_selectedSalaryRange!.split('-')[0]) : null,
        maxSalary: _selectedSalaryRange != null ? double.tryParse(_selectedSalaryRange!.split('-')[1]) : null,
        sort: _sortBy,
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

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadJobs();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = widget.initialQuery;
      _selectedJobType = widget.initialJobType;
      _selectedLocation = widget.initialLocation;
      _selectedExperience = null;
      _selectedSalaryRange = null;
      _sortBy = 'newest';
      _currentPage = 1;
      _searchController.text = widget.initialQuery;
      _locationController.text = widget.initialLocation ?? '';
    });
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: NetworkAwareWidget(
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('Search Results', style: unifiedHeaderStyle.copyWith(fontSize: 26)),
            backgroundColor: Colors.transparent,
            foregroundColor: textPrimaryColor,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: textPrimaryColor),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: primaryColor, size: 48),
                          const SizedBox(height: 16),
                          Text('Error loading jobs', style: unifiedHeaderStyle.copyWith(fontSize: 20, color: primaryColor)),
                          const SizedBox(height: 8),
                          Text(_error ?? 'Unknown error', style: unifiedBodyStyle, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadJobs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
                            style: unifiedButtonStyle,
                          ),
                        ],
                      ),
                    )
                  : _jobs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_outline, size: 64, color: inactiveTabColor),
                              const SizedBox(height: 16),
                              Text('No jobs found', style: unifiedHeaderStyle.copyWith(fontSize: 20, color: inactiveTabColor)),
                              const SizedBox(height: 8),
                              Text('Try adjusting your search criteria', style: unifiedBodyStyle, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    decoration: unifiedInputDecoration.copyWith(
                                        hintText: 'Search jobs...'),
                                    style: unifiedBodyStyle,
                                    onSubmitted: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                        _currentPage = 1;
                                      });
                                      _loadJobs();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _locationController,
                                    decoration: unifiedInputDecoration.copyWith(
                                        hintText: 'Enter location...'),
                                    style: unifiedBodyStyle,
                                    onSubmitted: (value) {
                                      setState(() {
                                        _selectedLocation = value.isNotEmpty ? value : null;
                                        _currentPage = 1;
                                      });
                                      _loadJobs();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = _searchController.text;
                                          _selectedLocation = _locationController.text.isNotEmpty ? _locationController.text : null;
                                          _currentPage = 1;
                                        });
                                        _loadJobs();
                                      },
                                      icon: const Icon(Icons.search, color: Colors.white),
                                      label: const Text('Search', style: TextStyle(fontFamily: 'Poppins')),
                                      style: unifiedButtonStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search Results Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: activeTabColor, width: 1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Search Results', style: unifiedHeaderStyle.copyWith(fontSize: 20, color: primaryColor)),
                                            const SizedBox(height: 4),
                                            Text('${_totalJobs} jobs found', style: unifiedBodyStyle.copyWith(color: inactiveTabColor)),
                                          ],
                                        ),
                                      ),
                                      if (_searchQuery?.isNotEmpty == true || _selectedLocation?.isNotEmpty == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: activeTabColor,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: activeTabColor.withOpacity(0.7)),
                                          ),
                                          child: Text(
                                            '${_searchQuery?.isNotEmpty == true ? "Search: $_searchQuery" : ""}${_searchQuery?.isNotEmpty == true && _selectedLocation?.isNotEmpty == true ? " | " : ""}${_selectedLocation?.isNotEmpty == true ? "Location: $_selectedLocation" : ""}',
                                            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Jobs List
                            ...List.generate(_jobs.length + (_jobs.length >= 2 ? 1 : 0), (index) {
                              if (_jobs.length >= 2 && index == 2) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: NativeAdWidget(),
                                );
                              }
                              final jobIndex = index > 2 && _jobs.length >= 2 ? index - 1 : index;
                              if (jobIndex >= _jobs.length) return const SizedBox.shrink();
                              final job = _jobs[jobIndex];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
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
                            }),
                            if (_jobs.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Pagination(
                                  currentPage: _currentPage,
                                  totalPages: _totalPages,
                                  onPageChanged: _onPageChanged,
                                ),
                              ),
                          ],
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