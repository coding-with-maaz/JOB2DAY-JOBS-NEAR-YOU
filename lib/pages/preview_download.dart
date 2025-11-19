import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../models/resume_model.dart';
import '../templates/classic_resume_templates.dart';
import '../templates/modern_resume_template.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart'; // For banner ad
import '../widgets/google_ads/native_ads/native_ad_widget.dart'; // For native ad
import '../widgets/google_ads/rewarded_ads/rewarded_ad_manager.dart'; // For rewarded ad
import '../utils/logger.dart'; // For logging ad events
// import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart'; // For interstitial ad

// Design system constants (aligned with JobDetailsPage, JobsPage, ResumeMakerPage, ResumeFormScreen)
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

class PreviewDownloadScreen extends StatefulWidget {
  final ResumeData resumeData;
  final int selectedTemplateIndex;
  final Uint8List? profileImageBytes;

  const PreviewDownloadScreen({
    Key? key,
    required this.resumeData,
    required this.selectedTemplateIndex,
    this.profileImageBytes,
  }) : super(key: key);

  @override
  State<PreviewDownloadScreen> createState() => _PreviewDownloadScreenState();
}

class _PreviewDownloadScreenState extends State<PreviewDownloadScreen> {
  Timer? _rewardedAdTimer;
  
  @override
  void initState() {
    super.initState();
    // _showInterstitialAd(); // Show interstitial ad on page load
    _startRewardedAdTimer();
  }

  // Future<void> _showInterstitialAd() async {
  //   try {
  //     // Add a small delay to ensure the page is fully loaded
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     // Show interstitial ad for PreviewDownloadScreen
  //     Logger.info('PreviewDownloadScreen: Attempting to show interstitial ad for PreviewDownload');
  //     final success = await InterstitialAdManager.showAdOnPage('PreviewDownload');
  //     Logger.info('PreviewDownloadScreen: Interstitial ad show result: $success');

  //     if (!success) {
  //       Logger.info('PreviewDownloadScreen: Interstitial ad not shown - may be due to cooldown, disabled, or no ad available');
  //     }
  //   } catch (e) {
  //     Logger.error('PreviewDownloadScreen: Error showing interstitial ad: $e');
  //   }
  // }

  void _startRewardedAdTimer() {
    // Show rewarded ad after 2 minutes (120 seconds)
    _rewardedAdTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) {
        _showTimedRewardedAd();
      }
    });
  }

  void _showTimedRewardedAd() {
    RewardedAdManager.showAd(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 You earned ${reward.amount} ${reward.type} for spending time on your resume!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      onAdClosed: () {
        Logger.info('PreviewDownloadScreen: Timed rewarded ad closed');
      },
      onAdFailedToShow: () {
        Logger.info('PreviewDownloadScreen: Timed rewarded ad failed to show');
      },
    );
  }

  @override
  void dispose() {
    _rewardedAdTimer?.cancel();
    super.dispose();
  }

  String get templateName {
    switch (widget.selectedTemplateIndex) {
      case 0:
        return 'Classic';
      case 1:
        return 'Modern';
      default:
        return 'Classic';
    }
  }

  pw.Document _generatePdf() {
    pw.MemoryImage? profileImage;
    if (widget.profileImageBytes != null) {
      profileImage = pw.MemoryImage(widget.profileImageBytes!);
    }
    switch (widget.selectedTemplateIndex) {
      case 0:
        return ResumeTemplates.generateTemplate1(widget.resumeData, profileImage: profileImage);
      case 1:
        return ModernResumeTemplate.generate(widget.resumeData, profileImage: profileImage);
      default:
        return ResumeTemplates.generateTemplate1(widget.resumeData, profileImage: profileImage);
    }
  }

  Future<void> _savePdfToDevice(BuildContext context, pw.Document pdf) async {
    try {
      final output = await getExternalStorageDirectory();
      final file = File("${output!.path}/resume_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF saved to device!'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      // Show rewarded ad after successful download
      await Future.delayed(const Duration(milliseconds: 500));
      RewardedAdManager.showAd(
        onUserEarnedReward: (ad, reward) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 You earned ${reward.amount} ${reward.type} for downloading your resume!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        onAdClosed: () {
          Logger.info('PreviewDownloadScreen: Download rewarded ad closed');
        },
        onAdFailedToShow: () {
          Logger.info('PreviewDownloadScreen: Download rewarded ad failed to show');
        },
      );
    } catch (e) {
      Logger.error('PreviewDownloadScreen: Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdf = _generatePdf();
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
            'Preview & Download',
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
              constraints: const BoxConstraints(maxWidth: 600),
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
                  // Template name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.style, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              templateName,
                              style: unifiedBodyStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // PDF Preview
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      height: 700,
                      child: PdfPreview(
                        build: (format) => pdf.save(),
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        allowPrinting: true,
                        allowSharing: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, color: primaryColor),
                      label: Text(
                        'Download PDF',
                        style: unifiedBodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 18,
                        ),
                      ),
                      style: unifiedButtonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 18)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        elevation: WidgetStateProperty.all(8),
                        shadowColor: WidgetStateProperty.all(Colors.deepPurple.withOpacity(0.2)),
                      ),
                      onPressed: () async {
                        await _savePdfToDevice(context, pdf);
                      },
                    ),
                  ),
                ],
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
}