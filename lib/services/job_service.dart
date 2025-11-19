import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../config/api_config.dart';

class JobService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getJobs({
    int page = 1,
    int limit = 10,
    String? search,
    String? location,
    String? jobType,
    String? experience,
    String? salaryRange,
    String? sortBy,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (location != null && location.isNotEmpty) 'location': location,
        if (jobType != null && jobType.isNotEmpty) 'jobType': jobType,
        if (experience != null && experience.isNotEmpty) 'experience': experience,
        if (salaryRange != null && salaryRange.isNotEmpty) 'salaryRange': salaryRange,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      };

      final uri = Uri.parse('$baseUrl/jobs').replace(queryParameters: queryParams);
      print('Fetching jobs from: $uri');
      
      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<Job> jobs = (data['jobs'] as List)
            .map((json) => Job.fromJson(json as Map<String, dynamic>))
            .toList();
        print('Successfully loaded ${jobs.length} jobs');
        return {
          'jobs': jobs,
          'total': data['total'] ?? jobs.length,
        };
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to load jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while loading jobs: $e');
      throw Exception('Failed to load jobs: $e');
    }
  }

  Future<Job> getJobBySlug(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/$slug'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Job.fromJson(data);
      } else {
        throw Exception('Failed to fetch job: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch job: $e');
    }
  }

  Future<List<Job>> getFeaturedJobs({
    int page = 1,
    int limit = 10,
    String? location,
    String? jobType,
    String? experience,
    double? minSalary,
    double? maxSalary,
    String? sort,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/featured').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (location != null) 'location': location,
          if (jobType != null) 'jobType': jobType,
          if (experience != null) 'experience': experience,
          if (minSalary != null) 'minSalary': minSalary.toString(),
          if (maxSalary != null) 'maxSalary': maxSalary.toString(),
          if (sort != null) 'sort': sort,
        },
      ));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch featured jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch featured jobs: $e');
    }
  }

  Future<Map<String, dynamic>> getJobsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/category/$categoryId').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ));
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        print('DEBUG: API response type: ${data.runtimeType}');
        print('DEBUG: API response data: $data');
        
        // Handle different response formats
        List<Job> jobs;
        int total = 0;
        int currentPage = page;
        int currentLimit = limit;
        
        if (data is List) {
          // API returned a list directly
          jobs = data.map((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
          total = jobs.length;
        } else if (data is Map<String, dynamic>) {
          // API returned a map with jobs key
          if (data.containsKey('jobs')) {
            jobs = (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
          } else {
            // Try to parse the entire response as a list of jobs
            jobs = data.entries.map((entry) {
              if (entry.value is Map<String, dynamic>) {
                return Job.fromJson(entry.value as Map<String, dynamic>);
              }
              throw Exception('Invalid job data format');
            }).toList();
          }
          total = data['total'] ?? jobs.length;
          currentPage = data['page'] ?? page;
          currentLimit = data['limit'] ?? limit;
        } else {
          throw Exception('Unexpected response format');
        }
        
        return {
          'jobs': jobs,
          'total': total,
          'page': currentPage,
          'limit': currentLimit,
        };
      } else {
        throw Exception('Failed to fetch jobs by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jobs by category: $e');
    }
  }

  Future<Map<String, dynamic>> getJobsByCountry(
    String country, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/country/$country').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'jobs': (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList(),
          'total': data['total'],
          'page': data['page'],
          'limit': data['limit'],
        };
      } else {
        throw Exception('Failed to fetch jobs by country: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jobs by country: $e');
    }
  }

  Future<Map<String, dynamic>> getJobsByCompany(
    String companyName, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/company/$companyName').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'jobs': (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList(),
          'total': data['total'],
          'page': data['page'],
          'limit': data['limit'],
        };
      } else {
        throw Exception('Failed to fetch jobs by company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jobs by company: $e');
    }
  }

  Future<Map<String, dynamic>> getTodayJobs({
    int page = 1,
    int limit = 10,
    String? sort,
  }) async {
    try {
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Use the main jobs endpoint with a date filter
      final response = await http.get(Uri.parse('$baseUrl/jobs').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'date': today,
          if (sort != null) 'sort': sort,
        },
      ));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'jobs': (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList(),
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      } else {
        throw Exception('Failed to fetch today\'s jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch today\'s jobs: $e');
    }
  }

  Future<int> getTotalJobsCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs/total'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['totalJobs'];
      } else {
        throw Exception('Failed to fetch total jobs count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch total jobs count: $e');
    }
  }

  Future<Map<String, dynamic>> searchJobs({
    required String query,
    int page = 1,
    int limit = 10,
    String? location,
    String? jobType,
    String? experience,
    double? minSalary,
    double? maxSalary,
    String? sort,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'search': query,
          if (location != null) 'location': location,
          if (jobType != null) 'jobType': jobType,
          if (experience != null) 'experience': experience,
          if (minSalary != null) 'minSalary': minSalary.toString(),
          if (maxSalary != null) 'maxSalary': maxSalary.toString(),
          if (sort != null) 'sort': sort,
        },
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'jobs': (data['jobs'] as List).map((json) => Job.fromJson(json as Map<String, dynamic>)).toList(),
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      } else {
        throw Exception('Failed to search jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search jobs: $e');
    }
  }
} 