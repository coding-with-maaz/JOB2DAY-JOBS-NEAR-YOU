import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/resume_model.dart';
import '../templates/classic_resume_templates.dart';
import '../templates/modern_resume_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../utils/logger.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';

// Design system colors (aligned with JobDetailsPage, ResumeMakerPage, ResumeFormScreen, PreviewDownloadScreen)
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

class TemplateSelectionScreen extends StatefulWidget {
  final int? initialSelected;
  const TemplateSelectionScreen({Key? key, this.initialSelected}) : super(key: key);

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplatePreview {
  final String title;
  final String description;
  final Future<pw.Document> Function() pdfBuilder;
  _TemplatePreview(this.title, this.description, this.pdfBuilder);
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  int? selectedIndex;

  final List<_TemplatePreview> _templates = [
    _TemplatePreview(
      'Classic',
      'Classic, professional layout',
      () async {
        return ResumeTemplates.generateTemplate1(ResumeData.demo());
      },
    ),
    _TemplatePreview(
      'Modern',
      'Modern, sidebar layout',
      () async {
        return ModernResumeTemplate.generate(ResumeData.demo());
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelected;
    _showInterstitialAd();
  }

  Future<void> _showInterstitialAd() async {
    try {
      // Initial attempt with 500ms delay
      await Future.delayed(const Duration(milliseconds: 500));
      Logger.info('TemplateSelectionScreen: Attempting to show interstitial ad for TemplateSelection (Initial)');
      bool success = await InterstitialAdManager.showAdOnPage('TemplateSelection');
      Logger.info('TemplateSelectionScreen: Interstitial ad show result (Initial): $success');

      if (!success) {
        Logger.info('TemplateSelectionScreen: Interstitial ad not shown - may be due to cooldown, disabled, or no ad available');
        // Retry after 2 seconds if the first attempt fails
        await Future.delayed(const Duration(seconds: 2));
        Logger.info('TemplateSelectionScreen: Attempting to show interstitial ad for TemplateSelection (Retry)');
        success = await InterstitialAdManager.showAdOnPage('TemplateSelection');
        Logger.info('TemplateSelectionScreen: Interstitial ad show result (Retry): $success');
        if (!success) {
          Logger.info('TemplateSelectionScreen: Interstitial ad not shown on retry');
        }
      }
    } catch (e) {
      Logger.error('TemplateSelectionScreen: Error showing interstitial ad: $e');
    }
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
            'Select Resume Template',
            style: unifiedHeaderStyle.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Native ad at the top
                  const SizedBox(height: 8),
                  const NativeAdWidget(),
                  const SizedBox(height: 18),
                  Text(
                    'Choose a Template',
                    style: unifiedHeaderStyle.copyWith(
                      fontSize: 22,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final t = _templates[index];
                      return _buildTemplatePreviewCard(index, t);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: selectedIndex != null
                          ? () {
                              Navigator.of(context).pop(selectedIndex);
                            }
                          : null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selectedIndex != null ? 1.0 : 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: selectedIndex != null
                                ? const LinearGradient(
                                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: selectedIndex == null ? Colors.deepPurple.shade100 : null,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              if (selectedIndex != null)
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: unifiedBodyStyle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // bottomNavigationBar: Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     BannerAdWidget(
        //       collapsible: true,
        //       collapsiblePlacement: 'bottom',
        //     ),
        //   ],
        // ),
      ),
    );
  }

  Widget _buildTemplatePreviewCard(int index, _TemplatePreview template) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Color(0xFF6A11CB) : Colors.grey.shade300,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.deepPurple.withOpacity(0.18) : Colors.grey.withOpacity(0.08),
              blurRadius: isSelected ? 18 : 8,
              spreadRadius: isSelected ? 3 : 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.deepPurple.withOpacity(0.08),
            highlightColor: Colors.deepPurple.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FutureBuilder<pw.Document>(
                      future: template.pdfBuilder(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Icon(Icons.error, color: Colors.red);
                        } else if (snapshot.hasData) {
                          return PdfPreview(
                            build: (format) async => snapshot.data!.save(),
                            allowPrinting: false,
                            allowSharing: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                            canDebug: false,
                            maxPageWidth: 180,
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    template.title,
                    style: unifiedBodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Color(0xFF6A11CB) : Colors.black87,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Icon(Icons.check_circle, color: Color(0xFF6A11CB), size: 22),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}