import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_page.dart';
import 'package:mama_meow/service/gpt_service/nursing_ai_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NursingReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required NursingReportMode mode,
    required String rangeLabel,
    required List<NursingModel> nursings,
    NursingAiInsight? ai,
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

    final totalDuration = _totalDurationMinutes(nursings);
    final avgDuration = nursings.isEmpty
        ? 0
        : (totalDuration / nursings.length).round();
    final lastTime = _latestSessionTime(nursings);

    final PdfColor scaffoldColor = PdfColor(0.9725, 0.9803, 0.9882);

    final PdfColor cardColor = PdfColor(
      1.0, // R (ff)
      0.604, // G (9a)
      0.635, // B (a2)
    );

    final PdfColor cardWhiteColor = PdfColor(0.98, 0.98, 0.98);

    final pw.LinearGradient gradient = pw.LinearGradient(
      begin: pw.Alignment.topLeft,
      end: pw.Alignment.bottomRight,
      colors: [cardColor, cardWhiteColor],
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
            totalDuration: _fmtMin(totalDuration),
            sessionCount: nursings.length,
            avgDuration: _fmtMin(avgDuration),
            lastTime: lastTime,
            gradient: gradient,
          ),

          if (ai != null) ...[
            pw.SizedBox(height: 14),
            _aiBlock(ai, regularTtf, semiboldTtf, scaffoldColor),
          ],

          pw.SizedBox(height: 18),
          pw.Text(
            "Nursing Sessions",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(nursings, cardColor, scaffoldColor, regularTtf),
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

  // =========================
  // AI block (NursingAiInsight)
  // =========================
  static pw.Widget _aiBlock(
    NursingAiInsight ai,
    pw.Font regularTtf,
    pw.Font semiBold,
    PdfColor scaffoldColor,
  ) {
    final title = ai.aiTitle.trim().isNotEmpty
        ? ai.aiTitle.trim()
        : "AI Nursing Analysis";

    final summary = ai.aiSummaryBullets
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final patterns = ai.patterns.where((e) => e.trim().isNotEmpty).toList();
    final watchOuts = ai.watchOuts.where((e) => e.trim().isNotEmpty).toList();
    final actions = ai.actionPlan.where((e) => e.trim().isNotEmpty).toList();

    final confidence = ai.confidenceNote.trim();
    final disclaimer = ai.disclaimer.trim().isNotEmpty
        ? ai.disclaimer.trim()
        : "Not medical advice. Consult a healthcare professional for concerns.";

    final sourceLines = <String>[];
    for (final s in ai.sources.take(2)) {
      final parts = <String>[
        if (s.title.trim().isNotEmpty) s.title.trim(),
        if (s.publisher.trim().isNotEmpty) s.publisher.trim(),
        if (s.year != null) s.year.toString(),
        if (s.url.trim().isNotEmpty) s.url.trim(),
      ];
      if (parts.isNotEmpty) sourceLines.add(parts.join(' • '));
    }

    pw.Widget bullets(String head, List<String> items) {
      if (items.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(head, style: pw.TextStyle(font: semiBold, fontSize: 11)),
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
          pw.Text(
            title,
            style: pw.TextStyle(
              font: semiBold,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (summary.isNotEmpty) bullets("Summary", summary),
          if (patterns.isNotEmpty) bullets("Patterns", patterns),
          if (watchOuts.isNotEmpty) bullets("Watch outs", watchOuts),
          if (actions.isNotEmpty) bullets("Action plan", actions),
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
          pw.SizedBox(height: 8),
          pw.Text(
            disclaimer,
            style: pw.TextStyle(
              font: regularTtf,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
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

  // =========================
  // Header
  // =========================
  static pw.Widget _header(
    NursingReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
    pw.LinearGradient gradient,
  ) {
    final title = switch (mode) {
      NursingReportMode.today => "Daily Nursing Report",
      NursingReportMode.week => "Weekly Nursing Report",
      NursingReportMode.month => "Monthly Nursing Report",
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
        gradient: gradient,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
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
          ),
        ],
      ),
    );
  }

  // =========================
  // Summary cards
  // =========================
  static pw.Widget _summaryCards({
    required String totalDuration,
    required int sessionCount,
    required String avgDuration,
    required String lastTime,
    required pw.Font regularTtf,
    required pw.Font semiBold,
    required pw.LinearGradient gradient,
  }) {
    pw.Widget card(String t, String v) {
      return pw.Expanded(
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
              pw.Text(
                t,
                style: pw.TextStyle(
                  font: regularTtf,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
    }

    return pw.Row(
      children: [
        card("Total", totalDuration),
        pw.SizedBox(width: 10),
        card("Sessions", "$sessionCount"),
        pw.SizedBox(width: 10),
        card("Avg", avgDuration),
        pw.SizedBox(width: 10),
        card("Last", lastTime),
      ],
    );
  }

  // =========================
  // Table
  // =========================
  static pw.Widget _table(
    List<NursingModel> nursings,
    PdfColor cardColor,
    PdfColor scaffoldColor,
    pw.Font regularTtf,
  ) {
    final headers = <String>[
      "Date",
      "Time",
      "Duration",
      "Side",
      "Feeding",
      "Milk Type",
      "Amount",
    ];

    final rows = nursings.map((n) {
      final date = _safeDateFromIso(n.createdAt);
      final milk = (n.milkType ?? "-");
      final amountStr = "${_fmtAmount(n.amount)} ${n.amountType}";
      return <String>[
        date,
        n.startTime,
        _fmtMin(n.duration),
        n.side,
        n.feedingType,
        milk,
        amountStr,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 9, font: regularTtf),
      headerDecoration: pw.BoxDecoration(color: cardColor),
      rowDecoration: pw.BoxDecoration(color: scaffoldColor),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
    );
  }

  // =========================
  // Helpers
  // =========================
  static int _totalDurationMinutes(List<NursingModel> nursings) {
    var sum = 0;
    for (final n in nursings) {
      sum += n.duration;
    }
    return sum;
  }

  static String _latestSessionTime(List<NursingModel> nursings) {
    DateTime? latest;
    String last = "-";
    for (final n in nursings) {
      final dt = DateTime.tryParse(n.createdAt);
      if (dt == null) continue;
      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
        last = n.startTime;
      }
    }
    return last;
  }

  static String _safeDateFromIso(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso.split(' ').first;
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }

  static String _fmtAmount(num v) {
    // 5 -> "5", 5.0 -> "5", 5.25 -> "5.25"
    final d = v.toDouble();
    if ((d - d.roundToDouble()).abs() < 0.000001) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }
}
