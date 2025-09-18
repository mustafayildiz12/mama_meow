import 'package:flutter/cupertino.dart' show CupertinoSegmentedControl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum ReportMode { today, week, month }

class SolidReportPage extends StatefulWidget {
  const SolidReportPage({super.key});

  @override
  State<SolidReportPage> createState() => _SolidReportPageState();
}

class _SolidReportPageState extends State<SolidReportPage> {
  late Future<List<SolidModel>> _futureToday;
  late Future<List<SolidModel>> _futureWeek;
  late Future<List<SolidModel>> _futureMonth;

  ReportMode _mode = ReportMode.today;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodaySolids();
    _futureWeek = _fetchWeekSolids();
    _futureMonth = _fetchMonthSolids();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade200, Colors.yellow.shade200],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leadingWidth: 36,
          title: Text(
            _mode == ReportMode.today
                ? "Today's Solid Report"
                : _mode == ReportMode.week
                ? "This Week's Solid Report"
                : "This Month's Solid Report",
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _Segmented(
                  value: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _mode == ReportMode.today
              ? todayBody()
              : _mode == ReportMode.week
              ? weeklyBody()
              : monthlyBody(),
        ),
      ),
    );
  }

  Widget monthlyBody() {
    final now = DateTime.now();
    final monthLabel = DateFormat(
      "LLLL yyyy",
      'en_US',
    ).format(now); // Örn: Eylül 2025

    return FutureBuilder<List<SolidModel>>(
      future: _futureMonth,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }
        if (snap.hasError) {
          return _CenteredMessage(
            emoji: '⚠️',
            title: 'Monthly data error',
            subtitle: snap.error.toString(),
          );
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const _CenteredMessage(
            emoji: '📅',
            title: 'No solids this month',
            subtitle: 'Add some to see monthly insights.',
          );
        }

        final series = buildMonthlyDaySeries(data, now);
        final summary = monthSummary(data);
        final foods = buildMonthlyFoodList(data);
        final int maxFood = foods.isEmpty ? 0 : foods.first.v;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionCard(
              title: "This Month • $monthLabel",
              subtitle: "Monthly summary",
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      title: "Total amount",
                      value: "${summary.totalAmount}",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      title: "Meals",
                      value: "${summary.mealCount}",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By day of month",
              subtitle: "Total amount per day (1–${now.daysInMonth})",
              child: SizedBox(
                height: 240,
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
                      dataSource: series,
                      xValueMapper: (e, _) => e.k,
                      yValueMapper: (e, _) => e.v,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: false,
                      ),
                      name: 'Amount',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By food type (month)",
              subtitle: "Totals by solid",
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
                      dataSource: foods,
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
              title: "Top foods this month",
              subtitle: "Most eaten solids",
              child: Column(
                children: [
                  for (final e in foods.take(8))
                    _TopFoodTile(
                      label: e.k,
                      value: e.v,
                      ratio: maxFood == 0 ? 0 : (e.v / maxFood),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget weeklyBody() {
    return FutureBuilder<List<SolidModel>>(
      future: _futureWeek,
      builder: (context, weekSnap) {
        if (weekSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }
        if (weekSnap.hasError) {
          return _CenteredMessage(
            emoji: '⚠️',
            title: 'Weekly data error',
            subtitle: weekSnap.error.toString(),
          );
        }

        final weekSolids = weekSnap.data ?? [];
        if (weekSolids.isEmpty) {
          return const _CenteredMessage(
            emoji: '📅',
            title: 'No solids this week',
            subtitle: 'Add some to see weekly insights.',
          );
        }

        // --- Haftalık agregasyonlar ---
        // Gün bazlı toplam miktar (Pzt..Paz = 1..7)
        final byWeekday = <int, int>{}; // 1..7 -> amount
        // Yiyecek bazlı toplam (haftalık)
        final byFoodWeek = <String, int>{};
        // Reaksiyon sayısı (haftalık)
        final byReactionWeek = <String, int>{};

        for (final s in weekSolids) {
          final created = DateTime.tryParse(s.createdAt) ?? DateTime.now();
          final wd = created.weekday; // 1..7
          final amt = int.tryParse(s.solidAmount) ?? 0;

          byWeekday[wd] = (byWeekday[wd] ?? 0) + amt;

          byFoodWeek[s.solidName] = (byFoodWeek[s.solidName] ?? 0) + amt;

          final rx = s.reactions == null
              ? "none"
              : reactionToText(s.reactions!);
          byReactionWeek[rx] = (byReactionWeek[rx] ?? 0) + 1;
        }

        // Haftanın label’ları (TR locale’de kısa adlar)
        final monday = DateTime.now().startOfWeekTR;
        final days = List.generate(7, (i) => monday.add(Duration(days: i)));

        final dayLabels = days
            .map((d) => DateFormat.E('en_EN').format(d)) // Pzt, Sal, Çar...
            .toList();

        final daySeries = <_KV>[];
        for (var i = 0; i < 7; i++) {
          final wd = days[i].weekday; // 1..7
          daySeries.add(_KV(dayLabels[i], byWeekday[wd] ?? 0));
        }

        final foodList =
            byFoodWeek.entries.map((e) => _KV(e.key, e.value)).toList()
              ..sort((a, b) => b.v.compareTo(a.v)); // çoktan aza

        final reactionList =
            byReactionWeek.entries.map((e) => _KV(e.key, e.value)).toList()
              ..sort((a, b) => b.v.compareTo(a.v));

        // Toplam/özet
        final totalWeekAmount = weekSolids.fold<int>(
          0,
          (s, e) => s + (int.tryParse(e.solidAmount) ?? 0),
        );
        final mealsWeek = weekSolids.length;

        final rangeLabel =
            "${DateFormat('d MMM', 'en_US').format(monday)} – ${DateFormat('d MMM', 'en_US').format(monday.add(const Duration(days: 6)))}";

        final int maxFood = foodList.isEmpty ? 0 : foodList.first.v;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionCard(
              title: "This Week • $rangeLabel",
              subtitle: "Weekly summary",
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      title: "Total amount",
                      value: "$totalWeekAmount",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(title: "Meals", value: "$mealsWeek"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By day of week",
              subtitle: "Total amount per day",
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
                      dataSource: daySeries,
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

            _SectionCard(
              title: "By food type (week)",
              subtitle: "Totals by solid",
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
                      dataSource: foodList,
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
              title: "Reactions (week)",
              subtitle: "Count of reactions",
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
                    BarSeries<_KV, String>(
                      dataSource: reactionList,
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
              title: "Top foods this week",
              subtitle: "Most eaten solids",
              child: Column(
                children: [
                  for (final e in foodList.take(6))
                    _TopFoodTile(
                      label: e.k,
                      value: e.v,
                      ratio: maxFood == 0 ? 0 : (e.v / maxFood),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget todayBody() {
    final todayStr = DateFormat(
      'EEEE, d MMM',
    ).format(DateTime.now()); // örn: Tuesday, 9 Sep
    return FutureBuilder<List<SolidModel>>(
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
        final solids = snapshot.data ?? [];
        if (solids.isEmpty) {
          return const _CenteredMessage(
            emoji: '🍽️',
            title: 'No solids recorded today',
            subtitle: 'Add a solid from the + button to see insights.',
          );
        }

        // --- Aggregations ---
        final totalAmount = solids.fold<int>(
          0,
          (sum, s) => sum + (int.tryParse(s.solidAmount) ?? 0),
        );
        final mealCount = solids.length;
        final lastEatTime = _findLastEatTime(solids); // "HH:mm" or "-"

        final byFood = <String, int>{};
        final byReaction = <String, int>{};
        final byHourRaw = <int, int>{}; // 0..23

        for (final s in solids) {
          final amt = int.tryParse(s.solidAmount) ?? 0;

          // food
          byFood[s.solidName] = (byFood[s.solidName] ?? 0) + amt;

          // reaction
          final rx = s.reactions == null
              ? "none"
              : reactionToText(s.reactions!);
          byReaction[rx] = (byReaction[rx] ?? 0) + 1;

          // hour
          final h = int.tryParse(s.eatTime.split(':').first) ?? 0;
          byHourRaw[h] = (byHourRaw[h] ?? 0) + amt;
        }

        // Saatleri 0..23 eksiksiz ve sıralı hale getir
        final byHour = <_KV>[];
        for (int h = 0; h < 24; h++) {
          byHour.add(_KV(h.toString().padLeft(2, '0'), byHourRaw[h] ?? 0));
        }

        // Pie için liste
        final byFoodList =
            byFood.entries.map((e) => _KV(e.key, e.value)).toList()
              ..sort((a, b) => b.v.compareTo(a.v)); // en çoktan aza

        // Reaksiyon bar için
        final byReactionList =
            byReaction.entries.map((e) => _KV(e.key, e.value)).toList()
              ..sort((a, b) => b.v.compareTo(a.v));

        // En çok yenenler (progress list)
        final int maxFood = byFoodList.isEmpty ? 0 : byFoodList.first.v;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _HeaderCard(
              dateLabel: todayStr,
              totalAmount: totalAmount,
              mealCount: mealCount,
              lastEatTime: lastEatTime,
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "Distribution by hour",
              subtitle: "When solids were eaten (00–23)",
              child: SizedBox(
                height: 220,
                child: SfCartesianChart(
                  backgroundColor: Colors.transparent,
                  primaryXAxis: CategoryAxis(
                    labelRotation: 0,
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
                      name: 'Amount',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By food type",
              subtitle: "Total amount by solid",
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
                      dataSource: byFoodList,
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
              title: "Reactions",
              subtitle: "Love it, meh, hated it, allergic/sensitivity",
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
                    BarSeries<_KV, String>(
                      dataSource: byReactionList,
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
              title: "Top foods today",
              subtitle: "Most eaten solids",
              child: Column(
                children: [
                  for (final e in byFoodList.take(6))
                    _TopFoodTile(
                      label: e.k,
                      value: e.v,
                      ratio: maxFood == 0 ? 0 : (e.v / maxFood),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Aylık veriyi gün bazında (1..daysInMonth) toplar.
  /// Dönüş: [_KV('01', 120), _KV('02', 80), ...]
  List<_KV> buildMonthlyDaySeries(
    List<SolidModel> monthSolids,
    DateTime anyDayInMonth,
  ) {
    final days = anyDayInMonth.daysInMonth;
    final totals = List<int>.filled(days, 0);

    for (final s in monthSolids) {
      final created = DateTime.tryParse(s.createdAt);
      if (created == null) continue;
      if (created.year == anyDayInMonth.year &&
          created.month == anyDayInMonth.month) {
        final d = created.day; // 1..days
        final amt = int.tryParse(s.solidAmount) ?? 0;
        totals[d - 1] += amt;
      }
    }

    return List.generate(days, (i) {
      final label = (i + 1).toString().padLeft(2, '0');
      return _KV(label, totals[i]);
    });
  }

  /// Aylık özet (toplam miktar, öğün sayısı)
  ({int totalAmount, int mealCount}) monthSummary(
    List<SolidModel> monthSolids,
  ) {
    final total = monthSolids.fold<int>(
      0,
      (s, e) => s + (int.tryParse(e.solidAmount) ?? 0),
    );
    return (totalAmount: total, mealCount: monthSolids.length);
  }

  /// Aylık yiyecek dağılımı
  List<_KV> buildMonthlyFoodList(List<SolidModel> monthSolids) {
    final byFood = <String, int>{};
    for (final s in monthSolids) {
      final amt = int.tryParse(s.solidAmount) ?? 0;
      byFood[s.solidName] = (byFood[s.solidName] ?? 0) + amt;
    }
    final list = byFood.entries.map((e) => _KV(e.key, e.value)).toList();
    list.sort((a, b) => b.v.compareTo(a.v));
    return list;
  }

  String _findLastEatTime(List<SolidModel> solids) {
    // createdAt ISO-8601 → en son eklenen
    DateTime? latest;
    String? eatTime;
    for (final s in solids) {
      final dt = DateTime.tryParse(s.createdAt);
      if (dt == null) continue;
      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
        eatTime = s.eatTime;
      }
    }
    return eatTime ?? '-';
  }

  Future<void> _refresh() async {
    setState(() {
      _futureToday = _fetchTodaySolids();
      _futureWeek = _fetchWeekSolids();
      _futureMonth = _fetchMonthSolids();
    });
    await Future.wait([_futureToday, _futureWeek]);
  }

  Future<List<SolidModel>> _fetchTodaySolids() async {
    final all = await solidService.getUserSolidList();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return all.where((s) {
      final created = DateTime.tryParse(s.createdAt);
      if (created == null) return false;
      return (created.isAtSameMomentAs(start) || created.isAfter(start)) &&
          (created.isBefore(end) || created.isAtSameMomentAs(end));
    }).toList();
  }

  /// HAFTALIK: Pazartesi–Pazar (TR) aralığını çek
  Future<List<SolidModel>> _fetchWeekSolids() async {
    final now = DateTime.now();
    final start = now.startOfWeekTR;
    final end = now.endOfWeekTR;

    // Range query ile sadece gerekli haftayı çekiyoruz
    return await solidService.getUserSolidsInRange(start, end);
  }

  Future<List<SolidModel>> _fetchMonthSolids() async {
    final now = DateTime.now();
    final start = now.startOfMonth;
    final end = now.endOfMonth;
    return await solidService.getUserSolidsInRange(start, end);
  }
}

// Ayrı, küçük bir segmented bileşeni:
class _Segmented extends StatelessWidget {
  final ReportMode value;
  final ValueChanged<ReportMode> onChanged;

  const _Segmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSegmentedControl<ReportMode>(
      groupValue: value,
      onValueChanged: onChanged,
      padding: const EdgeInsets.all(2),
      children: const {
        ReportMode.today: Padding(
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Text('Today', style: TextStyle(fontSize: 12)),
        ),
        ReportMode.week: Padding(
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Text('Week', style: TextStyle(fontSize: 12)),
        ),
        ReportMode.month: Padding(
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Text('Month', style: TextStyle(fontSize: 12)),
        ),
      },
    );
  }
}

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

/// ---- UI PARTIALS ----

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
  final int totalAmount;
  final int mealCount;
  final String lastEatTime;

  const _HeaderCard({
    required this.dateLabel,
    required this.totalAmount,
    required this.mealCount,
    required this.lastEatTime,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Today • $dateLabel",
      subtitle: "Summary of solids",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total amount", value: "$totalAmount"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(title: "Meals", value: "$mealCount"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(title: "Last time", value: lastEatTime),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.kDeepOrange,
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

class _TopFoodTile extends StatelessWidget {
  final String label;
  final int value;
  final double ratio;
  const _TopFoodTile({
    required this.label,
    required this.value,
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
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
            "$value",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.kDeepOrange,
            ),
          ),
        ],
      ),
    );
  }
}
