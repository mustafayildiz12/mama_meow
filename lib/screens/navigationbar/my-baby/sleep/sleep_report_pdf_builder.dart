import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mama_meow/models/activities/sleep_model.dart';
import 'sleep_report_page.dart'; // ReportMode

class SleepReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportMode mode,
    required String rangeLabel,
    required List<SleepModel> sleeps,
  }) async {
    final doc = pw.Document();

    var regularFontData = await rootBundle.load(
      "assets/fonts/nunito/Nunito-Regular.ttf",
    );
    final regularTtf = pw.Font.ttf(regularFontData);
    var semiboldTtfData = await rootBundle.load(
      "assets/fonts/nunito/Nunito-SemiBold.ttf",
    );
    final semiboldTtf = pw.Font.ttf(semiboldTtfData);

    final totalMinutes = _totalMinutes(sleeps);
    final avgMinutes = sleeps.isEmpty
        ? 0
        : (totalMinutes / sleeps.length).round();
    final lastEnd = _latestEndTime(sleeps); // "HH:mm" ya da "-"

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _header(mode, rangeLabel, regularTtf, semiboldTtf),
          pw.SizedBox(height: 12),
          _summaryCards(
            regularTtf: regularTtf,
            semiBold: semiboldTtf,
            total: _fmtMin(totalMinutes),
            count: sleeps.length,
            avg: _fmtMin(avgMinutes),
            lastEnd: lastEnd,
          ),
          pw.SizedBox(height: 18),

          pw.Text(
            "Sleeps",
            style: pw.TextStyle(
              font: semiboldTtf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _table(sleeps),
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

    final bytes = await doc.save(); // List<int>
    return Uint8List.fromList(bytes);
  }

  static pw.Widget _header(
    ReportMode mode,
    String rangeLabel,
    pw.Font regularTtf,
    pw.Font semiBold,
  ) {
    final title = switch (mode) {
      ReportMode.today => "Daily Sleep Report",
      ReportMode.week => "Weekly Sleep Report",
      ReportMode.month => "Monthly Sleep Report",
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
        color: PdfColors.grey100,
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

  static pw.Widget _summaryCards({
    required String total,
    required int count,
    required String avg,
    required String lastEnd,
    required pw.Font regularTtf,
    required pw.Font semiBold,
  }) {
    pw.Widget card(String t, String v) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
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
        card("Sleeps", "$count"),
        pw.SizedBox(width: 10),
        card("Avg", avg),
        pw.SizedBox(width: 10),
        card("Last End", lastEnd),
      ],
    );
  }

  static pw.Widget _table(List<SleepModel> sleeps) {
    // tablo başlıkları
    final headers = <String>[
      "Date",
      "Start",
      "End",
      "Duration",
      "How",
      "Start Mood",
      "End Mood",
    ];

    // satırlar
    final rows = sleeps.map((s) {
      final dur = _calcDurationMinutes(s);
      return <String>[
        _safeDate(s.sleepDate),
        s.startTime,
        s.endTime,
        _fmtMin(dur),
        (s.howItHappened ?? "-"),
        (s.startOfSleep ?? "-"),
        (s.endOfSleep ?? "-"),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
      },
    );
  }

  // ---- helpers (PDF tarafı) ----

  static int _totalMinutes(List<SleepModel> sleeps) {
    var sum = 0;
    for (final s in sleeps) {
      sum += _calcDurationMinutes(s);
    }
    return sum;
  }

  static String _latestEndTime(List<SleepModel> sleeps) {
    DateTime? latest;
    for (final s in sleeps) {
      final end = _combineDateAndTime(s.sleepDate, s.endTime);
      final start = _combineDateAndTime(s.sleepDate, s.startTime);
      if (end == null || start == null) continue;

      var endFixed = end;
      if (endFixed.isBefore(start)) {
        endFixed = endFixed.add(const Duration(days: 1));
      }
      if (latest == null || endFixed.isAfter(latest)) latest = endFixed;
    }
    return latest == null ? "-" : DateFormat('HH:mm').format(latest);
  }

  static DateTime? _combineDateAndTime(String dateStr, String hhmm) {
    try {
      final dateOnly = dateStr.split(' ').first; // "yyyy-MM-dd"
      final ymd = DateFormat('yyyy-MM-dd').parseStrict(dateOnly);
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return DateTime(ymd.year, ymd.month, ymd.day, h, m);
    } catch (_) {
      return null;
    }
  }

  static int _calcDurationMinutes(SleepModel s) {
    final start = _combineDateAndTime(s.sleepDate, s.startTime);
    var end = _combineDateAndTime(s.sleepDate, s.endTime);
    if (start == null || end == null) return 0;

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1)); // geceyi aşarsa
    }
    return end.difference(start).inMinutes;
  }

  static String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }

  static String _safeDate(String raw) {
    // sleepDate "yyyy-MM-dd ..." gelebiliyor
    final dateOnly = raw.split(' ').first;
    return dateOnly;
  }
}
