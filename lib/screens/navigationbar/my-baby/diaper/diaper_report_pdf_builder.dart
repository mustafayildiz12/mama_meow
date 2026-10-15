import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/service/gpt_service/diaper_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DiaperReportPdfBuilder {
  static const PdfColor _accent = PdfColor(0.6588, 0.9020, 0.8118); // A8E6CF

  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<DiaperModel> diapers,
    DiaperAiInsight? ai,
    DiaperReportComputed? computed,
  }) async {
    final t = await ReportPdfTheme.load(accent: _accent);
    final c = computed ?? DiaperReportComputed.fromDiapers(diapers);

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(t, title: reportTitle(mode, 'Diaper'), subtitle: rangeLabel),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total', '${c.totalCount}'),
          ('Last', c.lastChangeLabel),
          ('Avg gap', fmtDurationMinutes(c.avgGapMinutes)),
          ('Max gap', fmtDurationMinutes(c.maxGapMinutes)),
        ]),
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(t, ai, fallbackTitle: 'AI Diaper Analysis'),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Diaper changes'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const ['Date', 'Time', 'Type'],
          rows: [
            // Tarih/saat kullanıcının seçtiği saate göre (kaydetme anı değil).
            for (final d in sortDiapersByEventTime(diapers))
              [fmtPdfDate(d.eventAt), diaperDisplayTime(d), d.diaperName],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
