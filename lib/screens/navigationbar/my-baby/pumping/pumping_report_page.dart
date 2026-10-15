import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/add_pumping_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/pumping_ai_service.dart'
    show PumpingAIService;
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef PumpingReportMode = ReportPeriod;

final _palette = ReportPalette(
  tint: const Color(0xFFffcab0),
  badge: const Color(0xFFffd3a5),
  segmentFill: const Color(0xFFffcab0),
  segmentActiveForeground: Colors.white.withValues(alpha: 0.9),
);

class PumpingReportPage extends StatefulWidget {
  const PumpingReportPage({super.key});

  @override
  State<PumpingReportPage> createState() => _PumpingReportPageState();
}

class _PumpingReportPageState extends State<PumpingReportPage>
    with
        ReportPageMixin<
          PumpingReportPage,
          PumpingModel,
          PumpingReportComputed
        > {
  @override
  void initState() {
    super.initState();
    initReport('pumping_report_page');
  }

  @override
  Future<List<PumpingModel>> fetchFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return pumpingService.todayPumpings();
      case ReportPeriod.week:
        return pumpingService.weekPumpings();
      case ReportPeriod.month:
        return pumpingService.monthPumpings();
    }
  }

  @override
  PumpingReportComputed computeReport(List<PumpingModel> items) =>
      PumpingAiCompute.compute(pumpings: items, mode: period);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'pumping',
    emptyMessage: 'No pumping data to export.',
    shareText:
        "My baby's pumping report from Coo Care Baby Tracker 🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (pumpings, computed, period, label) async {
      final ai = await PumpingAIService().analyzePumpingReport(
        mode: period,
        rangeLabel: label,
        pumpings: pumpings,
        computed: computed,
        userLanguage: "en",
        notes: const [],
      );
      return PumpingReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        pumpings: pumpings,
        computed: computed,
        ai: ai,
      );
    },
  );

  Future<void> _addPumping() async {
    await showActivitySheet(context, (_) => const AddPumpingBottomSheet());
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<PumpingModel>(
      title: "🫗  Pumping Reports",
      palette: _palette,
      pdfIconColor: Colors.redAccent,
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      empty: CenteredMessage(
        emoji: '🍼',
        title: 'No record found',
        subtitle: "You'll see it here when you add pumping for this interval.",
        actionLabel: 'Add pumping',
        onAction: _addPumping,
      ),
      builder: (context, pumpings) =>
          _buildReportBody(pumpings, computedFor(pumpings)),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili aralık) ----
  Widget _buildReportBody(
    List<PumpingModel> pumpings,
    PumpingReportComputed c,
  ) {
    final byHour = [
      for (int h = 0; h < 24; h++)
        ChartEntry(h.toString().padLeft(2, '0'), c.minutesByHour[h] ?? 0),
    ];

    // Son oturum: kullanıcının seçtiği başlangıç saatine göre.
    final hhmm = DateFormat('HH:mm');
    DateTime? last;
    for (final p in pumpings) {
      final at = _eventTime(p);
      if (last == null || at.isAfter(last)) last = at;
    }

    final longest = [...pumpings]
      ..sort((a, b) => b.duration.compareTo(a.duration));
    final maxMinutes = longest.isEmpty ? 0 : longest.first.duration;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ReportHeaderCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
          title: "Pumping Overview",
          subtitle: rangeLabel,
          leading: "🍼",
          gap: 4,
          stats: [
            ("Total", formatMinutes(c.totalMinutes)),
            ("Sessions", "${c.sessions}"),
            ("Avg", formatMinutes(c.avgSessionMinutes)),
            ("Last", last == null ? '-' : hhmm.format(last)),
          ],
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Distribution by hour",
          subtitle: "Sum of minutes per hour (00–23)",
          leading: "📊",
          child: SizedBox(
            height: 220,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}m',
                majorGridLines: const MajorGridLines(width: 0.4),
                axisLine: const AxisLine(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                ColumnSeries<ChartEntry, String>(
                  dataSource: byHour,
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  pointColorMapper: (e, _) =>
                      tierColor(e.value, high: 120, mid: 60, low: 30),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  dataLabelMapper: (e, _) =>
                      e.value == 0 ? "" : formatMinutes(e.value.toInt()),
                  name: 'Minutes',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Side distribution",
          subtitle: "Left vs Right",
          leading: "📊",
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
                  dataSource: [
                    ChartEntry('Left', c.leftMinutes),
                    ChartEntry('Right', c.rightMinutes),
                  ],
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
          title: "Longest sessions",
          subtitle: "Top 5 by duration",
          leading: "⚡",
          child: Column(
            children: [
              for (final p in longest.take(5))
                RatioBarTile(
                  leading: _SidePill(isLeft: p.isLeft),
                  label: hhmm.format(_eventTime(p)),
                  valueText: formatMinutes(p.duration),
                  ratio: maxMinutes == 0 ? 0 : p.duration / maxMinutes,
                  color: AppColors.kDeepOrange,
                  trackColor: Colors.orange.withValues(alpha: 0.1),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ReportTipsCard(
          title: "AI Pumping Tips",
          leading: "💡",
          badgeColor: Color(0xFFf6a192),
          tips: [
            (
              "⏰",
              "Your morning sessions yield the highest volume. Consider pumping earlier when possible",
            ),
            (
              "💧",
              "Stay hydrated! Drink water before and during pumping sessions for better output",
            ),
            (
              "😌",
              "Try relaxation techniques or looking at baby photos to help with let-down reflex",
            ),
          ],
        ),
      ],
    );
  }

  DateTime _eventTime(PumpingModel p) =>
      reportEventTime(p.createdAt, p.startTime);
}

class _SidePill extends StatelessWidget {
  final bool isLeft;
  const _SidePill({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final color = isLeft ? Colors.blue : Colors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isLeft ? "Left" : "Right",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
