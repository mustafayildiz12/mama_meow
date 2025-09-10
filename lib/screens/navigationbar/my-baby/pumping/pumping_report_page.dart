import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';

class PumpingReportPage extends StatefulWidget {
  const PumpingReportPage({super.key});

  @override
  State<PumpingReportPage> createState() => _PumpingReportPageState();
}

class _PumpingReportPageState extends State<PumpingReportPage> {
  late Future<List<PumpingModel>> _futureToday;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodayPumpings();
  }

  Future<void> _refresh() async {
    setState(() => _futureToday = _fetchTodayPumpings());
    await _futureToday;
  }

  Future<List<PumpingModel>> _fetchTodayPumpings() async {
    // Servis metodu ismini getPumpingList yapmanı öneririm
    final all = await pumpingService.getDiaperList();

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    // createdAt ISO-8601 → sadece bugünküleri al
    return all.where((p) {
      final dt = DateTime.tryParse(p.createdAt);
      if (dt == null) return false;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      return key == todayKey;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.kLightOrange,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.kLightOrange,
        title: const Text("Today's Pumping Report"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PumpingModel>>(
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
            final pumpings = snapshot.data ?? [];
            if (pumpings.isEmpty) {
              return const _CenteredMessage(
                emoji: '🍼',
                title: 'No pumping sessions today',
                subtitle: 'Log a session to see insights here.',
              );
            }

            // ---- Aggregations ----
            final totalMinutes = pumpings.fold<int>(
              0,
              (sum, p) => sum + (p.duration),
            );
            final sessionCount = pumpings.length;
            final avgMinutes = sessionCount == 0
                ? 0
                : (totalMinutes / sessionCount).round();

            // Saatlere göre toplam dakika
            final byHourRaw = <int, int>{};
            // Taraf (Left/Right) sayımı
            int leftCount = 0, rightCount = 0;

            // Kronolojik liste
            final sortedByTime = [...pumpings]
              ..sort((a, b) {
                final aDt =
                    DateTime.tryParse(a.createdAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bDt =
                    DateTime.tryParse(b.createdAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return aDt.compareTo(bDt);
              });

            // Son seansın saati
            String lastSessionTime = '-';
            if (sortedByTime.isNotEmpty) {
              final last = sortedByTime.last;
              final dt = DateTime.tryParse(last.createdAt);
              if (dt != null) {
                lastSessionTime = DateFormat('HH:mm').format(dt);
              } else {
                lastSessionTime = last.startTime; // fallback
              }
            }

            for (final p in pumpings) {
              // by hour (createdAt var → 0..23)
              final h = _hourFromRecord(p);
              byHourRaw[h] = (byHourRaw[h] ?? 0) + p.duration;

              // side
              if (p.isLeft) {
                leftCount++;
              } else {
                rightCount++;
              }
            }

            // 0..23 eksiksiz
            final byHour = <_KV>[];
            for (int h = 0; h < 24; h++) {
              byHour.add(_KV(h.toString().padLeft(2, '0'), byHourRaw[h] ?? 0));
            }

            // En uzun seanslar
            final longest = <_PumpingWithDur>[];
            for (final p in pumpings) {
              longest.add(_PumpingWithDur(p, p.duration));
            }
            longest.sort((a, b) => b.minutes.compareTo(a.minutes));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _HeaderCard(
                  dateLabel: todayStr,
                  total: _fmtMin(totalMinutes),
                  sessions: sessionCount,
                  avg: _fmtMin(avgMinutes),
                  lastSessionTime: lastSessionTime,
                ),
                const SizedBox(height: 16),

                _SectionCard(
                  title: "Distribution by hour",
                  subtitle: "Sum of minutes per start hour (00–23)",
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
                        ColumnSeries<_KV, String>(
                          dataSource: byHour,
                          xValueMapper: (e, _) => e.k,
                          yValueMapper: (e, _) => e.v,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                          dataLabelMapper: (e, _) =>
                              e.v == 0 ? "" : _fmtMin(e.v),
                          name: 'Minutes',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _SectionCard(
                  title: "Side distribution",
                  subtitle: "Left vs Right",
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
                          dataSource: [
                            _KV('Left', leftCount),
                            _KV('Right', rightCount),
                          ],
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
                  title: "Longest sessions",
                  subtitle: "Top 5 by duration",
                  child: Column(
                    children: [
                      for (final e in longest.take(5))
                        _TopSessionTile(
                          label: _bestLabel(e.model),
                          minutes: e.minutes,
                          ratio: longest.isEmpty
                              ? 0
                              : (e.minutes / longest.first.minutes),
                          isLeft: e.model.isLeft,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Helpers ----

  int _hourFromRecord(PumpingModel p) {
    final dt = DateTime.tryParse(p.createdAt);
    if (dt != null) return dt.hour;
    final hh = int.tryParse(p.startTime.split(':').first);
    return (hh == null || hh < 0 || hh > 23) ? 0 : hh;
  }

  String _bestTime(PumpingModel p) {
    final dt = DateTime.tryParse(p.createdAt);
    if (dt != null) return DateFormat('HH:mm').format(dt);
    return p.startTime;
  }

  String _bestLabel(PumpingModel p) {
    final time = _bestTime(p);
    return "$time ";
  }

  String _fmtMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

class _PumpingWithDur {
  final PumpingModel model;
  final int minutes;
  _PumpingWithDur(this.model, this.minutes);
}

/// ---- UI PARTIALS (diğer raporlarla aynı stiller) ----

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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
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

class _HeaderCard extends StatelessWidget {
  final String dateLabel;
  final String total; // "xh ym"
  final int sessions;
  final String avg; // "xh ym"
  final String lastSessionTime;

  const _HeaderCard({
    required this.dateLabel,
    required this.total,
    required this.sessions,
    required this.avg,
    required this.lastSessionTime,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Today • $dateLabel",
      subtitle: "Summary of pumping",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: total),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Sessions", value: "$sessions"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Avg", value: avg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Last", value: lastSessionTime),
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

          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.kDeepOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSessionTile extends StatelessWidget {
  final String label;
  final int minutes;
  final double ratio;
  final bool isLeft;

  const _TopSessionTile({
    required this.label,
    required this.minutes,
    required this.ratio,
    required this.isLeft,
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
          // side badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isLeft ? Colors.blue : Colors.purple).withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isLeft ? Colors.blue : Colors.purple).withOpacity(0.2),
              ),
            ),
            child: Text(
              isLeft ? "Left" : "Right",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
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
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}
