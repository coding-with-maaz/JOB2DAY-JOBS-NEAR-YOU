class Reference {
  final String name;
  final String relationship;
  final String contact;

  Reference({required this.name, required this.relationship, required this.contact});
}

class ResumeData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final List<Experience> experiences;
  final List<Education> education;
  final List<String> skills;
  final List<String>? languages;
  final List<Reference>? references;

  // Quick Info fields
  final String? linkedin;
  final String? website;
  final String? nationality;
  final String? dob;
  final String? gender;
  final String? maritalStatus;
  final String? address2;
  final String? city;
  final String? state;
  final String? zip;

  ResumeData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    required this.experiences,
    required this.education,
    required this.skills,
    this.languages,
    this.references,
    this.linkedin,
    this.website,
    this.nationality,
    this.dob,
    this.gender,
    this.maritalStatus,
    this.address2,
    this.city,
    this.state,
    this.zip,
  });

  // Add this static method for demo data
  static ResumeData demo() {
    return ResumeData(
      name: 'Jane Doe',
      email: 'jane.doe@email.com',
      phone: '+1 234 567 890',
      address: '123 Main St, Springfield',
      summary: 'Experienced software engineer with a passion for developing innovative programs that expedite the efficiency and effectiveness of organizational success.',
      experiences: [
        Experience(
          company: 'Tech Solutions',
          role: 'Senior Developer',
          duration: '2019 - Present',
          description: 'Lead a team of 8 developers to build scalable web applications. Improved system performance by 30%.',
        ),
        Experience(
          company: 'Webify',
          role: 'Frontend Developer',
          duration: '2016 - 2019',
          description: 'Developed and maintained the company website and client projects using React and Angular.',
        ),
      ],
      education: [
        Education(
          institute: 'Springfield University',
          degree: 'B.Sc. Computer Science',
          duration: '2012 - 2016',
        ),
      ],
      skills: [
        'Flutter', 'Dart', 'JavaScript', 'React', 'Node.js', 'UI/UX Design', 'Agile', 'Git', 'REST APIs',
      ],
      languages: ['English', 'Spanish'],
      references: [
        Reference(
          name: 'John Smith',
          relationship: 'Manager at Tech Solutions',
          contact: 'john.smith@email.com | +1 555 123 456',
        ),
        Reference(
          name: 'Emily Johnson',
          relationship: 'Professor at Springfield University',
          contact: 'emily.johnson@university.edu | +1 555 987 654',
        ),
      ],
      linkedin: 'linkedin.com/in/janedoe',
      website: 'janedoe.dev',
      nationality: 'American',
      dob: '1992-05-14',
      gender: 'Female',
      maritalStatus: 'Single',
      address2: 'Apt 4B',
      city: 'Springfield',
      state: 'Illinois',
      zip: '62704',
    );
  }
}

class Experience {
  final String company;
  final String role;
  final String duration;
  final String description;

  Experience({required this.company, required this.role, required this.duration, required this.description});
}

class Education {
  final String institute;
  final String degree;
  final String duration;

  Education({required this.institute, required this.degree, required this.duration});
} 