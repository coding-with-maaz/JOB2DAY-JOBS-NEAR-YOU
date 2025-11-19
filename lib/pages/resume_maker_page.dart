import 'package:flutter/material.dart';
import 'template_selection.dart';
import 'resume_form.dart';
import 'preview_download.dart';
import '../models/resume_model.dart';
import 'dart:typed_data';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart'; // For banner ad
import '../services/review_service.dart';

// Design system colors (aligned with JobsPage and JobDetailsPage)
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

class ResumeMakerPage extends StatefulWidget {
  const ResumeMakerPage({super.key});

  @override
  State<ResumeMakerPage> createState() => _ResumeMakerPageState();
}

class _ResumeMakerPageState extends State<ResumeMakerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _glowAnim = Tween<double>(begin: 0.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startFlow(BuildContext context) async {
    if (!mounted) return;
    final selectedTemplate = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => const TemplateSelectionScreen()),
    );
    if (selectedTemplate == null || !mounted) return;
    
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeFormScreen(selectedTemplateIndex: selectedTemplate),
      ),
    );
    if (result == null || !mounted) return;
    final resumeData = result['resumeData'] as ResumeData;
    final profileImageBytes = result['profileImageBytes'] as Uint8List?;
    
    // Increment positive action for resume creation
    await ReviewService().incrementPositiveAction();
    
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewDownloadScreen(
          resumeData: resumeData,
          selectedTemplateIndex: selectedTemplate,
          profileImageBytes: profileImageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A11CB),
            Color(0xFF2575FC),
            Color(0xFF6D5BFF),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Resume Maker',
            style: unifiedHeaderStyle.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create a Stunning Resume',
                  style: unifiedHeaderStyle.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a template, fill your info, and export as PDF!',
                  style: unifiedBodyStyle.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: _glowAnim.value,
                            spreadRadius: 1,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: child,
                    );
                  },
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Start Resume Maker',
                        style: unifiedBodyStyle.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: unifiedButtonStyle.copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.deepPurpleAccent),
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 36, vertical: 18)),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                      elevation: WidgetStateProperty.all(8),
                      shadowColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => _startFlow(context),
                  ),
                ),
              ],
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
}