import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC), // #f8fafc
            Color(0xFFF1F5F9),
          ],
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
              onTap: () {
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios),
              ),
            ),
          ),
          title: Text(
            "🥄   Food Reports",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
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
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
              ),
              Expanded(
                child: _mode == ReportMode.today
                    ? todayBody()
                    : _mode == ReportMode.week
                    ? weeklyBody()
                    : monthlyBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget nutritionTips() {
    return _SectionCard(
      title: "AI Nutrition Tips",
      leading: "🤖",
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("💡", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Excellent variety! Try introducing more finger foods to develop fine motor skills",
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("🌟", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Your baby seems to love sweet foods. Gradually mix in vegetables for balanced taste",
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("🍽️", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Consider iron-rich foods like spinach or lentils - perfect age for this nutrition!",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget monthlyBody() {
    final now = DateTime.now();

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
              title: "Feeding Overview",
              subtitle: "",
              leading: "🍽️",
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
              leading: "🌈",
              subtitle: "Total amount per day (1–${now.daysInMonth})",
              child: SizedBox(
                height: 240,
                child: FoodChartCard(series: series),
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By food type (month)",
              subtitle: "Totals by solid",
              leading: "🎯",
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
              leading: "⏰",
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
            const SizedBox(height: 16),
            nutritionTips(),
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

        final int maxFood = foodList.isEmpty ? 0 : foodList.first.v;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionCard(
              title: "Feeding Overview",
              subtitle: "",
              leading: "🍽️",
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
              leading: "🌈",
              child: SizedBox(
                height: 220,
                child: FoodChartCard(series: daySeries),
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: "By food type (week)",
              subtitle: "Totals by solid",
              leading: "🎯",
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
              leading: "😋",
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
              leading: "⏰",
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
              leading: "⏰",
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
              leading: "🎯",
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
              leading: "😋",
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
              leading: "⏰",
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
    final bgColor = Colors.white.withValues(
      alpha: 0.8,
    ); // rgba(255,255,255,0.8)
    final borderColor = Colors.white.withValues(
      alpha: 0.3,
    ); // rgba(255,255,255,0.3)
    final activeFill = const Color(0xFFA8E6CF); // aktif buton zemini
    final inactiveFg = theme.textTheme.bodyMedium?.color; // pasif buton yazısı
    final activeFg = Colors.white.withValues(alpha: 0.9); // aktif buton yazısı

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

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

class FoodChartCard extends StatelessWidget {
  final List<_KV> series;
  const FoodChartCard({super.key, required this.series});

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
    if (count >= 20) {
      return const Color(0xFF2ECC71); // y
    } else if (count >= 10 && count < 20) {
      return const Color(0xFFFF7F50); // mercan
    } else if (count >= 5 && count < 10) {
      // Biraz daha parlak/aydınlık
      final base = const Color(0xFFF1C40F);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness((hsl.lightness * 1.10).clamp(0, 1)).toColor();
    } else if (count < 5) {
      return const Color(0xFF3498DB);
    } else {
      return Colors.teal;
    }
  }
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
      subtitle: "",
      leading: "🍽️",
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
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
    required this.leading,
    this.subtitle,

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
            const Color(0xFFA8E6CF),
            Colors.white.withValues(alpha: 0.9),
          ],
          stops: const [0.2, 1.0], // %20'de yeşil, %100'de beyaz
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
                  color: const Color(0xFF88d8c0),
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
                    backgroundColor: const Color(
                      0xFFA8E6CF,
                    ).withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFA8E6CF),
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
              color: const Color(0xFFA8E6CF),
            ),
          ),
        ],
      ),
    );
  }
}
