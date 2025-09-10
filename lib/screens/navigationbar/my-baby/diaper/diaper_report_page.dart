import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';

class DiaperReportPage extends StatefulWidget {
  const DiaperReportPage({super.key});

  @override
  State<DiaperReportPage> createState() => _DiaperReportPageState();
}

class _DiaperReportPageState extends State<DiaperReportPage> {
  late Future<List<DiaperModel>> _futureToday;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodayDiapers();
  }

  Future<void> _refresh() async {
    setState(() => _futureToday = _fetchTodayDiapers());
    await _futureToday;
  }

  Future<List<DiaperModel>> _fetchTodayDiapers() async {
    final all = await diaperService.getDiaperList();

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    // createdAt ISO-8601 → sadece bugünküleri al
    return all.where((d) {
      final dt = DateTime.tryParse(d.createdAt);
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
        title: const Text("Today's Diaper Report"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DiaperModel>>(
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
            final diapers = snapshot.data ?? [];
            if (diapers.isEmpty) {
              return const _CenteredMessage(
                emoji: '🧷',
                title: 'No diaper changes today',
                subtitle: 'Log a diaper change to see insights here.',
              );
            }

            // ---- Aggregations ----
            // Saat dağılımı (0..23)
            final byHourRaw = <int, int>{}; // 0..23 -> count
            // Tip dağılımı
            final byType = <String, int>{}; // wet/dirty/mixed/other
            // Zaman çizelgesi için sıralı liste
            final sortedByTime = [...diapers]
              ..sort((a, b) {
                final aDt =
                    DateTime.tryParse(a.createdAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bDt =
                    DateTime.tryParse(b.createdAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return aDt.compareTo(bDt);
              });

            // Son değiştirme saati
            String lastChange = '-';
            if (sortedByTime.isNotEmpty) {
              final last = sortedByTime.last;
              final dt = DateTime.tryParse(last.createdAt);
              if (dt != null) {
                lastChange = DateFormat('HH:mm').format(dt);
              } else {
                // fallback: diaperTime
                lastChange = last.diaperTime;
              }
            }

            // Ortalama ve en uzun aralık (dakika)
            final gaps = _computeGapsInMinutes(sortedByTime);
            final avgGapMin = gaps.isEmpty
                ? 0
                : (gaps.reduce((a, b) => a + b) / gaps.length).round();
            final maxGapMin = gaps.isEmpty
                ? 0
                : gaps.reduce((a, b) => a > b ? a : b);

            for (final d in diapers) {
              final h = _hourFromRecord(d);
              byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

              final name = _normalize(d.diaperName);
              final typeKey = _typeKey(name);
              byType[typeKey] = (byType[typeKey] ?? 0) + 1;
            }

            // Saat 0..23 eksiksiz ve sıralı
            final byHour = <_KV>[];
            for (int h = 0; h < 24; h++) {
              byHour.add(
                _KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)),
              );
            }

            // Tip listesi
            final byTypeList =
                byType.entries.map((e) => _KV(e.key, e.value)).toList()
                  ..sort((a, b) => b.v.compareTo(a.v));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _HeaderCard(
                  dateLabel: todayStr,
                  total: diapers.length.toString(),
                  lastChange: lastChange,
                  avgGap: _fmtMin(avgGapMin),
                  maxGap: _fmtMin(maxGapMin),
                ),
                const SizedBox(height: 16),

                _SectionCard(
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
                        ColumnSeries<_KV, String>(
                          dataSource: byHour,
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
                  title: "By diaper type",
                  subtitle: "wet / dirty / mixed / poo / pee",
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
                          dataSource: byTypeList,
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
                  title: "Timeline",
                  subtitle: "Chronological diaper changes",
                  child: Column(
                    children: [
                      for (final d in sortedByTime)
                        _TimelineTile(time: _bestTime(d), label: d.diaperName),
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

  int _hourFromRecord(DiaperModel d) {
    // Öncelik createdAt (ISO), yoksa diaperTime "HH:mm"
    final dt = DateTime.tryParse(d.createdAt);
    if (dt != null) return dt.hour;
    final hh = int.tryParse(d.diaperTime.split(':').first);
    return (hh == null || hh < 0 || hh > 23) ? 0 : hh;
  }

  String _bestTime(DiaperModel d) {
    final dt = DateTime.tryParse(d.createdAt);
    if (dt != null) return DateFormat('HH:mm').format(dt);
    return d.diaperTime;
  }

  // Değişimler arası boşluklar (dakika)
  List<int> _computeGapsInMinutes(List<DiaperModel> sorted) {
    final out = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.tryParse(sorted[i - 1].createdAt);
      final cur = DateTime.tryParse(sorted[i].createdAt);
      if (prev != null && cur != null) {
        out.add(cur.difference(prev).inMinutes.abs());
      }
    }
    return out;
  }

  String _normalize(String s) => s.trim().toLowerCase();

  String _typeKey(String name) {
    if (name.contains('pee')) return "pee";
    if (name.contains('poo')) return "poop";
    if (name.contains('mixed')) return 'mixed';
     if (name.contains('dry')) return 'dry';
    return 'other';
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

/// Key-Value yardımcı model
class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

/// ---- UI PARTIALS (Solid/Sleep ile aynı stil) ----

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
  final String total; // total diaper count
  final String lastChange;
  final String avgGap; // average gap
  final String maxGap; // longest gap

  const _HeaderCard({
    required this.dateLabel,
    required this.total,
    required this.lastChange,
    required this.avgGap,
    required this.maxGap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Today • $dateLabel",
      subtitle: "Summary of diaper changes",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: total),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Last change", value: lastChange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Avg interval", value: avgGap),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Longest", value: maxGap),
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

class _TimelineTile extends StatelessWidget {
  final String time;
  final String label;
  const _TimelineTile({required this.time, required this.label});

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
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.kDeepOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
