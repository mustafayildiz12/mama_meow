import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:mama_meow/service/gpt_service/pumping_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PumpingReportPdfBuilder {
  static const PdfColor _accent = PdfColor(0.964, 0.824, 0.796); // soft peach

  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<PumpingModel> pumpings,
    required PumpingReportComputed computed,
    PumpingAiInsight? ai,
  }) async {
    final t = await ReportPdfTheme.load(accent: _accent);

    final totalSide = computed.leftMinutes + computed.rightMinutes;
    int pct(int part) =>
        totalSide == 0 ? 0 : ((part * 100) / totalSide).round();

    // Kronolojik (kullanıcının seçtiği saate göre)
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [...pumpings]
      ..sort((a, b) => (a.eventAt ?? epoch).compareTo(b.eventAt ?? epoch));

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(t, title: reportTitle(mode, 'Pumping'), subtitle: rangeLabel),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total', fmtDurationMinutes(computed.totalMinutes)),
          ('Sessions', '${computed.sessions}'),
          ('Avg', fmtDurationMinutes(computed.avgSessionMinutes)),
          ('Last', computed.lastSessionTime),
        ]),
        pw.SizedBox(height: 10),
        pdfSummaryCards(t, [
          (
            'Side Split',
            '${pct(computed.leftMinutes)}% L / ${pct(computed.rightMinutes)}% R',
          ),
          ('Freq / Day', '${computed.frequencyPerDay}'),
          ('Longest Gap', '${computed.longestGapHours}h'),
        ], valueFontSize: 12),
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(t, ai, fallbackTitle: 'AI Pumping Analysis'),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Pumping Sessions'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const ['Date', 'Time', 'Side', 'Duration'],
          rows: [
            for (final p in sorted)
              [
                fmtPdfDate(p.eventAt),
                p.eventAt != null ? fmtPdfTime(p.eventAt) : p.startTime,
                p.isLeft ? 'Left' : 'Right',
                fmtDurationMinutes(p.duration),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
