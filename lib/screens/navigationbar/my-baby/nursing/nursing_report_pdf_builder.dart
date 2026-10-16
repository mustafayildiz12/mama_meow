import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/gpt_service/nursing_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NursingReportPdfBuilder {
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<NursingModel> nursings,
    NursingAiInsight? ai,
  }) async {
    final t = await ReportPdfTheme.load();

    // Kronolojik (kullanıcının seçtiği saate göre)
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [...nursings]
      ..sort((a, b) => (a.eventAt ?? epoch).compareTo(b.eventAt ?? epoch));

    final totalDuration = nursings.fold<int>(0, (sum, n) => sum + n.duration);
    // Süresiz kayıtlar (ör. biberon) ortalamayı düşürmesin.
    final timed = nursings.where((n) => n.duration > 0).length;
    final avgDuration = timed == 0 ? 0 : (totalDuration / timed).round();
    var lastTime = '-';
    DateTime? latest;
    for (final n in nursings) {
      final at = n.eventAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
        lastTime = n.startTime;
      }
    }

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(t, title: reportTitle(mode, 'Nursing'), subtitle: rangeLabel),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total', fmtDurationMinutes(totalDuration)),
          ('Sessions', '${nursings.length}'),
          ('Avg', fmtDurationMinutes(avgDuration)),
          ('Last', lastTime),
        ]),
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(t, ai, fallbackTitle: 'AI Nursing Analysis'),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Nursing Sessions'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const [
            'Date',
            'Time',
            'Duration',
            'Side',
            'Feeding',
            'Milk Type',
            'Amount',
          ],
          rows: [
            for (final n in sorted)
              [
                fmtPdfDate(n.eventAt),
                n.startTime,
                fmtDurationMinutes(n.duration),
                n.side.trim().isEmpty ? '-' : n.side,
                n.feedingType,
                n.milkType ?? '-',
                '${fmtNumber(n.amount)} ${n.amountType}'.trim(),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
