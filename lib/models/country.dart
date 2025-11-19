class Country {
  final String name;
  final String? code;
  final String? slug;
  final int jobCount;

  Country({
    required this.name,
    this.code,
    this.slug,
    this.jobCount = 0,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] ?? 'Unknown Country',
      code: json['code'],
      slug: json['slug'],
      jobCount: json['jobCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'slug': slug,
      'jobCount': jobCount,
    };
  }
} 