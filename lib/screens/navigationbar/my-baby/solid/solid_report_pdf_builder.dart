import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_compute.dart';
import 'package:mama_meow/service/gpt_service/solid_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SolidReportPdfBuilder {
  static const PdfColor _accent = PdfColor(0.91, 0.96, 0.94); // soft mint
  static const PdfColor _scaffold = PdfColor(0.973, 0.980, 0.988);

  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<SolidModel> solids,
    required SolidReportComputed computed,
    SolidAiInsight? ai,
  }) async {
    final t = await ReportPdfTheme.load(accent: _accent, scaffold: _scaffold);

    // Kronolojik (kullanıcının seçtiği yeme saatine göre)
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [...solids]
      ..sort((a, b) => (a.eventAt ?? epoch).compareTo(b.eventAt ?? epoch));

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(t, title: reportTitle(mode, 'Food'), subtitle: rangeLabel),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total Amount', fmtNumber(computed.totalAmount)),
          ('Meals', '${computed.mealCount}'),
          ('Last Eat', computed.lastEatTime),
        ]),
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(
            t,
            ai,
            fallbackTitle: 'AI Food Analysis',
            fallbackDisclaimer:
                'Not medical advice. Consult a healthcare professional if you have concerns.',
          ),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Foods'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const ['Date', 'Time', 'Food', 'Amount', 'Reaction'],
          rows: [
            for (final s in sorted)
              [
                fmtPdfDate(s.eventAt),
                s.eatTime,
                s.solidName,
                // "1,5" → "1.5"; sayı değilse metin olduğu gibi
                s.amountValue != null
                    ? fmtNumber(s.amountValue!)
                    : s.solidAmount,
                s.reactions == null ? '-' : reactionToText(s.reactions!),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
