import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';

class NursingReportPage extends StatefulWidget {
  const NursingReportPage({super.key});

  @override
  State<NursingReportPage> createState() => _NursingReportPageState();
}

class _NursingReportPageState extends State<NursingReportPage> {
  late Future<List<NursingModel>> _futureToday;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodayNursings();
  }

  Future<void> _refresh() async {
    setState(() => _futureToday = _fetchTodayNursings());
    await _futureToday;
  }

  Future<List<NursingModel>> _fetchTodayNursings() async {
    final all = await nursingService.getNursingList();

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final result = <NursingModel>[];
    for (final nursing in all) {
      final datePart = _safeDatePart(nursing.createdAt);
      if (datePart == todayKey) {
        result.add(nursing);
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
          colors: [Colors.green.shade100, Colors.teal.shade200],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text("Today's Nursing Report"),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<NursingModel>>(
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
              final nursings = snapshot.data ?? [];
              if (nursings.isEmpty) {
                return const _CenteredMessage(
                  emoji: '🍼',
                  title: 'No nursing records today',
                  subtitle: 'Log a nursing session to see insights here.',
                );
              }

              // ---- Aggregate ----
              final byHourRaw = <int, int>{}; // 0..23 -> count
              final bySide = <String, int>{}; // side -> count
              final byFeedingType = <String, int>{}; // feeding type -> count
              final byMilkType = <String, int>{}; // milk type -> count (for bottles)
              final byAmountType = <String, double>{}; // amount type -> total amount
              final nursingDetails = <_NursingDetail>[];

              String? lastNursingTime;
              DateTime? latestTime;
              int totalDuration = 0;

              for (final nursing in nursings) {
                // Parse hour from startTime
                final h = _parseHourSafe(nursing.startTime);
                byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

                // Count by side
                final side = _normalizeLabel(nursing.side);
                bySide[side] = (bySide[side] ?? 0) + 1;

                // Count by feeding type
                final feedingType = _normalizeLabel(nursing.feedingType);
                byFeedingType[feedingType] = (byFeedingType[feedingType] ?? 0) + 1;

                // Count by milk type (only for bottles)
                if (nursing.milkType != null) {
                  final milkType = _normalizeLabel(nursing.milkType!);
                  byMilkType[milkType] = (byMilkType[milkType] ?? 0) + 1;
                }

                // Sum by amount type
                final amountKey = nursing.amountType;
                byAmountType[amountKey] = (byAmountType[amountKey] ?? 0) + nursing.amount;

                // Total duration
                totalDuration += nursing.duration;

                // Nursing details for list
                nursingDetails.add(_NursingDetail(
                  side: nursing.side,
                  feedingType: nursing.feedingType,
                  milkType: nursing.milkType,
                  time: nursing.startTime,
                  duration: nursing.duration,
                  amount: nursing.amount,
                  amountType: nursing.amountType,
                  createdAt: nursing.createdAt,
                ));

                // Find latest nursing time
                final nursingTime = _parseDateTime(nursing.createdAt);
                if (nursingTime != null && (latestTime == null || nursingTime.isAfter(latestTime))) {
                  latestTime = nursingTime;
                  lastNursingTime = nursing.startTime;
                }
              }

              final totalNursings = nursings.length;
              final avgDuration = totalNursings == 0 ? 0 : (totalDuration / totalNursings).round();

              // Sort nursing details by time
              nursingDetails.sort((a, b) {
                final aTime = _parseTime(a.time);
                final bTime = _parseTime(b.time);
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return aTime.compareTo(bTime);
              });

              // Prepare chart data
              final byHour = <_KV>[];
              for (int h = 0; h < 24; h++) {
                byHour.add(_KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)));
              }

              final sideList = bySide.entries
                  .map((e) => _KV(e.key, e.value))
                  .toList()
                ..sort((a, b) => b.v.compareTo(a.v));

              final feedingTypeList = byFeedingType.entries
                  .map((e) => _KV(e.key, e.value))
                  .toList()
                ..sort((a, b) => b.v.compareTo(a.v));

              final milkTypeList = byMilkType.entries
                  .map((e) => _KV(e.key, e.value))
                  .toList()
                ..sort((a, b) => b.v.compareTo(a.v));

              final amountTypeList = byAmountType.entries
                  .map((e) => _AmountKV(e.key, e.value))
                  .toList()
                ..sort((a, b) => b.v.compareTo(a.v));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _HeaderCard(
                    dateLabel: todayStr,
                    total: totalNursings,
                    totalDuration: totalDuration,
                    avgDuration: avgDuration,
                    lastTime: lastNursingTime ?? '-',
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: "Distribution by hour",
                    subtitle: "When nursing sessions occurred",
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
                          ColumnSeries<_KV, String>(
                            dataSource: byHour,
                            xValueMapper: (e, _) => e.k,
                            yValueMapper: (e, _) => e.v,
                            dataLabelMapper: (e, _) => e.v == 0 ? "" : e.v.toString(),
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                            color: Colors.teal,
                            name: 'Count',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: "Side preference",
                    subtitle: "Distribution by nursing side",
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
                            dataSource: sideList,
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
                    title: "Feeding types",
                    subtitle: "Nursing vs bottle feeding",
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
                            dataSource: feedingTypeList,
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

                  if (milkTypeList.isNotEmpty) ...[
                    _SectionCard(
                      title: "Milk types",
                      subtitle: "Types of milk for bottle feeding",
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
                              dataSource: milkTypeList,
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
                  ],

                  if (amountTypeList.isNotEmpty) ...[
                    _SectionCard(
                      title: "Amount by type",
                      subtitle: "Total amounts by unit type",
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
                            BarSeries<_AmountKV, String>(
                              dataSource: amountTypeList,
                              xValueMapper: (e, _) => e.k,
                              yValueMapper: (e, _) => e.v,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                              ),
                              name: 'Amount',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _SectionCard(
                    title: "Today's nursing sessions",
                    subtitle: "Chronological list",
                    child: Column(
                      children: [
                        for (final detail in nursingDetails)
                          _NursingTile(
                            side: detail.side,
                            feedingType: detail.feedingType,
                            milkType: detail.milkType,
                            time: detail.time,
                            duration: detail.duration,
                            amount: detail.amount,
                            amountType: detail.amountType,
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

  String _safeDatePart(String createdAt) {
    // Expected format: ISO string
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (_) {
      return createdAt.split('T').first;
    }
  }

  int _parseHourSafe(String hhmm) {
    final h = int.tryParse(hhmm.split(':').first);
    return (h == null || h < 0 || h > 23) ? 0 : h;
  }

  DateTime? _parseDateTime(String createdAt) {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(2000, 1, 1, hour, minute); // Use dummy date for comparison
    } catch (_) {
      return null;
    }
  }

  String _normalizeLabel(String s) {
    return s.trim().toLowerCase();
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}min";
    if (m == 0) return "${h}h";
    return "${h}h ${m}min";
  }
}

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

class _AmountKV {
  final String k;
  final double v;
  _AmountKV(this.k, this.v);
}

class _NursingDetail {
  final String side;
  final String feedingType;
  final String? milkType;
  final String time;
  final int duration;
  final double amount;
  final String amountType;
  final String createdAt;

  _NursingDetail({
    required this.side,
    required this.feedingType,
    this.milkType,
    required this.time,
    required this.duration,
    required this.amount,
    required this.amountType,
    required this.createdAt,
  });
}

/// ---- UI FRAGMENTS ----

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
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
  final int total;
  final int totalDuration;
  final int avgDuration;
  final String lastTime;

  const _HeaderCard({
    required this.dateLabel,
    required this.total,
    required this.totalDuration,
    required this.avgDuration,
    required this.lastTime,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Today • $dateLabel",
      subtitle: "Summary of nursing",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Sessions", value: "$total"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Total", value: _formatDuration(totalDuration)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Avg", value: _formatDuration(avgDuration)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Last", value: lastTime),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "${m}min";
    if (m == 0) return "${h}h";
    return "${h}h ${m}min";
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.black54,
            ),
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
                  color: Colors.teal,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
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

class _NursingTile extends StatelessWidget {
  final String side;
  final String feedingType;
  final String? milkType;
  final String time;
  final int duration;
  final double amount;
  final String amountType;

  const _NursingTile({
    required this.side,
    required this.feedingType,
    this.milkType,
    required this.time,
    required this.duration,
    required this.amount,
    required this.amountType,
  });

  @override
  Widget build(BuildContext context) {
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
              feedingType.toLowerCase() == 'nursing' ? Icons.child_care : Icons.local_drink,
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
                  '${feedingType.toUpperCase()} - ${side.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${duration}min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    if (amount > 0) ...[
                      const Text(' • '),
                      Text(
                        '${amount.toStringAsFixed(1)} $amountType',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    if (milkType != null) ...[
                      const Text(' • '),
                      Text(
                        milkType!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}