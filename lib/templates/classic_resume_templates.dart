import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume_model.dart';

class ResumeTemplates {
  static pw.Document generateTemplate1(ResumeData data, {pw.MemoryImage? profileImage}) {
    final pdf = pw.Document();

    // Compact quick info with professional styling
    List<pw.Widget> quickInfoWidgets = [];
    void addQuickInfo(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        quickInfoWidgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  '$label:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    addQuickInfo('LinkedIn', data.linkedin);
    addQuickInfo('Website', data.website);
    addQuickInfo('City', data.city);
    addQuickInfo('State', data.state);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            italic: pw.Font.helveticaOblique(),
          ),
        ),
        header: (pw.Context context) => context.pageNumber == 1
            ? pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
              ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (profileImage != null)
                      pw.Center(
                        child: pw.Container(
                            width: 50,
                            height: 50,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                              border: pw.Border.all(color: PdfColors.grey300, width: 2),
                            ),
                          ),
                      ),
                    pw.Center(
                      child: pw.Text(
                                data.name,
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                        textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                    pw.Center(
                      child: pw.Text(
                          "${data.email} | ${data.phone} | ${data.address}",
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                            height: 1.3,
                        ),
                        textAlign: pw.TextAlign.center,
                          ),
                        ),
                        if ([data.city, data.website, data.linkedin, data.state].any((v) => v != null && v?.trim().isNotEmpty == true)) ...[
                          pw.SizedBox(height: 5),
                      pw.Center(
                        child: pw.Text(
                            [
                              if (data.city != null && data.city?.trim().isNotEmpty == true) data.city,
                              if (data.website != null && data.website?.trim().isNotEmpty == true) data.website,
                              if (data.linkedin != null && data.linkedin?.trim().isNotEmpty == true) data.linkedin,
                              if (data.state != null && data.state?.trim().isNotEmpty == true) data.state,
                            ].join(' | '),
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                            textAlign: pw.TextAlign.center,
                        ),
                          ),
                        ],
                      ],
                    ),
              )
            : pw.Container(),
        build: (pw.Context context) => <pw.Widget>[
            pw.SizedBox(height: 12),
            // Professional Summary
            _sectionHeader('Professional Summary'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Text(
                data.summary,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey900,
                  height: 1.3,
                ),
                maxLines: 4,
                overflow: pw.TextOverflow.clip,
              ),
            ),
            pw.SizedBox(height: 12),
            // Professional Experience
            _sectionHeader('Professional Experience'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: data.experiences.isEmpty
                    ? [
                        pw.Text(
                          'No experience added.',
                          style: pw.TextStyle(
                            color: PdfColors.grey500,
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ]
                    : data.experiences.take(2).map((e) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "${e.role} at ${e.company}",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColors.grey900,
                                ),
                              ),
                              pw.Text(
                                e.duration,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                e.description,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey800,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: pw.TextOverflow.clip,
                              ),
                            ],
                          ),
                        )).toList(),
              ),
            ),
            pw.SizedBox(height: 12),
            // Education
            _sectionHeader('Education'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: data.education.isEmpty
                    ? [
                        pw.Text(
                          'No education added.',
                          style: pw.TextStyle(
                            color: PdfColors.grey500,
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ]
                    : data.education.take(2).map((e) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "${e.degree} at ${e.institute}",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColors.grey900,
                                ),
                              ),
                              pw.Text(
                                e.duration,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
              ),
            ),
            pw.SizedBox(height: 12),
            // Skills
            _sectionHeader('Skills'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: data.skills.isEmpty
                  ? pw.Text(
                      'No skills added.',
                      style: pw.TextStyle(
                        color: PdfColors.grey500,
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    )
                  : pw.Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: data.skills.take(8).map((s) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const pw.EdgeInsets.only(bottom: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            ),
                            child: pw.Text(
                              s,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey900,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          )).toList(),
                    ),
            ),
            if (data.languages?.isNotEmpty == true) ...[
              pw.SizedBox(height: 12),
              _sectionHeader('Languages'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                child: pw.Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: data.languages!.map((lang) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Text(
                      lang,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey900,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
            // --- References Section ---
            if (data.references?.isNotEmpty == true) ...[
              pw.SizedBox(height: 18),
              _sectionHeader('References'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                child: pw.Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: data.references!.map((ref) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    // No background color or border
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(ref.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.indigo800)),
                        pw.SizedBox(height: 2),
                        pw.Text(ref.relationship, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                        pw.Text(ref.contact, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
                  )).toList(),
                ),
              ),
            ] else ...[
              pw.SizedBox(height: 18),
              _sectionHeader('References'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                child: pw.Text(
                  'No references added.',
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ], // end of children
        ), // end of MultiPage
    ); // end of pdf.addPage
    return pdf;
  }

  static pw.Widget _sectionHeader(String title, {PdfColor accent = PdfColors.grey900}) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 12),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      // Remove background color for main titles
      // decoration: pw.BoxDecoration(
      //   color: PdfColors.grey200,
      //   borderRadius: pw.BorderRadius.circular(8),
      // ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 1.1,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Divider(
              color: PdfColors.grey400,
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}