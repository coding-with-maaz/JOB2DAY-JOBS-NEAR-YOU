import 'package:flutter/material.dart';
import '../models/resume_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart'; // For banner ad
import '../utils/logger.dart'; // For logging ad events
// import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart'; // For interstitial ad

// Design system constants (aligned with JobDetailsPage, JobsPage, ResumeMakerPage)
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
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  elevation: 2,
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

class ResumeFormScreen extends StatefulWidget {
  final int selectedTemplateIndex;
  const ResumeFormScreen({Key? key, required this.selectedTemplateIndex}) : super(key: key);

  @override
  State<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends State<ResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final List<Experience> _experiences = [];
  final List<Education> _education = [];
  final List<String> _skills = [];
  final List<String> _languages = [];
  final _languageController = TextEditingController();

  // Quick Info
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  // For adding experience/education
  final _expCompanyController = TextEditingController();
  final _expRoleController = TextEditingController();
  final _expDurationController = TextEditingController();
  final _expDescController = TextEditingController();
  List<File> _expCertificates = [];

  final _eduInstituteController = TextEditingController();
  final _eduDegreeController = TextEditingController();
  final _eduDurationController = TextEditingController();

  final _skillController = TextEditingController();

  // Profile image
  File? _profileImage;

  // References
  final List<Reference> _references = [];
  final _refNameController = TextEditingController();
  final _refRelationshipController = TextEditingController();
  final _refContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _showInterstitialAd(); // Show interstitial ad on page load
  }

  // Future<void> _showInterstitialAd() async {
  //   try {
  //     // Add a small delay to ensure the page is fully loaded
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     // Show interstitial ad for ResumeFormScreen
  //     Logger.info('ResumeFormScreen: Attempting to show interstitial ad for ResumeForm');
  //     final success = await InterstitialAdManager.showAdOnPage('ResumeForm');
  //     Logger.info('ResumeFormScreen: Interstitial ad show result: $success');

  //     if (!success) {
  //       Logger.info('ResumeFormScreen: Interstitial ad not shown - may be due to cooldown, disabled, or no ad available');
  //     }
  //   } catch (e) {
  //     Logger.error('ResumeFormScreen: Error showing interstitial ad: $e');
  //   }
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _nationalityController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _expCompanyController.dispose();
    _expRoleController.dispose();
    _expDurationController.dispose();
    _expDescController.dispose();
    _eduInstituteController.dispose();
    _eduDegreeController.dispose();
    _eduDurationController.dispose();
    _skillController.dispose();
    _languageController.dispose();
    _refNameController.dispose();
    _refRelationshipController.dispose();
    _refContactController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  Future<void> _pickCertificate() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _expCertificates.add(File(picked.path));
      });
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _expCertificates.removeAt(index);
    });
  }

  void _addExperience() {
    if (_expCompanyController.text.isNotEmpty && _expRoleController.text.isNotEmpty) {
      setState(() {
        _experiences.add(Experience(
          company: _expCompanyController.text,
          role: _expRoleController.text,
          duration: _expDurationController.text,
          description: _expDescController.text,
        ));
        _expCompanyController.clear();
        _expRoleController.clear();
        _expDurationController.clear();
        _expDescController.clear();
        _expCertificates = [];
      });
    }
  }

  void _addEducation() {
    if (_eduInstituteController.text.isNotEmpty && _eduDegreeController.text.isNotEmpty) {
      setState(() {
        _education.add(Education(
          institute: _eduInstituteController.text,
          degree: _eduDegreeController.text,
          duration: _eduDurationController.text,
        ));
        _eduInstituteController.clear();
        _eduDegreeController.clear();
        _eduDurationController.clear();
      });
    }
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _addLanguage() {
    if (_languageController.text.isNotEmpty) {
      setState(() {
        _languages.add(_languageController.text);
        _languageController.clear();
      });
    }
  }

  void _removeLanguage(String language) {
    setState(() {
      _languages.remove(language);
    });
  }

  void _addReference() {
    if (_refNameController.text.isNotEmpty && _refRelationshipController.text.isNotEmpty && _refContactController.text.isNotEmpty) {
      setState(() {
        _references.add(Reference(
          name: _refNameController.text,
          relationship: _refRelationshipController.text,
          contact: _refContactController.text,
        ));
        _refNameController.clear();
        _refRelationshipController.clear();
        _refContactController.clear();
      });
    }
  }

  void _removeReference(int index) {
    setState(() {
      _references.removeAt(index);
    });
  }

  void _autoFillDemo() {
    final demoData = ResumeData.demo();
    _nameController.text = demoData.name ?? '';
    _emailController.text = demoData.email ?? '';
    _phoneController.text = demoData.phone ?? '';
    _addressController.text = demoData.address ?? '';
    _summaryController.text = demoData.summary ?? '';
    _linkedinController.text = demoData.linkedin ?? '';
    _websiteController.text = demoData.website ?? '';
    _nationalityController.text = demoData.nationality ?? '';
    _dobController.text = demoData.dob ?? '';
    _genderController.text = demoData.gender ?? '';
    _maritalStatusController.text = demoData.maritalStatus ?? '';
    _address2Controller.text = demoData.address2 ?? '';
    _cityController.text = demoData.city ?? '';
    _stateController.text = demoData.state ?? '';
    _zipController.text = demoData.zip ?? '';

    _experiences.clear();
    _experiences.addAll(demoData.experiences);

    _education.clear();
    _education.addAll(demoData.education);

    _skills.clear();
    _skills.addAll(demoData.skills);

    _languages.clear();
    _languages.addAll(demoData.languages ?? []);

    _references.clear();
    _references.addAll(demoData.references ?? []);

    setState(() {});
  }

  void _submit() async {
    // Count how many fields are filled (excluding experience/education/skills lists)
    int filled = 0;
    final controllers = [
      _nameController,
      _emailController,
      _phoneController,
      _addressController,
      _summaryController,
      _linkedinController,
      _websiteController,
      _nationalityController,
      _dobController,
      _genderController,
      _maritalStatusController,
      _address2Controller,
      _cityController,
      _stateController,
      _zipController,
    ];
    for (final c in controllers) {
      if (c.text.trim().isNotEmpty) filled++;
    }
    if (filled + _experiences.length + _education.length + _skills.length + _languages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill at least two fields to proceed.'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final data = ResumeData(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      summary: _summaryController.text,
      experiences: _experiences,
      education: _education,
      skills: _skills,
      languages: _languages,
      linkedin: _linkedinController.text,
      website: _websiteController.text,
      nationality: _nationalityController.text,
      dob: _dobController.text,
      gender: _genderController.text,
      maritalStatus: _maritalStatusController.text,
      address2: _address2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      zip: _zipController.text,
      references: _references,
    );
    Uint8List? profileImageBytes;
    if (_profileImage != null) {
      profileImageBytes = await _profileImage!.readAsBytes();
    }
    Navigator.of(context).pop({
      'resumeData': data,
      'profileImageBytes': profileImageBytes,
    });
  }

  Widget _whiteButton({required VoidCallback? onPressed, required Widget child}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: unifiedButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        foregroundColor: WidgetStateProperty.all(primaryColor),
        side: WidgetStateProperty.all(const BorderSide(color: primaryColor, width: 2)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC), Color(0xFF6D5BFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Resume Details',
            style: unifiedHeaderStyle.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.10),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Auto-Fill Demo Button
                    ElevatedButton(
                      onPressed: _autoFillDemo,
                      style: unifiedButtonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(primaryColor),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                      ),
                      child: Text(
                        'Auto-Fill Demo Data',
                        style: unifiedBodyStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Profile Image
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: primaryColor,
                              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person, color: Colors.white, size: 48)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Row(
                              children: [
                                _whiteButton(
                                  onPressed: _pickProfileImage,
                                  child: const Icon(Icons.camera_alt, size: 20),
                                ),
                                if (_profileImage != null)
                                  const SizedBox(width: 6),
                                if (_profileImage != null)
                                  _whiteButton(
                                    onPressed: _removeProfileImage,
                                    child: const Icon(Icons.close, size: 20),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Personal Information',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 22,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_nameController, 'Full Name'),
                    const SizedBox(height: 12),
                    _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, 'Phone', keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(_addressController, 'Address'),
                    const SizedBox(height: 12),
                    _buildTextField(_summaryController, 'Summary', maxLines: 3),
                    const SizedBox(height: 28),
                    // Quick Info
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Info',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: Color(0xFF2575FC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_linkedinController, 'LinkedIn'),
                    const SizedBox(height: 8),
                    _buildTextField(_websiteController, 'Website'),
                    const SizedBox(height: 8),
                    _buildTextField(_nationalityController, 'Nationality'),
                    const SizedBox(height: 8),
                    _buildTextField(_dobController, 'Date of Birth'),
                    const SizedBox(height: 8),
                    _buildTextField(_genderController, 'Gender'),
                    const SizedBox(height: 8),
                    _buildTextField(_maritalStatusController, 'Marital Status'),
                    const SizedBox(height: 8),
                    _buildTextField(_address2Controller, 'Address 2'),
                    const SizedBox(height: 8),
                    _buildTextField(_cityController, 'City'),
                    const SizedBox(height: 8),
                    _buildTextField(_stateController, 'State'),
                    const SizedBox(height: 8),
                    _buildTextField(_zipController, 'Zip Code'),
                    const SizedBox(height: 28),
                    // Experience
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'Experience',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: Color(0xFF2575FC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_expCompanyController, 'Company'),
                    const SizedBox(height: 8),
                    _buildTextField(_expRoleController, 'Role'),
                    const SizedBox(height: 8),
                    _buildTextField(_expDurationController, 'Duration'),
                    const SizedBox(height: 8),
                    _buildTextField(_expDescController, 'Description', maxLines: 2),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _whiteButton(
                          onPressed: _pickCertificate,
                          child: Row(
                            children: const [Icon(Icons.file_present, size: 18), SizedBox(width: 4), Text('Add Certificate(s)')],
                          ),
                        ),
                        if (_expCertificates.isNotEmpty)
                          const SizedBox(width: 8),
                        if (_expCertificates.isNotEmpty)
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _expCertificates.length,
                                separatorBuilder: (context, i) => const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final file = _expCertificates[i];
                                  return Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          file,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _removeCertificate(i),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _whiteButton(
                          onPressed: _addExperience,
                          child: Row(
                            children: const [Icon(Icons.add), SizedBox(width: 4), Text('Add Experience')],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('(${_experiences.length})', style: unifiedBodyStyle),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _experiences.length,
                      itemBuilder: (context, i) {
                        final e = _experiences[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              '${e.role} at ${e.company}',
                              style: unifiedBodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${e.duration}\n${e.description}',
                              style: unifiedBodyStyle.copyWith(color: textSecondaryColor),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _experiences.removeAt(i);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'Education',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: Color(0xFF2575FC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_eduInstituteController, 'Institute'),
                    const SizedBox(height: 8),
                    _buildTextField(_eduDegreeController, 'Degree'),
                    const SizedBox(height: 8),
                    _buildTextField(_eduDurationController, 'Duration'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _whiteButton(
                          onPressed: _addEducation,
                          child: Row(
                            children: const [Icon(Icons.add), SizedBox(width: 4), Text('Add Education')],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('(${_education.length})', style: unifiedBodyStyle),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _education.length,
                      itemBuilder: (context, i) {
                        final e = _education[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              '${e.degree} at ${e.institute}',
                              style: unifiedBodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              e.duration,
                              style: unifiedBodyStyle.copyWith(color: textSecondaryColor),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _education.removeAt(i);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'Skills',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_skillController, 'Skill')),
                        const SizedBox(width: 8),
                        _whiteButton(
                          onPressed: _addSkill,
                          child: Row(
                            children: const [Icon(Icons.add), SizedBox(width: 4), Text('Add Skill')],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _skills.map((s) => Chip(
                        label: Text(s, style: const TextStyle(color: Colors.white)),
                        backgroundColor: primaryColor,
                        deleteIconColor: Colors.white,
                        onDeleted: () {
                          setState(() {
                            _skills.remove(s);
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 28),
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'Languages',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_languageController, 'Language')),
                        const SizedBox(width: 8),
                        _whiteButton(
                          onPressed: _addLanguage,
                          child: Row(
                            children: const [Icon(Icons.add), SizedBox(width: 4), Text('Add Language')],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _languages.map((l) => Chip(
                        label: Text(l, style: const TextStyle(color: Colors.white)),
                        backgroundColor: primaryColor,
                        deleteIconColor: Colors.white,
                        onDeleted: () => _removeLanguage(l),
                      )).toList(),
                    ),
                    // References Section
                    const SizedBox(height: 28),
                    const Divider(height: 1, thickness: 1.2),
                    const SizedBox(height: 24),
                    Text(
                      'References',
                      style: unifiedHeaderStyle.copyWith(
                        fontSize: 20,
                        color: Color(0xFF2575FC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_refNameController, 'Name')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_refRelationshipController, 'Relationship')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_refContactController, 'Contact')),
                        const SizedBox(width: 8),
                        _whiteButton(
                          onPressed: _addReference,
                          child: Row(
                            children: const [Icon(Icons.add), SizedBox(width: 4), Text('Add')],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _references.length,
                      itemBuilder: (context, i) {
                        final r = _references[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              r.name,
                              style: unifiedBodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${r.relationship}\n${r.contact}',
                              style: unifiedBodyStyle.copyWith(color: textSecondaryColor),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _removeReference(i),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _whiteButton(
                        onPressed: _submit,
                        child: Text(
                          'Continue',
                          style: unifiedBodyStyle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: unifiedInputDecoration.copyWith(
        labelText: label,
        fillColor: const Color(0xFFF7F7FA),
      ),
      style: unifiedBodyStyle,
    );
  }
}