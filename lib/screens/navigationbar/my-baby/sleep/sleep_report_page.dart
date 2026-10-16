import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/add_sleep_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/sleep_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_charts.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/sleep_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef SleepReportMode = ReportPeriod;

class SleepReportPage extends StatefulWidget {
  const SleepReportPage({super.key});

  @override
  State<SleepReportPage> createState() => _SleepReportPageState();
}

class _SleepReportPageState extends State<SleepReportPage>
    with ReportPageMixin<SleepReportPage, SleepModel, _SleepReportComputed> {
  @override
  void initState() {
    super.initState();
    initReport('sleep_report_page');
  }

  @override
  Future<List<SleepModel>> fetchFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return sleepService.todaySleeps();
      case ReportPeriod.week:
        return sleepService.weekSleeps();
      case ReportPeriod.month:
        return sleepService.monthSleeps();
    }
  }

  @override
  _SleepReportComputed computeReport(List<SleepModel> items) =>
      _computeReport(items);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'sleep',
    emptyMessage: 'No sleep data to export.',
    // Export = paylaşım sayfası (görüntüle/kaydet/partner-doktora gönder).
    shareText:
        "My baby's sleep report from Coo Care Baby Tracker 😴🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (sleeps, _, period, label) async {
      final ai = await SleepAIService().analyzeSleepReport(
        mode: period,
        rangeLabel: label,
        sleeps: sleeps,
      );
      return SleepReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        sleeps: sleeps,
        ai: ai,
      );
    },
  );

  Future<void> _addSleep() async {
    await showActivitySheet(
      context,
      (_) => SleepExtendedMultiSliderBottomSheet(
        initialStartEnds: const [12 * 60, 15 * 60],
        sleepDate: DateTime.now(),
      ),
    );
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<SleepModel>(
      title: "Sleep Reports",
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      bottomSafeArea: true,
      empty: CenteredMessage(
        emoji: '😴',
        title: 'No record found',
        subtitle: "You'll see it here when you add sleep for this interval.",
        actionLabel: 'Add sleep',
        onAction: _addSleep,
      ),
      builder: (context, sleeps) => _buildReportBody(computedFor(sleeps)),
    );
  }

  // =========================
  // ✅ SINGLE COMPUTE (1 kez)
  // =========================

  _SleepReportComputed _computeReport(List<SleepModel> sleeps) {
    final byHourRaw = <int, int>{}; // 0..23 -> total minutes
    final byHow = <String, int>{};
    final byStartMood = <String, int>{};
    final byEndMood = <String, int>{};
    int totalMinutes = 0;

    void bump(Map<String, int> map, String? raw) {
      final v = (raw ?? '').trim();
      final key = (v.isEmpty ? 'none' : v).toLowerCase();
      map[key] = (map[key] ?? 0) + 1;
    }

    // Gece yarısında bölünmüş parçalar tek uyku sayılır.
    final sessions = mergeSleepSessions(sleeps);
    for (final s in sessions) {
      final dur = s.durationMinutes;
      totalMinutes += dur;

      // başlangıç saati dağılımı
      final h = s.start?.hour ?? parseHourMinute(s.first.startTime)?.$1 ?? 0;
      byHourRaw[h] = (byHourRaw[h] ?? 0) + dur;

      bump(byHow, s.first.howItHappened);
      bump(byStartMood, s.first.startOfSleep);
      bump(byEndMood, s.last.endOfSleep);
    }

    final count = sessions.length;
    return _SleepReportComputed(
      totalMinutes: totalMinutes,
      count: count,
      avgMinutes: count == 0 ? 0 : (totalMinutes / count).round(),
      distHourMinutes: {
        for (int h = 0; h < 24; h++)
          h.toString().padLeft(2, '0'): byHourRaw[h] ?? 0,
      },
      howCounts: byHow,
      startMoodCounts: byStartMood,
      endMoodCounts: byEndMood,
      sessions: sessions,
    );
  }

  // =========================
  // UI BUILD (computed kullan)
  // =========================

  Widget _buildReportBody(_SleepReportComputed computed) {
    final longest = [...computed.sessions]
      ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
    final maxDur = longest.isEmpty ? 0 : longest.first.durationMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ReportHeaderCard(
          title: "Sleep Overview",
          subtitle: rangeLabel,
          tileHeight: 78,
          valueMaxLines: 2,
          stats: [
            ("Total", formatMinutes(computed.totalMinutes)),
            ("Sleeps", "${computed.count}"),
            ("Avg", formatMinutes(computed.avgMinutes)),
          ],
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Distribution by start hour",
          subtitle: "When sleep started (sum of minutes per hour)",
          child: SizedBox(
            height: 220,
            child: _MinutesByHourChart(
              series: orderedEntries(computed.distHourMinutes),
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "How it happened",
          subtitle: "Sleep method distribution",
          child: SizedBox(
            height: 240,
            child: DistributionDoughnut(
              data: sortedEntries(computed.howCounts),
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Start of sleep",
          subtitle: "upset, crying, content, under 10 min, 10–30 min, >30 min",
          child: _countBarChart(sortedEntries(computed.startMoodCounts)),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "End of sleep",
          subtitle: "woke up child, upset, content, crying",
          child: _countBarChart(sortedEntries(computed.endMoodCounts)),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Longest sleeps",
          subtitle: "Top 5 by duration",
          child: Column(
            children: [
              for (final e in longest.take(5))
                RatioBarTile(
                  label: "${e.first.startTime} → ${e.last.endTime}",
                  valueText: formatMinutes(e.durationMinutes),
                  ratio: maxDur == 0 ? 0 : e.durationMinutes / maxDur,
                  color: AppColors.activeBerry,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _countBarChart(List<ChartEntry> data) {
    return SizedBox(
      height: 220,
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBorderWidth: 0,
        primaryXAxis: ReportChartStyle.categoryAxis(),
        primaryYAxis: ReportChartStyle.valueAxis(),
        tooltipBehavior: ReportChartStyle.tooltip(),
        series: [
          BarSeries<ChartEntry, String>(
            dataSource: data,
            xValueMapper: (e, _) => e.label,
            yValueMapper: (e, _) => e.value,
            color: AppColors.activeBerry,
            borderRadius: ReportChartStyle.barRadius,
            dataLabelSettings: ReportChartStyle.barDataLabels,
            name: 'Count',
          ),
        ],
      ),
    );
  }
}

// =========================
// COMPUTED MODEL
// =========================

class _SleepReportComputed {
  final int totalMinutes;
  final int count;
  final int avgMinutes;

  final Map<String, int> distHourMinutes; // "00".."23" -> minutes
  final Map<String, int> howCounts; // method -> count
  final Map<String, int> startMoodCounts; // start mood -> count
  final Map<String, int> endMoodCounts; // end mood -> count

  final List<SleepSession> sessions; // birleştirilmiş uykular

  const _SleepReportComputed({
    required this.totalMinutes,
    required this.count,
    required this.avgMinutes,
    required this.distHourMinutes,
    required this.howCounts,
    required this.startMoodCounts,
    required this.endMoodCounts,
    required this.sessions,
  });
}

/// Saat başına toplam uyku dakikası (tek renk berry sütunlar).
class _MinutesByHourChart extends StatelessWidget {
  final List<ChartEntry> series;
  const _MinutesByHourChart({required this.series});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBackgroundColor: Colors.transparent,
        plotAreaBorderWidth: 0,
        primaryXAxis: ReportChartStyle.categoryAxis(),
        primaryYAxis: ReportChartStyle.valueAxis(labelFormat: '{value}m'),
        tooltipBehavior: ReportChartStyle.tooltip(),
        enableAxisAnimation: true,
        series: <CartesianSeries<ChartEntry, String>>[
          ColumnSeries<ChartEntry, String>(
            dataSource: series,
            xValueMapper: (e, _) => e.label,
            yValueMapper: (e, _) => e.value,
            color: AppColors.activeBerry,
            width: 0.85,
            spacing: 0.10,
            borderRadius: ReportChartStyle.columnRadius,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            name: 'Amount',
          ),
        ],
      ),
    );
  }
}
