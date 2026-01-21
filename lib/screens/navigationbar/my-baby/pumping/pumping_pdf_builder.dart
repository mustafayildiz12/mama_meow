import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_page.dart';
import 'package:mama_meow/service/gpt_service/pumping_ai_service.dart';

class PumpingReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required PumpingReportMode mode,
    required String rangeLabel,
    required List<PumpingModel> pumpings,
    required PumpingReportComputed computed,
    PumpingAiInsight? ai,
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

    final totalMinutes = computed.totalMinutes;
    final avgMinutes = computed.avgSessionMinutes;
    final lastTime = computed.lastSessionTime; // computed içinde string

    final PdfColor scaffoldColor = PdfColor(0.9725, 0.9803, 0.9882);
    final PdfColor cardColor = PdfColor(0.964, 0.824, 0.796); // soft peach
    final PdfColor cardWhiteColor = PdfColor(1, 1, 1);

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
            total: _fmtMin(totalMinutes),
            sessions: computed.sessions,
            avg: _fmtMin(avgMinutes),
            lastTime: lastTime,
            gradient: gradient,
          ),
          pw.SizedBox(height: 10),
          _computedCards(
            regularTtf: regularTtf,
            semiBold: semiboldTtf,
            computed: computed,
            gradient: gradient,
          ),

          if (ai != null) ...[
            pw.SizedBox(height: 14),
            _aiBlock(ai, regularTtf, semiboldTtf, scaffoldColor),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            "Pumping Sessions",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(pumpings, cardColor, scaffoldColor, regularTtf),
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

  static pw.Widget _computedCards({
    required pw.Font regularTtf,
    required pw.Font semiBold,
    required PumpingReportComputed computed,
    required pw.LinearGradient gradient,
  }) {
    final totalSide = computed.leftMinutes + computed.rightMinutes;
    final leftPct = totalSide == 0
        ? 0
        : ((computed.leftMinutes * 100) / totalSide).round();
    final rightPct = totalSide == 0
        ? 0
        : ((computed.rightMinutes * 100) / totalSide).round();

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
                  fontSize: 12,
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
        card("Side Split", "$leftPct% L / $rightPct% R"),
        pw.SizedBox(width: 10),
        card("Freq / Day", "${computed.frequencyPerDay}"),
        pw.SizedBox(width: 10),
        card("Longest Gap", "${computed.longestGapHours}h"),
      ],
    );
  }

  static pw.Widget _header(
    PumpingReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
    pw.LinearGradient gradient,
  ) {
    final title = switch (mode) {
      PumpingReportMode.today => "Daily Pumping Report",
      PumpingReportMode.week => "Weekly Pumping Report",
      PumpingReportMode.month => "Monthly Pumping Report",
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
        gradient: gradient,
      ),
      child: pw.Row(
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

  static pw.Widget _summaryCards({
    required String total,
    required int sessions,
    required String avg,
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
        card("Total", total),
        pw.SizedBox(width: 10),
        card("Sessions", "$sessions"),
        pw.SizedBox(width: 10),
        card("Avg", avg),
        pw.SizedBox(width: 10),
        card("Last", lastTime),
      ],
    );
  }

  static pw.Widget _aiBlock(
    PumpingAiInsight ai,
    pw.Font regularTtf,
    pw.Font semiBold,
    PdfColor scaffoldColor,
  ) {
    final title = ai.aiTitle.trim().isNotEmpty
        ? ai.aiTitle.trim()
        : "AI Pumping Analysis";

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
      final line = [
        if (s.title.trim().isNotEmpty) s.title.trim(),
        if (s.publisher.trim().isNotEmpty) s.publisher.trim(),
        if (s.year != null) s.year.toString(),
        if (s.url.trim().isNotEmpty) s.url.trim(),
      ].join(' • ');
      if (line.trim().isNotEmpty) sourceLines.add(line);
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

  static pw.Widget _table(
    List<PumpingModel> items,
    PdfColor headerColor,
    PdfColor rowColor,
    pw.Font regularTtf,
  ) {
    final headers = <String>["Date", "Time", "Side", "Duration"];

    final rows = items.map((p) {
      final dt = DateTime.tryParse(p.createdAt);
      final date = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : "-";
      final time = dt != null ? DateFormat('HH:mm').format(dt) : (p.startTime);
      final side = p.isLeft ? "Left" : "Right";
      final dur = _fmtMin(p.duration);
      return <String>[date, time, side, dur];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        font: regularTtf,
      ),
      cellStyle: pw.TextStyle(fontSize: 9, font: regularTtf),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      rowDecoration: pw.BoxDecoration(color: rowColor),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
    );
  }

  static String _latestTime(List<PumpingModel> items) {
    DateTime? latest;
    for (final p in items) {
      final dt = DateTime.tryParse(p.createdAt);
      if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
    }
    return latest == null ? "-" : DateFormat('HH:mm').format(latest);
  }

  static String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}
