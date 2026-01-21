import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_page.dart';
import 'package:mama_meow/service/gpt_service/diaper_ai_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DiaperReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required DiaperReportMode mode,
    required String rangeLabel,
    required List<DiaperModel> diapers,
    DiaperAiInsight? ai,
    DiaperReportComputed? computed,
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

    final c = computed ?? _compute(diapers);

    final PdfColor scaffoldColor = PdfColor(
      0.9725490196,
      0.9803921569,
      0.9882352941,
    );
    final PdfColor cardColor = PdfColor(
      0.7803921569,
      0.8078431373,
      0.9176470588,
    );
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
            total: "${c.totalCount}",
            last: c.lastChangeLabel,
            avgGap: _fmtMin(c.avgGapMinutes),
            maxGap: _fmtMin(c.maxGapMinutes),
            gradient: gradient,
          ),
          if (ai != null) ...[
            pw.SizedBox(height: 14),
            _aiBlock(ai, regularTtf, semiboldTtf, scaffoldColor),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            "Diaper changes",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(diapers, cardColor, scaffoldColor),
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

  // ---- AI Block ----
  static pw.Widget _aiBlock(
    DiaperAiInsight ai,
    pw.Font regularTtf,
    pw.Font semiBold,
    PdfColor scaffoldColor,
  ) {
    final title = ai.aiTitle.trim().isNotEmpty
        ? ai.aiTitle.trim()
        : "AI Diaper Analysis";

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
      final t = s.title.trim();
      final p = s.publisher.trim();
      final y = (s.year != null) ? s.year.toString() : '';
      final u = s.url.trim();
      final line = [
        if (t.isNotEmpty) t,
        if (p.isNotEmpty) p,
        if (y.isNotEmpty) y,
        if (u.isNotEmpty) u,
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

  // ---- Header ----
  static pw.Widget _header(
    DiaperReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
    pw.LinearGradient gradient,
  ) {
    final title = switch (mode) {
      DiaperReportMode.today => "Daily Diaper Report",
      DiaperReportMode.week => "Weekly Diaper Report",
      DiaperReportMode.month => "Monthly Diaper Report",
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

  // ---- Summary Cards ----
  static pw.Widget _summaryCards({
    required String total,
    required String last,
    required String avgGap,
    required String maxGap,
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
        card("Last", last),
        pw.SizedBox(width: 10),
        card("Avg gap", avgGap),
        pw.SizedBox(width: 10),
        card("Max gap", maxGap),
      ],
    );
  }

  // ---- Table ----
  static pw.Widget _table(
    List<DiaperModel> diapers,
    PdfColor cardColor,
    PdfColor scaffoldColor,
  ) {
    final headers = <String>["Date", "Time", "Type"];

    final sorted = [...diapers]
      ..sort((a, b) {
        final aDt =
            DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDt =
            DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDt.compareTo(bDt);
      });

    final rows = sorted.map((d) {
      final dt = DateTime.tryParse(d.createdAt);
      final date = dt != null
          ? DateFormat('yyyy-MM-dd').format(dt)
          : d.createdAt.split(' ').first;
      final time = dt != null ? DateFormat('HH:mm').format(dt) : d.diaperTime;
      return <String>[date, time, d.diaperName];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: cardColor),
      rowDecoration: pw.BoxDecoration(color: scaffoldColor),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
    );
  }

  // ---- Compute (PDF için minimal) ----
  static DiaperReportComputed _compute(List<DiaperModel> diapers) {
    final sortedByTime = [...diapers]
      ..sort((a, b) {
        final aDt =
            DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDt =
            DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDt.compareTo(bDt);
      });

    String lastChange = '-';
    if (sortedByTime.isNotEmpty) {
      final dt = DateTime.tryParse(sortedByTime.last.createdAt);
      lastChange = dt != null
          ? DateFormat('HH:mm').format(dt)
          : sortedByTime.last.diaperTime;
    }

    final gaps = <int>[];
    for (int i = 1; i < sortedByTime.length; i++) {
      final prev = DateTime.tryParse(sortedByTime[i - 1].createdAt);
      final cur = DateTime.tryParse(sortedByTime[i].createdAt);
      if (prev != null && cur != null) {
        gaps.add(cur.difference(prev).inMinutes.abs());
      }
    }

    final avgGapMin = gaps.isEmpty
        ? 0
        : (gaps.reduce((a, b) => a + b) / gaps.length).round();
    final maxGapMin = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a > b ? a : b);

    final byHourRaw = <int, int>{};
    final byType = <String, int>{};

    int hourFromRecord(DiaperModel d) {
      final dt = DateTime.tryParse(d.createdAt);
      if (dt != null) return dt.hour;
      final hh = int.tryParse(d.diaperTime.split(':').first);
      return (hh == null || hh < 0 || hh > 23) ? 0 : hh;
    }

    String normalize(String s) => s.trim().toLowerCase();

    String typeKey(String name) {
      if (name.contains('pee')) return 'pee';
      if (name.contains('poo') ||
          name.contains('poop') ||
          name.contains('dirty'))
        return 'poop';
      if (name.contains('mixed')) return 'mixed';
      if (name.contains('wet')) return 'wet';
      if (name.contains('dry')) return 'dry';
      return 'other';
    }

    final timeline = <DiaperDetail>[];
    for (final d in sortedByTime) {
      final h = hourFromRecord(d);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

      final type = typeKey(normalize(d.diaperName));
      byType[type] = (byType[type] ?? 0) + 1;

      final dt = DateTime.tryParse(d.createdAt);
      final time = dt != null ? DateFormat('HH:mm').format(dt) : d.diaperTime;
      timeline.add(
        DiaperDetail(time: time, label: d.diaperName, createdAt: d.createdAt),
      );
    }

    final distHourCount = <String, int>{};
    for (int h = 0; h < 24; h++) {
      distHourCount[h.toString().padLeft(2, '0')] = byHourRaw[h] ?? 0;
    }

    return DiaperReportComputed(
      totalCount: diapers.length,
      lastChangeLabel: lastChange,
      avgGapMinutes: avgGapMin,
      maxGapMinutes: maxGapMin,
      distHourCount: distHourCount,
      typeCounts: byType,
      timeline: timeline,
    );
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
