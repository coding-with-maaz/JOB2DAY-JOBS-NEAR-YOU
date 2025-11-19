import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume_model.dart';

class ModernResumeTemplate {
  static pw.Document generate(ResumeData data, {pw.MemoryImage? profileImage}) {
    final pdf = pw.Document();
    const accentColor = PdfColors.blueGrey800;
    const sidebarBg = PdfColors.grey200;
    const dividerColor = PdfColors.blueGrey300;
    const textColor = PdfColors.black;
    const lightTextColor = PdfColors.grey600;

    // Sidebar
    pw.Widget buildSidebar([double? sidebarHeight]) {
      return pw.Container(
        width: 180,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: sidebarBg,
          borderRadius: pw.BorderRadius.circular(24),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Contact
            pw.Text('Contact', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Text('Phone:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
            pw.Text(data.phone, style: pw.TextStyle(fontSize: 10, color: textColor)),
            pw.SizedBox(height: 4),
            pw.Text('Email:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
            pw.Text(data.email, style: pw.TextStyle(fontSize: 10, color: textColor)),
            if (data.address?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 4),
              pw.Text('Address:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
              pw.Text(data.address!, style: pw.TextStyle(fontSize: 10, color: textColor)),
            ],
            pw.SizedBox(height: 14),
            pw.Divider(color: dividerColor, thickness: 1),
            // Education
            pw.SizedBox(height: 10),
            pw.Text('Education', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            ...data.education.map((e) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(e.degree, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: textColor)),
                pw.Text(e.institute, style: pw.TextStyle(fontSize: 9, color: lightTextColor)),
                pw.Text(e.duration, style: pw.TextStyle(fontSize: 9, color: lightTextColor)),
                pw.SizedBox(height: 8),
              ],
            )),
            pw.Divider(color: dividerColor, thickness: 1),
            // Skills
            pw.SizedBox(height: 10),
            pw.Text('Skills', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: data.skills.map((s) =>
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(s, style: pw.TextStyle(color: textColor, fontSize: 10)),
                )
              ).toList(),
            ),
            pw.Divider(color: dividerColor, thickness: 1),
            // Languages
            pw.SizedBox(height: 10),
            pw.Text('Language', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: (data.languages ?? ['English']).map((l) =>
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(l, style: pw.TextStyle(color: textColor, fontSize: 10)),
                )
              ).toList(),
            ),
          ],
        ),
      );
    }

    // Header
    pw.Widget buildHeader() {
      return pw.Container(
        height: 110,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            // Header background (centered rounded rectangle)
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Container(
                height: 80,
                width: 390,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(18),
                ),
                padding: const pw.EdgeInsets.only(left: 70, right: 30),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Spacer for image overlap
                    pw.SizedBox(width: 40),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 40),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                data.name,
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Sales Representative',
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  color: lightTextColor,
                                  fontWeight: pw.FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Profile image (overlapping left edge)
            if (profileImage != null)
              pw.Positioned(
                left: 45,
                top: 10,
                child: pw.Container(
                  width: 90,
                  height: 90,
                  margin: const pw.EdgeInsets.only(right: 16),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Section header
    pw.Widget sectionHeader(String title) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Row(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accentColor, letterSpacing: 0.5),
            ),
            pw.Expanded(
              child: pw.Divider(color: dividerColor, thickness: 1, indent: 10),
            ),
          ],
        ),
      );
    }

    // Experience section
    List<pw.Widget> buildExperienceWidgets() {
      return data.experiences.isNotEmpty
          ? data.experiences.map((e) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${e.role}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                    pw.Text('${e.company}', style: pw.TextStyle(fontSize: 10, color: textColor)),
                    pw.Text(e.duration, style: pw.TextStyle(fontSize: 9, color: lightTextColor)),
                    if (e.description.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Bullet(text: e.description, style: pw.TextStyle(fontSize: 9, color: textColor)),
                    ],
                  ],
                ),
              );
            }).toList()
          : [pw.Text('No experience added.', style: pw.TextStyle(fontSize: 10, color: lightTextColor))];
    }

    // References section
    List<pw.Widget> buildReferenceWidgets() {
      if (data.references != null && data.references!.isNotEmpty) {
        final refs = data.references!;
        return [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: refs.take(2).map((ref) => pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: dividerColor, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(ref.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                    pw.Text(ref.relationship, style: pw.TextStyle(fontSize: 9, color: textColor)),
                    pw.Text('Phone: ${ref.contact}', style: pw.TextStyle(fontSize: 9, color: lightTextColor)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ];
      } else {
        return [pw.Text('No references added.', style: pw.TextStyle(fontSize: 10, color: lightTextColor, fontStyle: pw.FontStyle.italic))];
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          // Calculate sidebar height to match main content
          final mainContent = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              sectionHeader('About Me'),
              pw.Text(
                data.summary ?? 'I am a Sales Representative who is a professional who initiates and manages relationships with customers. They serve as their point of contact and lead from initial outreach through the making of the final purchase by them or someone in their household.',
                style: pw.TextStyle(fontSize: 10, height: 1.3, color: textColor),
              ),
              sectionHeader('Work Experience'),
              ...buildExperienceWidgets(),
              sectionHeader('References'),
              ...buildReferenceWidgets(),
            ],
          );
          final header = buildHeader();
          // Estimate sidebar height: header + main content + spacing
          final sidebarHeight = 90.0 + 18.0 + 600.0; // Adjust 600.0 as needed for your content
          return [
            header,
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 0),
                // Sidebar starts just below the header background
                pw.Column(
                  children: [
                    pw.SizedBox(height: 10),
                    buildSidebar(null), // Pass null or remove height param, let sidebar size to content
                  ],
                ),
                pw.SizedBox(width: 28),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(top: 8, left: 24, right: 24),
                    child: mainContent,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
    return pdf;
  }
}