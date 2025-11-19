import '../models/job.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int jobCount;
  final List<Job> categoryJobs;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    this.jobCount = 0,
    this.categoryJobs = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Parse job count
    int parseJobCount(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    // Parse category jobs
    List<Job> parseCategoryJobs(dynamic jobs) {
      if (jobs == null) return [];
      if (jobs is! List) return [];
      return jobs.map((job) => Job.fromJson(job)).toList();
    }

    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      jobCount: parseJobCount(json['jobCount'] ?? json['job_count'] ?? 0),
      categoryJobs: parseCategoryJobs(json['categoryJobs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'isActive': isActive,
      'jobCount': jobCount,
      'categoryJobs': categoryJobs.map((job) => job.toJson()).toList(),
    };
  }
} 