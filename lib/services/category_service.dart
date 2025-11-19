import 'package:dio/dio.dart';
import '../models/job.dart';
import '../models/category.dart';
import '../config/api_config.dart';

class CategoryService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: ApiConfig.headers,
    connectTimeout: Duration(milliseconds: ApiConfig.timeout),
    receiveTimeout: Duration(milliseconds: ApiConfig.timeout),
  ));

  Future<Map<String, dynamic>> getCategories({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get('/categories', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      if (response.data == null) {
        throw ApiException('Response data is null');
      }

      if (response.data is List) {
        // If backend returns a list directly
      final List<dynamic> data = response.data;
        return {
          'categories': data.map((json) => Category.fromJson(json)).toList(),
          'total': data.length,
          'page': page,
          'limit': limit,
        };
      } else {
        // If backend returns a map/object
        final Map<String, dynamic> data = response.data;
        final List<dynamic> categoriesData = data['categories'] as List<dynamic>;
        return {
          'categories': categoriesData.map((json) => Category.fromJson(json)).toList(),
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      }
    } on DioException catch (e) {
      throw ApiException('Failed to fetch categories: ${e.message}', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to fetch categories: $e');
    }
  }

  Future<Category> getCategoryBySlug(String slug) async {
    try {
      final response = await _dio.get('/categories/$slug');
      
      if (response.data == null) {
        throw ApiException('Response data is null');
      }

      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException('Failed to fetch category: ${e.message}', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to fetch category: $e');
    }
  }

  Future<Map<String, dynamic>> getCategoryJobs(
    int categoryId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? jobType,
    String? location,
    String? experience,
    double? minSalary,
    double? maxSalary,
    String? sort,
  }) async {
    try {
      final response = await _dio.get('/jobs/category/$categoryId', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (jobType != null) 'jobType': jobType,
        if (location != null) 'location': location,
        if (experience != null) 'experience': experience,
        if (minSalary != null) 'minSalary': minSalary,
        if (maxSalary != null) 'maxSalary': maxSalary,
        if (sort != null) 'sort': sort,
      });
      
      if (response.data == null) {
        throw ApiException('Response data is null');
      }

      if (response.data is List) {
        // If backend returns a list directly
        final List<dynamic> jobsData = response.data;
        return {
          'jobs': jobsData.map((json) => Job.fromJson(json)).toList(),
          'total': jobsData.length,
          'page': page,
          'limit': limit,
        };
      } else {
        // If backend returns a map/object
      final Map<String, dynamic> data = response.data;
      final List<dynamic> jobsData = data['jobs'] as List<dynamic>;
      return {
        'jobs': jobsData.map((json) => Job.fromJson(json)).toList(),
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
      };
      }
    } on DioException catch (e) {
      throw ApiException('Failed to fetch category jobs: ${e.message}', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to fetch category jobs: $e');
    }
  }

  Future<int> getTotalCategoriesCount() async {
    try {
      final response = await _dio.get('/jobs/categories/total');
      
      if (response.data == null) {
        throw ApiException('Response data is null');
      }

      return response.data['totalCategories'];
    } on DioException catch (e) {
      throw ApiException('Failed to fetch total categories count: ${e.message}', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to fetch total categories count: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
} 