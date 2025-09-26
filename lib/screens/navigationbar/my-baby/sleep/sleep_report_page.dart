import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';

enum ReportMode { today, week, month }

class SleepReportPage extends StatefulWidget {
  const SleepReportPage({super.key});

  @override
  State<SleepReportPage> createState() => _SleepReportPageState();
}

class _SleepReportPageState extends State<SleepReportPage> {
  ReportMode _mode = ReportMode.today;
  late Future<List<SleepModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchByMode(_mode);
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchByMode(_mode));
    await _future;
  }

  Future<List<SleepModel>> _fetchByMode(ReportMode mode) {
    switch (mode) {
      case ReportMode.today:
        return sleepService.todaySleeps();
      case ReportMode.week:
        return sleepService.weekSleeps();
      case ReportMode.month:
        return sleepService.monthSleeps();
    }
  }

  String _rangeLabel(ReportMode mode) {
    final now = DateTime.now();
    if (mode == ReportMode.today) {
      return DateFormat('EEEE, d MMM').format(now);
    } else if (mode == ReportMode.week) {
      final s = now.startOfWeekTR;
      final e = now.endOfWeekTR;
      final a = DateFormat('d MMM').format(s);
      final b = DateFormat('d MMM').format(e);
      return "$a – $b";
    } else {
      final s = now.startOfMonth;
      final e = now.endOfMonth;
      final a = DateFormat('MMM yyyy').format(s);
      final b = DateFormat('d').format(e);
      return "$a (1–$b)";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios),
              ),
            ),
          ),
          title: const Text(
            "😴  Sleep Reports",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Text(
                "📤",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 12),
                child: Center(
                  child: _GlassSegmented(
                    value: _mode,
                    onChanged: (m) {
                      setState(() {
                        _mode = m;
                        _future = _fetchByMode(_mode);
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<SleepModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingView();
                    }
                    if (snapshot.hasError) {
                      return _CenteredMessage(
                        emoji: '⚠️',
                        title: 'Bir şeyler ters gitti',
                        subtitle: snapshot.error.toString(),
                      );
                    }
                    final sleeps = snapshot.data ?? [];
                    if (sleeps.isEmpty) {
                      return const _CenteredMessage(
                        emoji: '😴',
                        title: 'Kayıt bulunamadı',
                        subtitle:
                            'Bu aralık için uyku eklediğinde burada göreceksin.',
                      );
                    }
                    return _buildReportBody(context, sleeps);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REPORT BODY (bugünkü/haftalık/aylık hepsi aynı görselleştirmeyi kullanır) ---
  Widget _buildReportBody(BuildContext context, List<SleepModel> sleeps) {
    // Aggregate
    final minutesList = <int>[];
    final byHourRaw = <int, int>{}; // 0..23 -> toplam dakika
    final byStartMood = <String, int>{};
    final byEndMood = <String, int>{};
    final byHow = <String, int>{};

    DateTime? latestEnd;
    String lastEndStr = '-';

    for (final s in sleeps) {
      final dur = _calcDurationMinutes(s);
      minutesList.add(dur);

      final h = _parseHourSafe(s.startTime);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + dur;

      if ((s.startOfSleep ?? '').trim().isNotEmpty) {
        final k = _normalizeLabel(s.startOfSleep!);
        byStartMood[k] = (byStartMood[k] ?? 0) + 1;
      } else {
        byStartMood['none'] = (byStartMood['none'] ?? 0) + 1;
      }

      if ((s.endOfSleep ?? '').trim().isNotEmpty) {
        final k = _normalizeLabel(s.endOfSleep!);
        byEndMood[k] = (byEndMood[k] ?? 0) + 1;
      } else {
        byEndMood['none'] = (byEndMood['none'] ?? 0) + 1;
      }

      if ((s.howItHappened ?? '').trim().isNotEmpty) {
        final k = _normalizeLabel(s.howItHappened!);
        byHow[k] = (byHow[k] ?? 0) + 1;
      } else {
        byHow['none'] = (byHow['none'] ?? 0) + 1;
      }

      final endDt = _combineDateAndTime(
        s.sleepDate,
        s.endTime,
        allowNextDay: true,
      );
      if (endDt != null && (latestEnd == null || endDt.isAfter(latestEnd))) {
        latestEnd = endDt;
        lastEndStr = DateFormat('HH:mm').format(endDt);
      }
    }

    final totalMinutes = minutesList.fold<int>(0, (sum, m) => sum + m);
    final napsCount = sleeps.length;
    final avgMinutes = napsCount == 0 ? 0 : (totalMinutes / napsCount).round();

    final byHour = <_KV>[];
    for (int h = 0; h < 24; h++) {
      byHour.add(_KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)));
    }

    final howList = byHow.entries.map((e) => _KV(e.key, e.value)).toList()
      ..sort((a, b) => b.v.compareTo(a.v));

    final startMoodList =
        byStartMood.entries.map((e) => _KV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));
    final endMoodList =
        byEndMood.entries.map((e) => _KV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));

    final sortedByDuration =
        sleeps.map((s) => _SleepWithDur(s, _calcDurationMinutes(s))).toList()
          ..sort((a, b) {
            final aDt = _combineDateAndTime(
              a.model.sleepDate,
              a.model.startTime,
            );
            final bDt = _combineDateAndTime(
              b.model.sleepDate,
              b.model.startTime,
            );
            if (aDt == null && bDt == null) return 0;
            if (aDt == null) return 1;
            if (bDt == null) return -1;
            return aDt.compareTo(bDt);
          });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeaderCard(
          dateLabel: _rangeLabel(_mode),
          total: _fmtMin(totalMinutes),
          naps: napsCount,
          avg: _fmtMin(avgMinutes),
          lastEndTime: lastEndStr,
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Distribution by start hour",
          subtitle: "When sleep started (sum of minutes per hour)",
          leading: "📊",
          child: SizedBox(height: 220, child: SleepChartCard(series: byHour)),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "How it happened",
          subtitle: "Sleep method distribution",
          leading: "📊",
          child: SizedBox(
            height: 240,
            child: SfCircularChart(
              backgroundColor: Colors.transparent,
              legend: const Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              series: <CircularSeries<_KV, String>>[
                PieSeries<_KV, String>(
                  dataSource: howList,
                  xValueMapper: (e, _) => e.k,
                  yValueMapper: (e, _) => e.v,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  explode: true,
                  explodeIndex: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Start of sleep",
          subtitle: "upset, crying, content, under 10 min, 10–30 min, >30 min",
          leading: "🌊",
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
                BarSeries<_KV, String>(
                  dataSource: startMoodList,
                  xValueMapper: (e, _) => e.k,
                  yValueMapper: (e, _) => e.v,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "End of sleep",
          subtitle: "woke up child, upset, content, crying",
          leading: "🌊",
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
                BarSeries<_KV, String>(
                  dataSource: endMoodList,
                  xValueMapper: (e, _) => e.k,
                  yValueMapper: (e, _) => e.v,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Longest sleeps",
          subtitle: "Top 5 by duration",
          leading: "⭐",
          child: Column(
            children: [
              for (final e
                  in (sortedByDuration
                        ..sort((a, b) => b.minutes.compareTo(a.minutes)))
                      .take(5))
                _TopSleepTile(
                  label: "${e.model.startTime} → ${e.model.endTime}",
                  minutes: e.minutes,
                  ratio: sortedByDuration.isEmpty
                      ? 0
                      : (e.minutes /
                                (sortedByDuration
                                    .map((x) => x.minutes)
                                    .fold<int>(0, (p, c) => c > p ? c : p)))
                            .clamp(0, 1),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Helpers (senin önceki kodundan) ----
  String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }

  int _parseHourSafe(String hhmm) {
    final h = int.tryParse(hhmm.split(':').first);
    return (h == null || h < 0 || h > 23) ? 0 : h;
  }

  DateTime? _combineDateAndTime(
    String dateStr,
    String hhmm, {
    bool allowNextDay = false,
  }) {
    try {
      final dateOnly = dateStr.split(' ').first; // "yyyy-MM-dd"
      final ymd = DateFormat('yyyy-MM-dd').parseStrict(dateOnly);
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return DateTime(ymd.year, ymd.month, ymd.day, h, m);
    } catch (_) {
      return null;
    }
  }

  int _calcDurationMinutes(SleepModel s) {
    final start = _combineDateAndTime(s.sleepDate, s.startTime);
    DateTime? end = _combineDateAndTime(s.sleepDate, s.endTime);
    if (start == null || end == null) return 0;
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1)); // geceyi aşarsa
    }
    return end.difference(start).inMinutes;
  }

  String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }

  String _normalizeLabel(String s) => s.trim().toLowerCase();
}

// --- Shared view classes (seninkilerle aynı) ---

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _CenteredMessage extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  const _CenteredMessage({
    required this.emoji,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

class _SleepWithDur {
  final SleepModel model;
  final int minutes;
  _SleepWithDur(this.model, this.minutes);
}

class _HeaderCard extends StatelessWidget {
  final String dateLabel;
  final String total;
  final int naps;
  final String avg;
  final String lastEndTime;

  const _HeaderCard({
    required this.dateLabel,
    required this.total,
    required this.naps,
    required this.avg,
    required this.lastEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Sleep Overview",
      subtitle: "$dateLabel",
      leading: "🌙",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: total),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Sleeps", value: "$naps"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Avg", value: avg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Last end", value: lastEndTime),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  const _StatTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets padding;
  final String leading;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    required this.leading,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFc7ceea),
            Colors.white.withValues(alpha: 0.9),
          ],
          stops: const [0.2, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFb5c8e8),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(leading, style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TopSleepTile extends StatelessWidget {
  final String label;
  final int minutes;
  final double ratio;
  const _TopSleepTile({
    required this.label,
    required this.minutes,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFc7ceea).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFc7ceea),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _fmtMin(minutes),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFc7ceea),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }
}

class _GlassSegmented extends StatelessWidget {
  final ReportMode value;
  final ValueChanged<ReportMode> onChanged;

  const _GlassSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Renkleri kolay değiştirebilmen için tanımlar:
    final bgColor = Colors.white;
    final borderColor = Colors.white.withValues(
      alpha: 0.3,
    ); // rgba(255,255,255,0.3)
    final activeFill = const Color(0xFFc7ceea); // aktif buton zemini
    final inactiveFg = theme.textTheme.bodyMedium?.color; // pasif buton yazısı
    final activeFg = Colors.white; // aktif buton yazısı

    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 0), // CSS'teki margin
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // blur(20px)
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            padding: const EdgeInsets.all(4), // CSS'teki padding: 4px
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Daily',
                    selected: value == ReportMode.today,
                    onTap: () => onChanged(ReportMode.today),
                    activeFg: activeFg,
                    inactiveFg: inactiveFg,
                    activeFill: activeFill,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentButton(
                    label: 'Weekly',
                    selected: value == ReportMode.week,
                    onTap: () => onChanged(ReportMode.week),
                    activeFg: activeFg,
                    inactiveFg: inactiveFg,
                    activeFill: activeFill,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentButton(
                    label: 'Monthly',
                    selected: value == ReportMode.month,
                    onTap: () => onChanged(ReportMode.month),
                    activeFg: activeFg,
                    inactiveFg: inactiveFg,
                    activeFill: activeFill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeFill;
  final Color? inactiveFg;
  final Color activeFg;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeFill,
    required this.inactiveFg,
    required this.activeFg,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? activeFill : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? activeFg : inactiveFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SleepChartCard extends StatelessWidget {
  final List<_KV> series;
  const SleepChartCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBackgroundColor: Colors.transparent,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: const MajorGridLines(width: 0.4),
          axisLine: const AxisLine(width: 0),
          labelFormat: '{value}m',
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        enableAxisAnimation: true,
        series: <CartesianSeries<_KV, String>>[
          ColumnSeries<_KV, String>(
            dataSource: series,
            xValueMapper: (e, _) => e.k,
            yValueMapper: (e, _) => e.v,
            // Her bar için farklı renk:
            pointColorMapper: (e, _) => _colorFor(e.v),
            // Barları yatayda genişlet:
            width: 0.85, // 0..1 (daha büyük = daha kalın)
            spacing: 0.10, // barlar arası boşluk
            borderRadius: BorderRadius.circular(8),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            name: 'Amount',
          ),
        ],
      ),
    );
  }

  // CSS'teki sınıflara benzer renklendirme:
  // vegetables, fruits, grains(az biraz daha parlak), proteins
  Color _colorFor(int count) {
    if (count >= 2000) {
      return const Color(0xFF2ECC71); // y
    } else if (count >= 1000 && count < 2000) {
      return const Color(0xFFFF7F50); // mercan
    } else if (count >= 500 && count < 1000) {
      // Biraz daha parlak/aydınlık
      final base = const Color(0xFFF1C40F);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness((hsl.lightness * 1.10).clamp(0, 1)).toColor();
    } else if (count < 500) {
      return const Color(0xFF3498DB);
    } else {
      return Colors.teal;
    }
  }
}
