import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_compute.dart';
import 'package:mama_meow/service/gpt_service/solid_ai_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'solid_report_page.dart';
import 'package:mama_meow/models/activities/solid_model.dart';

class SolidReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required SolidReportMode mode,
    required String rangeLabel,
    required List<SolidModel> solids,
    required SolidReportComputed computed,
    SolidAiInsight? ai,
  }) async {
    final doc = pw.Document();

    final regularFontData = await rootBundle.load(
      "assets/fonts/nunito/Nunito-Regular.ttf",
    );
    final regularTtf = pw.Font.ttf(regularFontData);

    final semiboldTtfData = await rootBundle.load(
      "assets/fonts/nunito/Nunito-SemiBold.ttf",
    );
    final semiboldTtf = pw.Font.ttf(semiboldTtfData);

    final PdfColor cardColor = PdfColor(0.780, 0.808, 0.918);
    final PdfColor cardWhite = PdfColor(1, 1, 1);
    final PdfColor scaffold = PdfColor(0.973, 0.980, 0.988);

    final gradient = pw.LinearGradient(
      begin: pw.Alignment.topLeft,
      end: pw.Alignment.bottomRight,
      colors: [cardColor, cardWhite],
      stops: const [0.2, 1.0],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _header(mode, rangeLabel, regularTtf, semiboldTtf, gradient),
          pw.SizedBox(height: 12),
          _summaryCards(
            regularTtf: regularTtf,
            semiBold: semiboldTtf,
            totalAmount: computed.totalAmount,
            meals: computed.mealCount,
            lastEatTime: computed.lastEatTime,
            gradient: gradient,
          ),

          if (ai != null) ...[
            pw.SizedBox(height: 14),
            _aiBlock(ai, regularTtf, semiboldTtf, scaffold),
          ],

          pw.SizedBox(height: 18),
          pw.Text(
            "Foods",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(solids, cardColor, scaffold, regularTtf),
          pw.SizedBox(height: 12),
          pw.Text(
            "Generated at: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
              font: regularTtf,
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    return Uint8List.fromList(bytes);
  }

  static pw.Widget _header(
    SolidReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
    pw.LinearGradient gradient,
  ) {
    final title = switch (mode) {
      SolidReportMode.today => "Daily Food Report",
      SolidReportMode.week => "Weekly Food Report",
      SolidReportMode.month => "Monthly Food Report",
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
        gradient: gradient,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: semiBold,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            rangeLabel,
            style: pw.TextStyle(
              font: regularTtf,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards({
    required int totalAmount,
    required int meals,
    required String lastEatTime,
    required pw.Font regularTtf,
    required pw.Font semiBold,
    required pw.LinearGradient gradient,
  }) {
    pw.Widget card(String t, String v) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          gradient: gradient,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(t, style: pw.TextStyle(font: regularTtf, fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.Text(
              v,
              style: pw.TextStyle(
                font: semiBold,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    return pw.Row(
      children: [
        card("Total Amount", "$totalAmount"),
        pw.SizedBox(width: 10),
        card("Meals", "$meals"),
        pw.SizedBox(width: 10),
        card("Last Eat", lastEatTime),
      ],
    );
  }

  // Sleep PDF’deki _aiBlock’un aynısı, sadece SolidAiInsight tipini kullan
  static pw.Widget _aiBlock(
    SolidAiInsight ai,
    pw.Font regularTtf,
    pw.Font semiBold,
    PdfColor scaffoldColor,
  ) {
    final title = ai.aiTitle.trim().isNotEmpty
        ? ai.aiTitle.trim()
        : "AI Food Analysis";

    final summary = ai.aiSummaryBullets
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final patterns = ai.patterns.where((e) => e.trim().isNotEmpty).toList();

    final watchOuts = ai.watchOuts.where((e) => e.trim().isNotEmpty).toList();

    final actions = ai.actionPlan.where((e) => e.trim().isNotEmpty).toList();

    final confidence = ai.confidenceNote.trim();

    final disclaimer = ai.disclaimer.trim().isNotEmpty
        ? ai.disclaimer.trim()
        : "Not medical advice. Consult a healthcare professional if you have concerns.";

    // ---- Sources (maks. 2 tane basıyoruz) ----
    final sourceLines = <String>[];
    for (final s in ai.sources.take(2)) {
      final parts = <String>[
        if (s.title.trim().isNotEmpty) s.title.trim(),
        if (s.publisher.trim().isNotEmpty) s.publisher.trim(),
        if (s.year != null) s.year.toString(),
        if (s.url.trim().isNotEmpty) s.url.trim(),
      ];
      if (parts.isNotEmpty) {
        sourceLines.add(parts.join(' • '));
      }
    }

    // ---- Bullet renderer ----
    pw.Widget bullets(String header, List<String> items) {
      if (items.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(header, style: pw.TextStyle(font: semiBold, fontSize: 11)),
          pw.SizedBox(height: 4),
          for (final it in items.take(6))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "•  ",
                    style: pw.TextStyle(font: regularTtf, fontSize: 10),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      it,
                      style: pw.TextStyle(font: regularTtf, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
        color: scaffoldColor,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ---- Title ----
          pw.Text(
            title,
            style: pw.TextStyle(
              font: semiBold,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          // ---- Sections ----
          if (summary.isNotEmpty) bullets("Summary", summary),
          if (patterns.isNotEmpty) bullets("Patterns", patterns),
          if (watchOuts.isNotEmpty) bullets("Watch outs", watchOuts),
          if (actions.isNotEmpty) bullets("Action plan", actions),

          // ---- Confidence ----
          if (confidence.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              "Confidence",
              style: pw.TextStyle(font: semiBold, fontSize: 11),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              confidence,
              style: pw.TextStyle(
                font: regularTtf,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],

          // ---- Disclaimer ----
          pw.SizedBox(height: 8),
          pw.Text(
            disclaimer,
            style: pw.TextStyle(
              font: regularTtf,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),

          // ---- Sources ----
          if (sourceLines.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              "Sources",
              style: pw.TextStyle(font: semiBold, fontSize: 11),
            ),
            pw.SizedBox(height: 3),
            for (final line in sourceLines)
              pw.Text(
                line,
                style: pw.TextStyle(
                  font: regularTtf,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _table(
    List<SolidModel> solids,
    PdfColor headerColor,
    PdfColor rowColor,
    pw.Font regularTtf,
  ) {
    final headers = <String>["Date", "Time", "Food", "Amount", "Reaction"];

    final rows = solids.map((s) {
      final date = (s.createdAt.isNotEmpty)
          ? (DateTime.tryParse(
                  s.createdAt,
                )?.toIso8601String().split('T').first ??
                s.createdAt.split(' ').first)
          : '-';

      final reaction = s.reactions == null ? '-' : reactionToText(s.reactions!);

      return <String>[date, s.eatTime, s.solidName, s.solidAmount, reaction];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 9, font: regularTtf),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      rowDecoration: pw.BoxDecoration(color: rowColor),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
    );
  }
}
