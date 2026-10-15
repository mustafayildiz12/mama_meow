import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_compute.dart';
import 'package:mama_meow/service/gpt_service/medicine_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:mama_meow/utils/pdf/report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MedicineReportPdfBuilder {
  static const PdfColor _accent = PdfColor(0.7098, 0.8863, 0.8392); // b5e2d6

  static Future<Uint8List> build({
    required PdfPageFormat format,
    required ReportPeriod mode,
    required String rangeLabel,
    required List<MedicineModel> medicines,
    MedicineAiInsight? ai,
    MedicineReportComputed?
    computed, // opsiyonel: hazırsa tekrar hesaplamayalım
  }) async {
    final t = await ReportPdfTheme.load(accent: _accent);
    final c = computed ?? MedicineReportComputed.fromMedicines(medicines);

    // Kronolojik (kullanıcının seçtiği saate göre)
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [...medicines]
      ..sort((a, b) => (a.eventAt ?? epoch).compareTo(b.eventAt ?? epoch));

    return buildReportPdf(
      format: format,
      theme: t,
      build: (context) => [
        pdfHeader(
          t,
          title: reportTitle(mode, 'Medicine'),
          subtitle: rangeLabel,
        ),
        pw.SizedBox(height: 12),
        pdfSummaryCards(t, [
          ('Total', '${c.totalCount}'),
          ('Unique', '${c.uniqueMedicineCount}'),
          ('Last Time', c.lastTimeLabel),
        ]),
        if (ai != null) ...[
          pw.SizedBox(height: 14),
          pdfAiBlock(
            t,
            ai,
            fallbackTitle: 'AI Medicine Analysis',
            fallbackDisclaimer:
                'Not medical advice. Confirm any medication concerns with your pediatrician or pharmacist.',
          ),
        ],
        pw.SizedBox(height: 18),
        pdfSectionTitle(t, 'Medicines'),
        pw.SizedBox(height: 8),
        pdfTable(
          t,
          headers: const ['Date', 'Time', 'Medicine', 'Amount'],
          rows: [
            for (final m in sorted)
              [
                fmtPdfDate(m.eventAt),
                medicineDisplayTime(m),
                m.medicineName,
                '${fmtNumber(m.amount)} ${m.amountType}'.trim(),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pdfGeneratedAt(t),
      ],
    );
  }
}
