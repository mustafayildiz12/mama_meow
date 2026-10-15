import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/add_medicine_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_compute.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/medicine_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef MedicineReportMode = ReportPeriod;

const _chartColor = Color(0xFF059669);

final _palette = ReportPalette(
  tint: const Color(0xFFb5e2d6),
  badge: const Color(0xFFa8d5ba),
  segmentFill: const Color(0xFFA8E6CF),
  segmentBackground: Colors.white.withValues(alpha: 0.8),
  segmentActiveForeground: Colors.white.withValues(alpha: 0.9),
);

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
      title: "💊  Medicine Reports",
      palette: _palette,
      pdfIconColor: const Color(0xFFA8E6CF),
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
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(width: 0.4),
                axisLine: const AxisLine(width: 0),
                labelFormat: '{value}',
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              enableAxisAnimation: true,
              series: [
                ColumnSeries<ChartEntry, String>(
                  dataSource: orderedEntries(computed.distHourCount),
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  dataLabelMapper: (e, _) =>
                      e.value == 0 ? "" : e.value.toString(),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  color: _chartColor,
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
            child: SfCircularChart(
              backgroundColor: Colors.transparent,
              legend: const Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              series: <CircularSeries<ChartEntry, String>>[
                PieSeries<ChartEntry, String>(
                  dataSource: sortedEntries(computed.medicineCounts),
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  pointColorMapper: (_, _) => _chartColor,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  explode: true,
                  explodeIndex: 0,
                ),
              ],
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
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0.4),
                  axisLine: const AxisLine(width: 0),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  BarSeries<ChartEntry, String>(
                    dataSource: amountTypeList,
                    xValueMapper: (e, _) => e.label,
                    yValueMapper: (e, _) => e.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
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
          leading: "💡",
          badgeColor: Color(0xFFdc2626),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.kLightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: AppColors.kDeepOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$amount $amountType',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.kDeepOrange,
            ),
          ),
        ],
      ),
    );
  }
}
