import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';
import '../models/job.dart';
import '../utils/logger.dart';

class CountryService {
  final String _baseUrl = 'https://backend.harpaljob.com/api';

  Future<List<Country>> getCountries() async {
    try {
      Logger.info('Fetching countries from: $_baseUrl/jobs/countries');
      final response = await http.get(Uri.parse('$_baseUrl/jobs/countries'));
      Logger.info('Response status: ${response.statusCode}');
      Logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> countriesData = data['countries'] ?? [];
        Logger.info('Parsed ${countriesData.length} countries');
        
        // Log each country's data for debugging
        for (var country in countriesData) {
          Logger.info('Country data: $country');
        }
        
        return countriesData.map((json) => Country.fromJson(json)).toList();
      } else {
        Logger.error('Failed to load countries. Status code: ${response.statusCode}');
        throw Exception('Failed to load countries');
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading countries: $e');
      Logger.error('Stack trace: $stackTrace');
      throw Exception('Failed to load countries: $e');
    }
  }

  Future<CountryJobsResult> getCountryJobs(
    String countrySlug, {
    int page = 1,
    int limit = 10,
    String? sort,
    String? jobType,
    String? experience,
    double? minSalary,
    double? maxSalary,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (sort != null) 'sort': sort,
        if (jobType != null) 'jobType': jobType,
        if (experience != null) 'experience': experience,
        if (minSalary != null) 'minSalary': minSalary.toString(),
        if (maxSalary != null) 'maxSalary': maxSalary.toString(),
        if (search != null) 'search': search,
      };

      final uri = Uri.parse('$_baseUrl/jobs/country/$countrySlug').replace(queryParameters: queryParams);
      Logger.info('Fetching country jobs from: $uri');
      
      final response = await http.get(uri);
      Logger.info('Response status: ${response.statusCode}');
      Logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Logger.info('Successfully loaded country jobs data');
        return CountryJobsResult.fromJson(data);
      } else {
        Logger.error('Failed to load country jobs. Status code: ${response.statusCode}');
        throw Exception('Failed to load country jobs');
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading country jobs: $e');
      Logger.error('Stack trace: $stackTrace');
      throw Exception('Failed to load country jobs: $e');
    }
  }
}

class CountryJobsResult {
  final Country country;
  final List<Job> jobs;
  final bool hasMore;
  final int totalJobs;
  final Map<String, int> statistics;

  CountryJobsResult({
    required this.country,
    required this.jobs,
    required this.hasMore,
    required this.totalJobs,
    required this.statistics,
  });

  factory CountryJobsResult.fromJson(Map<String, dynamic> json) {
    final statistics = json['statistics'] ?? {};
    return CountryJobsResult(
      country: Country(
        name: json['country'],
        slug: json['countrySlug'],
        jobCount: statistics['totalJobs'] ?? 0,
      ),
      jobs: List<Job>.from(json['jobs'].map((job) => Job.fromJson(job))),
      hasMore: json['hasMore'] ?? false,
      totalJobs: statistics['totalJobs'] ?? json['totalJobs'] ?? 0,
      statistics: {
        'full-time': statistics['fullTime'] ?? statistics['full-time'] ?? 0,
        'part-time': statistics['partTime'] ?? statistics['part-time'] ?? 0,
        'contract': statistics['contract'] ?? 0,
        'internship': statistics['internship'] ?? 0,
      },
    );
  }
} 