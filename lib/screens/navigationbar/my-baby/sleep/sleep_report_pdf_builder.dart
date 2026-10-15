import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/gpt_service/sleep_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SleepReportPdfBuilder {
  static const PdfColor _accent = PdfColor(
    0.7803921568627451,
    0.807843137254902,
    0.9176470588235294,
  );

  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<SleepModel> sleeps,
    SleepAiInsight? ai,
  }) async {
    final t = await ReportPdfTheme.load(accent: _accent);

    // Gece yarısında bölünmüş kayıtlar tek uyku sayılır (ortalama yarıya
    // düşmesin); tablo ise kayıtları olduğu gibi listeler.
    final sessions = mergeSleepSessions(sleeps);
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final avgMinutes = sessions.isEmpty
        ? 0
        : (totalMinutes / sessions.length).round();

    DateTime? lastEnd;
    for (final s in sessions) {
      final end = s.end;
      if (end != null && (lastEnd == null || end.isAfter(lastEnd))) {
        lastEnd = end;
      }
    }

    // Tüm kayıtlar, kronolojik (saati okunamayanlar sonda).
    final rows = sessions.expand((s) => s.segments);

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(t, title: reportTitle(mode, 'Sleep'), subtitle: rangeLabel),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total', fmtDurationMinutes(totalMinutes)),
          ('Sleeps', '${sessions.length}'),
          ('Avg', fmtDurationMinutes(avgMinutes)),
          ('Last End', fmtPdfTime(lastEnd)),
        ]),
        // ✅ AI ANALYSIS bloğu (tablonun üstünde)
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(t, ai, fallbackTitle: 'AI Sleep Analysis'),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Sleeps'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const [
            'Date',
            'Start',
            'End',
            'Duration',
            'How',
            'Start Mood',
            'End Mood',
          ],
          rows: [
            for (final s in rows)
              [
                s.sleepDate.trim().split(' ').first,
                s.startTime,
                s.endTime,
                fmtDurationMinutes(s.durationMinutes),
                s.howItHappened ?? '-',
                s.startOfSleep ?? '-',
                s.endOfSleep ?? '-',
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
