class Job {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String location;
  final String salary;
  final String jobType;
  final String experience;
  final List<String> skills;
  final String status;
  final int companyId;
  final String imageUrl;
  final String tags;
  final String country;
  final bool isFeatured;
  final int vacancy;
  final int views;
  final String position;
  final String qualification;
  final String industry;
  final DateTime applyBefore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? employer;
  final Map<String, dynamic>? company;
  final String companyName;
  final String? logoUrl;
  final String applyLink;

  Job({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.experience,
    required this.skills,
    required this.status,
    required this.companyId,
    required this.imageUrl,
    required this.tags,
    required this.country,
    required this.isFeatured,
    required this.vacancy,
    required this.views,
    required this.position,
    required this.qualification,
    required this.industry,
    required this.applyBefore,
    required this.createdAt,
    required this.updatedAt,
    this.employer,
    this.company,
    required this.companyName,
    this.logoUrl,
    this.applyLink = '',
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // Parse skills
    List<String> parseSkills(dynamic skills) {
      if (skills == null) return [];
      if (skills is List) return skills.map((s) => s.toString()).toList();
      if (skills is String) return skills.split(',').map((s) => s.trim()).toList();
      return [];
    }

    // Robust company name extraction
    String extractCompanyName(Map<String, dynamic> json) {
      return json['jobEmployer']?['companyName']?.toString() ??
             json['company']?['name']?.toString() ??
             json['employer']?['companyName']?.toString() ??
             json['companyName']?.toString() ??
             'Unknown Company';
    }

    return Job(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      salary: json['salary'] ?? '',
      jobType: json['jobType'] ?? '',
      experience: json['experience'] ?? '',
      skills: parseSkills(json['skills']),
      status: json['status'] ?? 'active',
      companyId: json['companyId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      tags: json['tags'] ?? '',
      country: json['country'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      vacancy: json['vacancy'] ?? 1,
      views: json['views'] ?? 0,
      position: json['position'] ?? '',
      qualification: json['qualification'] ?? '',
      industry: json['industry'] ?? '',
      applyBefore: DateTime.parse(json['applyBefore'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      employer: json['employer'] as Map<String, dynamic>?,
      company: json['company'] as Map<String, dynamic>?,
      companyName: extractCompanyName(json),
      logoUrl: json['jobEmployer']?['logoUrl']?.toString(),
      applyLink: json['applyLink'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'experience': experience,
      'skills': skills,
      'status': status,
      'companyId': companyId,
      'imageUrl': imageUrl,
      'tags': tags,
      'country': country,
      'isFeatured': isFeatured,
      'vacancy': vacancy,
      'views': views,
      'position': position,
      'qualification': qualification,
      'industry': industry,
      'applyBefore': applyBefore.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'employer': employer,
      'company': company,
      'companyName': companyName,
      'logoUrl': logoUrl,
      'applyLink': applyLink,
    };
  }
} 