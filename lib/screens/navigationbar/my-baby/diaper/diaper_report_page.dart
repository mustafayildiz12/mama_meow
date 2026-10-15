import 'package:flutter/material.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/add_diaper_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_helpers.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/diaper_ai_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Eski ad korunuyor; yeni kodda doğrudan ReportPeriod kullanın.
typedef DiaperReportMode = ReportPeriod;

final _palette = ReportPalette(
  tint: const Color(0xFFA8E6CF),
  segmentFill: const Color(0xFFA8E6CF),
  segmentBackground: Colors.white.withValues(alpha: 0.8),
  segmentActiveForeground: Colors.white.withValues(alpha: 0.9),
);

class DiaperReportPage extends StatefulWidget {
  const DiaperReportPage({super.key});
  @override
  State<DiaperReportPage> createState() => _DiaperReportPageState();
}

class _DiaperReportPageState extends State<DiaperReportPage>
    with ReportPageMixin<DiaperReportPage, DiaperModel, DiaperReportComputed> {
  @override
  void initState() {
    super.initState();
    initReport('diaper_report_page');
  }

  @override
  Future<List<DiaperModel>> fetchFor(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return diaperService.todayDiapers();
      case ReportPeriod.week:
        return diaperService.weekDiapers();
      case ReportPeriod.month:
        return diaperService.monthDiapers();
    }
  }

  @override
  DiaperReportComputed computeReport(List<DiaperModel> items) =>
      DiaperReportComputed.fromDiapers(items);

  Future<void> _exportPdf(BuildContext anchor) => exportPdf(
    anchor,
    filePrefix: 'diaper',
    emptyMessage: 'No diaper data to export.',
    shareText:
        "My baby's diaper report from Coo Care Baby Tracker 🐾 ${globalFunctions.appInviteText()}",
    buildPdf: (diapers, computed, period, label) async {
      final ai = await DiaperAIService().analyze(
        mode: period,
        rangeLabel: label,
        c: computed,
        userLanguage: "en",
        notes: const [],
      );
      return DiaperReportPdfBuilder.build(
        format: PdfPageFormat.a4,
        mode: period,
        rangeLabel: label,
        diapers: diapers,
        computed: computed,
        ai: ai,
      );
    },
  );

  Future<void> _addDiaper() async {
    await showActivitySheet(context, (_) => const AddDiaperBottomSheet());
    if (mounted) await refreshReport();
  }

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<DiaperModel>(
      title: "🚼  Diaper Reports",
      palette: _palette,
      pdfIconColor: Colors.green,
      isLoading: exporting,
      onExportPdf: _exportPdf,
      onRefresh: refreshReport,
      period: period,
      onPeriodChanged: changePeriod,
      future: future,
      empty: CenteredMessage(
        emoji: '🧷',
        title: 'No record found',
        subtitle:
            "You'll see it here when you add a diaper change for this period.",
        actionLabel: 'Add diaper',
        onAction: _addDiaper,
      ),
      builder: (context, diapers) =>
          _buildReportBody(context, computedFor(diapers)),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili aralığa uygulanır) ----
  Widget _buildReportBody(BuildContext context, DiaperReportComputed computed) {
    final byHour = orderedEntries(computed.distHourCount);
    final byTypeList = sortedEntries(computed.typeCounts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ReportHeaderCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
          title: "Range • $rangeLabel",
          subtitle: "Summary of diaper changes",
          gap: 2,
          stats: [
            ("Total", computed.totalCount.toString()),
            ("Avg", formatMinutes(computed.avgGapMinutes)),
            ("Longest", formatMinutes(computed.maxGapMinutes)),
          ],
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "Distribution by hour",
          subtitle: "When diaper changes happened (00–23)",
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
              enableAxisAnimation: true,
              series: [
                ColumnSeries<ChartEntry, String>(
                  dataSource: byHour,
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
                  color: const Color(0xFF059669),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ReportSectionCard(
          title: "By diaper type",
          subtitle: "wet / dirty / mixed / pee / poop",
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
                  dataSource: byTypeList,
                  xValueMapper: (e, _) => e.label,
                  yValueMapper: (e, _) => e.value,
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
          title: "Timeline",
          subtitle: "Chronological diaper changes for $rangeLabel",
          child: Column(
            children: [
              for (final d in computed.timeline)
                _TimelineTile(time: d.time, label: d.label),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String time;
  final String label;
  const _TimelineTile({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFA8E6CF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
