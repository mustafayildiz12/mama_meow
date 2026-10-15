import 'package:flutter/material.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/add_nursing_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/nursing_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef NursingReportMode = ReportPeriod;

const _nursingColor = Color(0xFFff9aa2);

const _palette = ReportPalette(tint: _nursingColor, segmentFill: _nursingColor);

class NursingReportPage extends StatefulWidget {
  const NursingReportPage({super.key});

  @override
  State<NursingReportPage> createState() => _NursingReportPageState();
}

class _NursingReportPageState extends State<NursingReportPage>
    with
        ReportPageMixin<
          NursingReportPage,
          NursingModel,
          NursingReportComputed
        > {
  @override
  void initState() {
    super.initState();
    initReport('nursing_report_page');
  }

  @override
  Future<List<NursingModel>> fetchFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return nursingService.todayNursings();
      case ReportPeriod.week:
        return nursingService.weekNursings();
      case ReportPeriod.month:
        return nursingService.monthNursings();
    }
  }

  @override
  NursingReportComputed computeReport(List<NursingModel> items) =>
      NursingReportComputed.fromNursings(items);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'nursing',
    emptyMessage: 'No nursing data to export.',
    shareText:
        "My baby's nursing report from Coo Care Baby Tracker 🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (nursings, computed, period, label) async {
      final ai = await NursingAIService().analyze(
        mode: period,
        c: computed,
        rangeLabel: label,
      );
      return NursingReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        nursings: nursings,
        ai: ai,
      );
    },
  );

  Future<void> _addNursing() async {
    await showActivitySheet(context, (_) => const AddNursingBottomSheet());
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<NursingModel>(
      title: "🍼  Nursing Reports",
      palette: _palette,
      pdfIconColor: _nursingColor,
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      bottomSafeArea: true,
      empty: CenteredMessage(
        emoji: '🍼',
        title: 'No record found',
        subtitle:
            'You will see it here when you add breastfeeding for this period.',
        actionLabel: 'Add nursing',
        onAction: _addNursing,
      ),
      builder: (context, nursings) =>
          _buildReportBody(nursings, computedFor(nursings)),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili aralığa uygulanır) ----
  Widget _buildReportBody(
    List<NursingModel> nursings,
    NursingReportComputed computed,
  ) {
    // Oturum listesi gerçek olay zamanına göre (gün + saat) sıralı.
    final sessions = [...nursings]
      ..sort(
        (a, b) => reportEventTime(
          a.createdAt,
          a.startTime,
        ).compareTo(reportEventTime(b.createdAt, b.startTime)),
      );
    // Biberon kayıtlarında taraf boş, emzirmede miktar 0 yazılır; grafiklerde
    // bu boş/sıfır dilimler gösterilmez.
    final sideList = sortedEntries(computed.sideCounts)
      ..removeWhere((e) => e.label.isEmpty);
    final milkTypeList = sortedEntries(computed.milkTypeCounts)
      ..removeWhere((e) => e.label.isEmpty);
    final amountTypeList = sortedEntries(computed.amountTypeTotals)
      ..removeWhere((e) => e.value <= 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Distribution by hour",
          subtitle: "When nursing sessions occurred",
          leading: "🤱",
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
                  pointColorMapper: (e, _) =>
                      tierColor(e.value, high: 2, mid: 1, low: 0.5),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Side preference",
          subtitle: "Distribution by nursing side",
          leading: "⏱️",
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
                  dataSource: sideList,
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  pointColorMapper: (e, _) =>
                      tierColor(e.value, high: 20, mid: 10, low: 5),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  explode: true,
                  explodeIndex: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Feeding types",
          subtitle: "Nursing vs bottle feeding",
          leading: "🍼",
          child: _barChart(
            sortedEntries(computed.feedingTypeCounts),
            name: 'Count',
            color: (e, _) => tierColor(e.value, high: 20, mid: 10, low: 5),
          ),
        ),
        const SizedBox(height: 16),

        if (milkTypeList.isNotEmpty) ...[
          ReportSectionCard(
            title: "Milk types",
            subtitle: "Types of milk for bottle feeding",
            leading: "🐄",
            child: _barChart(milkTypeList, name: 'Count'),
          ),
          const SizedBox(height: 16),
        ],

        if (amountTypeList.isNotEmpty) ...[
          ReportSectionCard(
            title: "Amount by type",
            subtitle: "Total amounts by unit type",
            leading: "🥛",
            child: _barChart(
              amountTypeList,
              name: 'Amount',
              color: (_, index) => index == 0 ? Colors.pinkAccent : Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
        ],

        ReportSectionCard(
          title: "Sessions",
          subtitle: "Chronological list for $rangeLabel",
          leading: "⏱️",
          child: Column(children: [for (final n in sessions) _NursingTile(n)]),
        ),
        const SizedBox(height: 16),
        const ReportTipsCard(
          title: "AI Nursing Tips",
          leading: "🤖",
          badgeColor: Colors.pinkAccent,
          tips: [
            (
              "💡",
              "Your feeding intervals are very consistent. This helps establish a great routine!",
            ),
            (
              "🌡️",
              "Your baby seems to love sweet foods. Gradually mix in vegetables for balanced taste",
            ),
            (
              "💪",
              "Consider iron-rich foods like spinach or lentils - perfect age for this nutrition!",
            ),
          ],
        ),
      ],
    );
  }

  Widget _barChart(
    List<ChartEntry> data, {
    required String name,
    Color? Function(ChartEntry e, int index)? color,
  }) {
    return SizedBox(
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
            dataSource: data,
            xValueMapper: (e, _) => e.label,
            yValueMapper: (e, _) => e.value,
            pointColorMapper: color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            name: name,
          ),
        ],
      ),
    );
  }
}

class _NursingTile extends StatelessWidget {
  final NursingModel n;
  const _NursingTile(this.n);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.textTheme.bodySmall?.copyWith(color: Colors.black54);
    final title = n.side.trim().isEmpty
        ? n.feedingType.toUpperCase()
        : '${n.feedingType.toUpperCase()} - ${n.side.toUpperCase()}';

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
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              n.feedingType.toLowerCase() == 'nursing'
                  ? Icons.child_care
                  : Icons.local_drink,
              color: Colors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text('${n.duration}min', style: subtle),
                    if (n.amount > 0) ...[
                      const Text(' • '),
                      Text(
                        '${n.amount.toStringAsFixed(1)} ${n.amountType}',
                        style: subtle,
                      ),
                    ],
                    if (n.milkType != null) ...[
                      const Text(' • '),
                      Text(n.milkType!, style: subtle),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            n.startTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
