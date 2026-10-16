import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/add_solid_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_compute.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/solid_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef SolidReportMode = ReportPeriod;

class SolidReportPage extends StatefulWidget {
  const SolidReportPage({super.key});

  @override
  State<SolidReportPage> createState() => _SolidReportPageState();
}

class _SolidReportPageState extends State<SolidReportPage>
    with ReportPageMixin<SolidReportPage, SolidModel, SolidReportComputed> {
  @override
  void initState() {
    super.initState();
    initReport('solid_report_page');
  }

  /// Yalnızca seçili dönem çekilir (anahtar aralığı sorgusu).
  @override
  Future<List<SolidModel>> fetchFor(ReportPeriod period) {
    final range = DateRange.forPeriod(period);
    return solidService.getUserSolidsInRange(range.start, range.end);
  }

  @override
  SolidReportComputed computeReport(List<SolidModel> items) =>
      SolidReportComputed.fromSolids(items);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'solid',
    emptyMessage: 'No food data to export.',
    shareText:
        "My baby's solid food report from Coo Care Baby Tracker 🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (solids, computed, period, label) async {
      final ai = await SolidAIService().analyzeSolidReport(
        mode: period,
        rangeLabel: label,
        solids: solids,
      );
      return SolidReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        solids: solids,
        computed: computed,
        ai: ai,
      );
    },
  );

  Future<void> _addSolid() async {
    await showActivitySheet(context, (_) => const AddSolidBottomSheet());
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = switch (period) {
      ReportPeriod.today => (
        '🍽️',
        'No solids recorded today',
        'Add a solid from the + button to see insights.',
      ),
      ReportPeriod.week => (
        '📅',
        'No solids this week',
        'Add some to see weekly insights.',
      ),
      ReportPeriod.month => (
        '📅',
        'No solids this month',
        'Add some to see monthly insights.',
      ),
    };

    return ReportScaffold<SolidModel>(
      title: "Food Reports",
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      bottomSafeArea: true,
      empty: CenteredMessage(
        emoji: emoji,
        title: title,
        subtitle: subtitle,
        actionLabel: 'Add solid',
        onAction: _addSolid,
      ),
      builder: (context, solids) =>
          _buildReportBody(solids, computedFor(solids)),
    );
  }

  // ---- RAPOR GÖVDESİ (günlük / haftalık / aylık tek gövde) ----
  Widget _buildReportBody(List<SolidModel> solids, SolidReportComputed c) {
    final p = period;
    final foods = sortedEntries(c.byFoodAmount);
    final maxFood = foods.isEmpty ? 0 : foods.first.value;
    final suffix = switch (p) {
      ReportPeriod.today => '',
      ReportPeriod.week => ' (week)',
      ReportPeriod.month => ' (month)',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ReportHeaderCard(
          padding: p == ReportPeriod.today
              ? const EdgeInsets.fromLTRB(16, 18, 16, 16)
              : const EdgeInsets.all(16),
          title: p == ReportPeriod.today
              ? "Today • $rangeLabel"
              : "Feeding Overview",
          subtitle: "",
          leading: "🍽️",
          gap: 12,
          tileHeight: 78,
          valueFontSize: null,
          stats: [
            ("T. Amount", "${c.totalAmount}"),
            ("Meals", "${c.mealCount}"),
            if (p == ReportPeriod.today) ("Last time", c.lastEatTime),
          ],
        ),
        const SizedBox(height: 16),

        switch (p) {
          ReportPeriod.today => ReportSectionCard(
            title: "Distribution by hour",
            subtitle: "When solids were eaten (00–23)",
            leading: "⏰",
            child: SizedBox(
              height: 220,
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                primaryXAxis: _categoryAxis(),
                primaryYAxis: _valueAxis(),
                tooltipBehavior: _tooltip(),
                enableAxisAnimation: true,
                series: [
                  ColumnSeries<ChartEntry, String>(
                    dataSource: orderedEntries(c.distEatHourAmount),
                    xValueMapper: (e, _) => e.label,
                    yValueMapper: (e, _) => e.value,
                    color: AppColors.activeBerry,
                    borderRadius: _columnRadius,
                    dataLabelSettings: _barDataLabels,
                    name: 'Amount',
                  ),
                ],
              ),
            ),
          ),
          ReportPeriod.week => ReportSectionCard(
            title: "By day of week",
            subtitle: "Total amount per day",
            leading: "🌈",
            child: SizedBox(
              height: 220,
              child: _AmountChart(series: _weekSeries(solids)),
            ),
          ),
          ReportPeriod.month => ReportSectionCard(
            title: "By day of month",
            leading: "🌈",
            subtitle: "Total amount per day (1–${DateTime.now().daysInMonth})",
            child: SizedBox(
              height: 240,
              child: _AmountChart(series: _monthSeries(solids)),
            ),
          ),
        },
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "By food type$suffix",
          subtitle: p == ReportPeriod.today
              ? "Total amount by solid"
              : "Totals by solid",
          leading: "🎯",
          child: SizedBox(
            height: 240,
            child: _DistributionDoughnut(data: foods),
          ),
        ),
        const SizedBox(height: 16),

        if (p != ReportPeriod.month) ...[
          ReportSectionCard(
            title: "Reactions$suffix",
            subtitle: p == ReportPeriod.today
                ? "Love it, meh, hated it, allergic/sensitivity"
                : "Count of reactions",
            leading: "😋",
            child: SizedBox(
              height: 220,
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                primaryXAxis: _categoryAxis(),
                primaryYAxis: _valueAxis(),
                tooltipBehavior: _tooltip(),
                enableAxisAnimation: true,
                series: [
                  BarSeries<ChartEntry, String>(
                    dataSource: sortedEntries(c.reactionCounts),
                    xValueMapper: (e, _) => e.label,
                    yValueMapper: (e, _) => e.value,
                    color: AppColors.activeBerry,
                    borderRadius: _barRadius,
                    dataLabelSettings: _barDataLabels,
                    name: 'Count',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        ReportSectionCard(
          title: switch (p) {
            ReportPeriod.today => "Top foods today",
            ReportPeriod.week => "Top foods this week",
            ReportPeriod.month => "Top foods this month",
          },
          subtitle: "Most eaten solids",
          leading: "⏰",
          child: Column(
            children: [
              for (final e in foods.take(p == ReportPeriod.month ? 8 : 6))
                RatioBarTile(
                  label: e.label,
                  valueText: "${e.value}",
                  ratio: maxFood == 0 ? 0 : e.value / maxFood,
                  color: AppColors.activeBerry,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ReportTipsCard(
          title: "AI Nutrition Tips",
          leading: "🤖",
          badgeColor: AppColors.peachTint,
          tips: [
            (
              "💡",
              "Excellent variety! Try introducing more finger foods to develop fine motor skills",
            ),
            (
              "🌟",
              "Your baby seems to love sweet foods. Gradually mix in vegetables for balanced taste",
            ),
            (
              "🍽️",
              "Consider iron-rich foods like spinach or lentils - perfect age for this nutrition!",
            ),
          ],
        ),
      ],
    );
  }

  // ---- Helpers ----

  DateTime _eventTime(SolidModel s) => reportEventTime(s.createdAt, s.eatTime);

  /// Bu haftanın günlerine (Pzt..Paz) göre toplam miktar.
  List<ChartEntry> _weekSeries(List<SolidModel> solids) {
    final range = DateRange.forPeriod(ReportPeriod.week);
    final totals = List<num>.filled(7, 0);
    for (final s in solids) {
      final at = _eventTime(s);
      if (range.contains(at)) totals[at.weekday - 1] += s.amountValue ?? 0;
    }
    final start = range.start;
    final fmt = DateFormat.E('en');
    return [
      for (var i = 0; i < 7; i++)
        ChartEntry(
          fmt.format(DateTime(start.year, start.month, start.day + i)),
          totals[i],
        ),
    ];
  }

  /// Bu ayın günlerine (1..daysInMonth) göre toplam miktar.
  List<ChartEntry> _monthSeries(List<SolidModel> solids) {
    final now = DateTime.now();
    final totals = List<num>.filled(now.daysInMonth, 0);
    for (final s in solids) {
      final at = _eventTime(s);
      if (at.year == now.year && at.month == now.month) {
        totals[at.day - 1] += s.amountValue ?? 0;
      }
    }
    return [
      for (var i = 0; i < totals.length; i++)
        ChartEntry((i + 1).toString().padLeft(2, '0'), totals[i]),
    ];
  }
}

/// Gün bazlı miktar grafiği (tek renk berry sütunlar).
class _AmountChart extends StatelessWidget {
  final List<ChartEntry> series;
  const _AmountChart({required this.series});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBackgroundColor: Colors.transparent,
        plotAreaBorderWidth: 0,
        primaryXAxis: _categoryAxis(),
        primaryYAxis: _valueAxis(),
        tooltipBehavior: _tooltip(),
        enableAxisAnimation: true,
        series: <CartesianSeries<ChartEntry, String>>[
          ColumnSeries<ChartEntry, String>(
            dataSource: series,
            xValueMapper: (e, _) => e.label,
            yValueMapper: (e, _) => e.value,
            color: AppColors.activeBerry,
            width: 0.85,
            spacing: 0.10,
            borderRadius: _columnRadius,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            name: 'Amount',
          ),
        ],
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
