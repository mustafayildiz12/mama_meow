import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';

class SleepReportPage extends StatefulWidget {
  const SleepReportPage({super.key});

  @override
  State<SleepReportPage> createState() => _SleepReportPageState();
}

class _SleepReportPageState extends State<SleepReportPage> {
  late Future<List<SleepModel>> _futureToday;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodaySleeps();
  }

  Future<void> _refresh() async {
    setState(() => _futureToday = _fetchTodaySleeps());
    await _futureToday;
  }

  Future<List<SleepModel>> _fetchTodaySleeps() async {
    final all = await sleepService.getSleepList();

    // sleepDate: "yyyy-MM-dd hh:mm" (muhtemelen 24 saatlik kullanıyorsun; yine de güvenli parse yazdım)
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final result = <SleepModel>[];
    for (final s in all) {
      final datePart = _safeDatePart(s.sleepDate); // "yyyy-MM-dd"
      if (datePart == todayKey) {
        result.add(s);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade200, Colors.purple.shade200],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text("Today's Sleep Report"),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<SleepModel>>(
            future: _futureToday,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              }
              if (snapshot.hasError) {
                return _CenteredMessage(
                  emoji: '⚠️',
                  title: 'Something went wrong',
                  subtitle: snapshot.error.toString(),
                );
              }
              final sleeps = snapshot.data ?? [];
              if (sleeps.isEmpty) {
                return const _CenteredMessage(
                  emoji: '😴',
                  title: 'No sleep records today',
                  subtitle: 'Log a sleep to see insights here.',
                );
              }

              // ---- Aggregate ----
              final minutesList = <int>[];
              final byHourRaw = <int, int>{}; // 0..23 -> toplam dakika
              final byStartMood =
                  <
                    String,
                    int
                  >{}; // upset, crying, content, under10, 10-30, >30
              final byEndMood =
                  <String, int>{}; // woke up child, upset, content, crying
              final byHow =
                  <String, int>{}; // nursing, own bed, next to caregiver, ...

              DateTime? latestEnd; // son bitiş zamanı
              String lastEndStr = '-';

              for (final s in sleeps) {
                final dur = _calcDurationMinutes(s); // cross-midnight aware
                minutesList.add(dur);

                // start hour bucket
                final h = _parseHourSafe(s.startTime);
                byHourRaw[h] = (byHourRaw[h] ?? 0) + dur;

                // moods & how
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

                // last end time (latest by end datetime)
                final endDt = _combineDateAndTime(
                  s.sleepDate,
                  s.endTime,
                  allowNextDay: true,
                );
                if (endDt != null &&
                    (latestEnd == null || endDt.isAfter(latestEnd))) {
                  latestEnd = endDt;
                  lastEndStr = DateFormat('HH:mm').format(endDt);
                }
              }

              final totalMinutes = minutesList.fold<int>(
                0,
                (sum, m) => sum + m,
              );
              final napsCount = sleeps.length;
              final avgMinutes = napsCount == 0
                  ? 0
                  : (totalMinutes / napsCount).round();

              // Saat 0..23 eksiksiz ve sıralı
              final byHour = <_KV>[];
              for (int h = 0; h < 24; h++) {
                byHour.add(
                  _KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)),
                );
              }

              // how-it-happened pasta
              final howList =
                  byHow.entries.map((e) => _KV(e.key, e.value)).toList()
                    ..sort((a, b) => b.v.compareTo(a.v));

              // moods barlar
              final startMoodList =
                  byStartMood.entries.map((e) => _KV(e.key, e.value)).toList()
                    ..sort((a, b) => b.v.compareTo(a.v));
              final endMoodList =
                  byEndMood.entries.map((e) => _KV(e.key, e.value)).toList()
                    ..sort((a, b) => b.v.compareTo(a.v));

              final sortedByDuration = <_SleepWithDur>[];
              for (final s in sleeps) {
                sortedByDuration.add(_SleepWithDur(s, _calcDurationMinutes(s)));
              }
              sortedByDuration.sort((a, b) {
                final aDt = _combineDateAndTime(
                  a.model.sleepDate,
                  a.model.startTime,
                );
                final bDt = _combineDateAndTime(
                  b.model.sleepDate,
                  b.model.startTime,
                );
                if (aDt == null && bDt == null) return 0;
                if (aDt == null) return 1; // null en sona
                if (bDt == null) return -1;
                return aDt.compareTo(bDt); // küçükten büyüğe
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _HeaderCard(
                    dateLabel: todayStr,
                    total: _fmtMin(totalMinutes),
                    naps: napsCount,
                    avg: _fmtMin(avgMinutes),
                    lastEndTime: lastEndStr,
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: "Distribution by start hour",
                    subtitle: "When sleep started (sum of minutes per hour)",
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
                          labelFormat: '{value}m',
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        enableAxisAnimation: true,
                        series: [
                          ColumnSeries<_KV, String>(
                            dataSource: byHour,
                            xValueMapper: (e, _) => e.k,
                            yValueMapper: (e, _) => e.v,
                            dataLabelMapper: (e, _) =>
                                e.v == 0 ? "" : _fmtMinutes(e.v),
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                            color: AppColors.kDeepOrange,
                            name: 'Minutes',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: "How it happened",
                    subtitle: "Sleep method distribution",
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
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
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
                    subtitle:
                        "upset, crying, content, under 10 min, 10–30 min, >30 min",
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
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
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
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
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
                    child: Column(
                      children: [
                        for (final e in sortedByDuration)
                          _TopSleepTile(
                            label: "${e.model.startTime} → ${e.model.endTime}",
                            minutes: e.minutes,
                            ratio: sortedByDuration.isEmpty
                                ? 0
                                : (e.minutes / sortedByDuration.first.minutes),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- Helpers ----

  String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }

  String _safeDatePart(String sleepDate) {
    // Beklenen format: "yyyy-MM-dd hh:mm" veya "yyyy-MM-dd HH:mm"
    // Sadece tarih bölümünü al
    final parts = sleepDate.split(' ');
    if (parts.isNotEmpty) return parts.first;
    return sleepDate;
    // Alternatif: DateTime.tryParse(sleepDate)?.toIso8601String().substring(0,10) ...
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
    // dateStr: "yyyy-MM-dd hh:mm" (saat kısmını yok sayıp sadece tarihi kullanıyoruz)
    try {
      final dateOnly = _safeDatePart(dateStr);
      final yearMonthDay = DateFormat('yyyy-MM-dd').parseStrict(dateOnly);
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return DateTime(
        yearMonthDay.year,
        yearMonthDay.month,
        yearMonthDay.day,
        h,
        m,
      );
    } catch (_) {
      return null;
    }
  }

  int _calcDurationMinutes(SleepModel s) {
    // start/end "HH:mm" + sleepDate tarih parçası
    final start = _combineDateAndTime(s.sleepDate, s.startTime);
    DateTime? end = _combineDateAndTime(s.sleepDate, s.endTime);

    if (start == null || end == null) return 0;

    // Cross-midnight: end < start ise 1 gün ekle
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    return end.difference(start).inMinutes;
  }

  String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }

  String _normalizeLabel(String s) {
    return s.trim().toLowerCase();
  }
}

class _KV {
  final String k; // hour
  final int v; // total minutes
  String get label => _fmtMinutes(v); // computed property

  _KV(this.k, this.v);

  String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}

class _SleepWithDur {
  final SleepModel model;
  final int minutes;
  _SleepWithDur(this.model, this.minutes);
}

/// ---- UI FRAGMENTS (solid rapordaki stillerle uyumlu) ----

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
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

class _HeaderCard extends StatelessWidget {
  final String dateLabel;
  final String total; // "xh ym"
  final int naps;
  final String avg; // "xh ym"
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
      title: "Today • $dateLabel",
      subtitle: "Summary of sleep",
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.black54),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kDeepOrange,
                ),
              ),
            ],
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

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,

    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
     // color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Color(0xFFF6F1E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
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
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.kDeepOrange,
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
              color: AppColors.kDeepOrange,
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
