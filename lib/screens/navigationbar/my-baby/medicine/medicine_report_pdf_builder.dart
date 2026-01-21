import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_compute.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_page.dart';
import 'package:mama_meow/service/gpt_service/medicine_ai_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MedicineReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required MedicineReportMode mode,
    required String rangeLabel,
    required List<MedicineModel> medicines,
    MedicineAiInsight? ai,
    MedicineReportComputed?
    computed, // opsiyonel: hazırsa tekrar hesaplamayalım
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

    final c = computed ?? _compute(medicines);

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
            unique: "${c.uniqueMedicineCount}",
            lastTime: c.lastTimeLabel,
            gradient: gradient,
          ),
          if (ai != null) ...[
            pw.SizedBox(height: 14),
            _aiBlock(ai, regularTtf, semiboldTtf, scaffoldColor),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            "Medicines",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(medicines, cardColor, scaffoldColor),
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

  // ---- AI Block (Sleep’teki ile aynı) ----
  static pw.Widget _aiBlock(
    MedicineAiInsight ai,
    pw.Font regularTtf,
    pw.Font semiBold,
    PdfColor scaffoldColor,
  ) {
    final title = ai.aiTitle.trim().isNotEmpty
        ? ai.aiTitle.trim()
        : "AI Medicine Analysis";

    final summary = ai.aiSummaryBullets
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final patterns = ai.patterns.where((e) => e.trim().isNotEmpty).toList();
    final watchOuts = ai.watchOuts.where((e) => e.trim().isNotEmpty).toList();
    final actions = ai.actionPlan.where((e) => e.trim().isNotEmpty).toList();

    final confidence = ai.confidenceNote.trim();
    final disclaimer = ai.disclaimer.trim().isNotEmpty
        ? ai.disclaimer.trim()
        : "Not medical advice. Confirm any medication concerns with your pediatrician or pharmacist.";

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
    MedicineReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
    pw.LinearGradient gradient,
  ) {
    final title = switch (mode) {
      MedicineReportMode.today => "Daily Medicine Report",
      MedicineReportMode.week => "Weekly Medicine Report",
      MedicineReportMode.month => "Monthly Medicine Report",
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
    required String unique,
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
        card("Unique", unique),
        pw.SizedBox(width: 10),
        card("Last Time", lastTime),
      ],
    );
  }

  // ---- Table ----
  static pw.Widget _table(
    List<MedicineModel> medicines,
    PdfColor cardColor,
    PdfColor scaffoldColor,
  ) {
    final headers = <String>["Date", "Time", "Medicine", "Amount"];

    final rows = medicines.map((m) {
      final dt = _tryParseDateTime(m.createdAt);
      final date = dt != null
          ? DateFormat('yyyy-MM-dd').format(dt)
          : m.createdAt.split(' ').first;
      final time = m.startTime.trim().isNotEmpty
          ? m.startTime
          : (dt != null ? DateFormat('HH:mm').format(dt) : "-");

      return <String>[
        date,
        time,
        m.medicineName,
        "${m.amount} ${m.amountType}",
      ];
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

  // ---- Computed (PDF builder içi minimal) ----
  static MedicineReportComputed _compute(List<MedicineModel> medicines) {
    final byHourRaw = <int, int>{};
    final byMedicine = <String, int>{};
    final byAmountType = <String, double>{};
    final details = <MedicineDetail>[];

    String lastTime = '-';
    DateTime? latest;

    int parseHourSafe(MedicineModel m) {
      final h = int.tryParse(m.startTime.split(':').first);
      if (h != null && h >= 0 && h <= 23) return h;
      final dt = _tryParseDateTime(m.createdAt);
      return dt?.hour ?? 0;
    }

    String bestTime(MedicineModel m) {
      final t = m.startTime.trim();
      if (t.isNotEmpty) return t;
      final dt = _tryParseDateTime(m.createdAt);
      return dt != null ? DateFormat('HH:mm').format(dt) : '-';
    }

    String norm(String s) => s.trim().toLowerCase();

    for (final m in medicines) {
      final h = parseHourSafe(m);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

      final nameKey = norm(m.medicineName);
      byMedicine[nameKey] = (byMedicine[nameKey] ?? 0) + 1;

      byAmountType[m.amountType] =
          (byAmountType[m.amountType] ?? 0) + m.amount.toDouble();

      details.add(
        MedicineDetail(
          name: m.medicineName,
          time: bestTime(m),
          amount: m.amount,
          amountType: m.amountType,
          createdAt: m.createdAt,
        ),
      );

      final ct = _tryParseDateTime(m.createdAt);
      if (ct != null && (latest == null || ct.isAfter(latest))) {
        latest = ct;
        lastTime = bestTime(m);
      }
    }

    details.sort((a, b) {
      final at = _parseTime(a.time);
      final bt = _parseTime(b.time);
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });

    final distHourCount = <String, int>{};
    for (int h = 0; h < 24; h++) {
      distHourCount[h.toString().padLeft(2, '0')] = byHourRaw[h] ?? 0;
    }

    return MedicineReportComputed(
      totalCount: medicines.length,
      uniqueMedicineCount: byMedicine.keys.length,
      lastTimeLabel: lastTime,
      distHourCount: distHourCount,
      medicineCounts: byMedicine,
      amountTypeTotals: byAmountType,
      details: details,
    );
  }

  static DateTime? _tryParseDateTime(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseTime(String timeStr) {
    try {
      final p = timeStr.split(':');
      return DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }
}
