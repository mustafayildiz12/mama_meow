import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
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
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef NursingReportMode = ReportPeriod;

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
      title: "Nursing Reports",
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
              plotAreaBorderWidth: 0,
              primaryXAxis: _categoryAxis(),
              primaryYAxis: _valueAxis(labelFormat: '{value}'),
              tooltipBehavior: _tooltip(),
              enableAxisAnimation: true,
              series: [
                ColumnSeries<ChartEntry, String>(
                  dataSource: orderedEntries(computed.distHourCount),
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  dataLabelMapper: (e, _) =>
                      e.value == 0 ? "" : e.value.toString(),
                  dataLabelSettings: _barDataLabels,
                  color: AppColors.activeBerry,
                  borderRadius: _columnRadius,
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
            child: _DistributionDoughnut(data: sideList),
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
            color: (_, index) => _seriesColor(index),
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
              color: (_, index) => _seriesColor(index),
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
          badgeColor: AppColors.peachTint,
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
        plotAreaBorderWidth: 0,
        primaryXAxis: _categoryAxis(),
        primaryYAxis: _valueAxis(),
        tooltipBehavior: _tooltip(),
        series: [
          BarSeries<ChartEntry, String>(
            dataSource: data,
            xValueMapper: (e, _) => e.label,
            yValueMapper: (e, _) => e.value,
            // Renk eşleyici yoksa tek seri: berry.
            color: AppColors.activeBerry,
            pointColorMapper: color,
            borderRadius: _barRadius,
            dataLabelSettings: _barDataLabels,
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
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.charcoalSoft,
    );
    final title = n.side.trim().isEmpty
        ? n.feedingType.toUpperCase()
        : '${n.feedingType.toUpperCase()} - ${n.side.toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconSquircle(
              background: AppColors.pinkTint,
              size: 40,
              radius: 14,
              child: Icon(
                n.feedingType.toLowerCase() == 'nursing'
                    ? Icons.child_care_outlined
                    : Icons.local_drink_outlined,
                color: AppColors.activeBerry,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Text('${n.duration}min', style: subtle),
                      if (n.amount > 0) ...[
                        Text(' • ', style: subtle),
                        Text(
                          '${n.amount.toStringAsFixed(1)} ${n.amountType}',
                          style: subtle,
                        ),
                      ],
                      if (n.milkType != null) ...[
                        Text(' • ', style: subtle),
                        Text(n.milkType!, style: subtle),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _TimeBadge(n.startTime),
          ],
        ),
      ),
    );
  }
}

/// Saat rozeti: pembe tint zemin, berry ink metin.
class _TimeBadge extends StatelessWidget {
  final String time;
  const _TimeBadge(this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        time,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.berryInk,
        ),
      ),
    );
  }
}

/// Dağılım halkası: dilimler seri sırasıyla (berry → pembe → şeftali …).
class _DistributionDoughnut extends StatelessWidget {
  final List<ChartEntry> data;
  const _DistributionDoughnut({required this.data});

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: Colors.transparent,
      legend: _legend,
      series: <CircularSeries<ChartEntry, String>>[
        DoughnutSeries<ChartEntry, String>(
          dataSource: data,
          xValueMapper: (e, _) => e.label,
          yValueMapper: (e, _) => e.value,
          pointColorMapper: (_, i) => _seriesColor(i),
          innerRadius: '58%',
          radius: '78%',
          strokeColor: AppColors.cottonWhite,
          strokeWidth: 2,
          legendIconType: LegendIconType.circle,
          dataLabelSettings: _pieDataLabels,
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }
}

// =========================
// GRAFİK STİLİ (Warm Cotton & Berry)
// =========================

const _axisLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.charcoalSoft,
);

/// Sütun/çubuk ucundaki değer etiketleri (beyaz kart üzerinde berry ink).
const _barDataLabels = DataLabelSettings(
  isVisible: true,
  labelAlignment: ChartDataLabelAlignment.outer,
  textStyle: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.berryInk,
  ),
);

/// Halka grafik etiketleri: dilimin dışında, kömür renginde.
const _pieDataLabels = DataLabelSettings(
  isVisible: true,
  labelPosition: ChartDataLabelPosition.outside,
  textStyle: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.deepCharcoal,
  ),
  connectorLineSettings: ConnectorLineSettings(color: AppColors.outline),
);

const _legend = Legend(
  isVisible: true,
  overflowMode: LegendItemOverflowMode.wrap,
  iconHeight: 10,
  iconWidth: 10,
  textStyle: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.deepCharcoal,
  ),
);

/// Sütunların üst köşeleri yuvarlak.
const _columnRadius = BorderRadius.vertical(top: Radius.circular(8));

/// Yatay çubukların değer ucu (sağ) yuvarlak.
const _barRadius = BorderRadius.horizontal(right: Radius.circular(8));

/// Kategori ekseni: çizgisiz, ızgarasız, yumuşak kömür etiketler.
CategoryAxis _categoryAxis() => const CategoryAxis(
  majorGridLines: MajorGridLines(width: 0),
  majorTickLines: MajorTickLines(width: 0),
  axisLine: AxisLine(width: 0),
  labelStyle: _axisLabelStyle,
);

/// Değer ekseni: ince pembe (hairline) ızgara.
NumericAxis _valueAxis({String? labelFormat}) => NumericAxis(
  labelFormat: labelFormat,
  majorGridLines: const MajorGridLines(width: 1, color: AppColors.hairline),
  majorTickLines: const MajorTickLines(width: 0),
  axisLine: const AxisLine(width: 0),
  labelStyle: _axisLabelStyle,
);

TooltipBehavior _tooltip() => TooltipBehavior(
  enable: true,
  color: AppColors.deepCharcoal,
  textStyle: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.cottonWhite,
  ),
);

/// Kategori sırasına göre seri rengi (berry → pembe → şeftali → ink → kömür).
Color _seriesColor(int index) =>
    AppColors.chartSeries[index % AppColors.chartSeries.length];
