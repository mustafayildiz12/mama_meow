import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/add_medicine_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_compute.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_charts.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/medicine_ai_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef MedicineReportMode = ReportPeriod;

class MedicineReportPage extends StatefulWidget {
  const MedicineReportPage({super.key});
  @override
  State<MedicineReportPage> createState() => _MedicineReportPageState();
}

class _MedicineReportPageState extends State<MedicineReportPage>
    with
        ReportPageMixin<
          MedicineReportPage,
          MedicineModel,
          MedicineReportComputed
        > {
  @override
  void initState() {
    super.initState();
    initReport('medicine_report_page');
  }

  @override
  Future<List<MedicineModel>> fetchFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return medicineService.todayMedicines();
      case ReportPeriod.week:
        return medicineService.weekMedicines();
      case ReportPeriod.month:
        return medicineService.monthMedicines();
    }
  }

  @override
  MedicineReportComputed computeReport(List<MedicineModel> items) =>
      MedicineReportComputed.fromMedicines(items);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'medicine',
    emptyMessage: 'No medicine data to export.',
    shareText:
        "My baby's medicine report from Coo Care Baby Tracker 🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (medicines, computed, period, label) async {
      final ai = await MedicineAIService().analyze(
        mode: period,
        rangeLabel: label,
        c: computed,
      );
      return MedicineReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        medicines: medicines,
        computed: computed,
        ai: ai,
      );
    },
  );

  Future<void> _addMedicine() async {
    await showActivitySheet(
      context,
      (_) => AddMedicineBottomSheet(selectedDate: DateTime.now()),
    );
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<MedicineModel>(
      title: "Medicine Reports",
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      empty: CenteredMessage(
        emoji: '💊',
        title: 'No record found',
        subtitle:
            'You will see it here when you add medication for this period.',
        actionLabel: 'Add medicine',
        onAction: _addMedicine,
      ),
      builder: (context, medicines) => _buildReportBody(computedFor(medicines)),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili tarih aralığı) ----
  Widget _buildReportBody(MedicineReportComputed computed) {
    final amountTypeList = sortedEntries(computed.amountTypeTotals);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ReportHeaderCard(
          title: "Medicine Overview",
          subtitle: rangeLabel,
          stats: [
            ("Total", "${computed.totalCount}"),
            ("Types", "${computed.uniqueMedicineCount}"),
            ("Last time", computed.lastTimeLabel),
          ],
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Distribution by hour",
          subtitle: "When medicines were given",
          child: SizedBox(
            height: 220,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              primaryXAxis: ReportChartStyle.categoryAxis(),
              primaryYAxis: ReportChartStyle.valueAxis(labelFormat: '{value}'),
              tooltipBehavior: ReportChartStyle.tooltip(),
              enableAxisAnimation: true,
              series: [
                ColumnSeries<ChartEntry, String>(
                  dataSource: orderedEntries(computed.distHourCount),
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  dataLabelMapper: (e, _) =>
                      e.value == 0 ? "" : e.value.toString(),
                  dataLabelSettings: ReportChartStyle.barDataLabels,
                  color: AppColors.activeBerry,
                  borderRadius: ReportChartStyle.columnRadius,
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Medicine types",
          subtitle: "Distribution by medicine name",
          child: SizedBox(
            height: 240,
            child: DistributionDoughnut(
              data: sortedEntries(computed.medicineCounts),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (amountTypeList.isNotEmpty) ...[
          ReportSectionCard(
            title: "Amount by type",
            subtitle: "Total amounts by unit type",
            child: SizedBox(
              height: 220,
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                primaryXAxis: ReportChartStyle.categoryAxis(),
                primaryYAxis: ReportChartStyle.valueAxis(),
                tooltipBehavior: ReportChartStyle.tooltip(),
                series: [
                  BarSeries<ChartEntry, String>(
                    dataSource: amountTypeList,
                    xValueMapper: (e, _) => e.label,
                    yValueMapper: (e, _) => e.value,
                    color: AppColors.activeBerry,
                    borderRadius: ReportChartStyle.barRadius,
                    dataLabelSettings: ReportChartStyle.barDataLabels,
                    name: 'Amount',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        ReportSectionCard(
          title: "Sessions",
          subtitle: "Chronological list for $rangeLabel",
          child: Column(
            children: [
              // details kronolojik (gün + saat) sıralı gelir
              for (final d in computed.details)
                _MedicineTile(
                  name: d.name,
                  time: d.time,
                  amount: d.amount,
                  amountType: d.amountType,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ReportTipsCard(
          title: "AI Medicine Tips",
          tips: [
            (
              "⚠️",
              "Always double-check dosage amounts before administering medication",
            ),
            (
              "🌡️",
              "Store all medications in a cool, dry place away from children",
            ),
            (
              "📞",
              "Contact pediatrician if you notice any unusual reactions or side effects",
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicineTile extends StatelessWidget {
  final String name;
  final String time;
  final num amount;
  final String amountType;
  const _MedicineTile({
    required this.name,
    required this.time,
    required this.amount,
    required this.amountType,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const IconSquircle(
              background: AppColors.peachTint,
              size: 40,
              radius: 14,
              child: ActivityIcon(kind: ActivityKind.medicine, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$amount $amountType',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.charcoalSoft,
                    ),
                  ),
                ],
              ),
            ),
            // Saat rozeti: pembe tint zemin, berry ink metin.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pinkTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.berryInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
