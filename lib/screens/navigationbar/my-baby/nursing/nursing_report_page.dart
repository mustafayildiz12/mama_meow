import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
// GlassSegmented widget'ını senin paylaştığın yerden import et.

enum ReportMode { today, week, month }

class NursingReportPage extends StatefulWidget {
  const NursingReportPage({super.key});

  @override
  State<NursingReportPage> createState() => _NursingReportPageState();
}

class _NursingReportPageState extends State<NursingReportPage> {
  ReportMode _mode = ReportMode.today;
  late Future<List<NursingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchByMode(_mode);
  }

  Future<List<NursingModel>> _fetchByMode(ReportMode mode) {
    switch (mode) {
      case ReportMode.today:
        return nursingService.todayNursings();
      case ReportMode.week:
        return nursingService.weekNursings();
      case ReportMode.month:
        return nursingService.monthNursings();
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchByMode(_mode));
    await _future;
  }

  String _rangeLabel(ReportMode mode) {
    final now = DateTime.now();
    if (mode == ReportMode.today) {
      return DateFormat('EEEE, d MMM').format(now);
    } else if (mode == ReportMode.week) {
      final s = now.startOfWeekTR, e = now.endOfWeekTR;
      return "${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM').format(e)}";
    } else {
      final s = now.startOfMonth, e = now.endOfMonth;
      return "${DateFormat('MMM yyyy').format(s)} (1–${DateFormat('d').format(e)})";
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
            "🍼  Nursing Reports",
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
                    onChanged: (m) => setState(() {
                      _mode = m;
                      _future = _fetchByMode(_mode);
                    }),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<NursingModel>>(
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
                    final nursings = snapshot.data ?? [];
                    if (nursings.isEmpty) {
                      return const _CenteredMessage(
                        emoji: '🍼',
                        title: 'Kayıt bulunamadı',
                        subtitle:
                            'Bu aralık için emzirme eklediğinde burada göreceksin.',
                      );
                    }
                    return _buildReportBody(context, nursings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili aralığa uygulanır) ----
  Widget _buildReportBody(BuildContext context, List<NursingModel> nursings) {
    final byHourRaw = <int, int>{}; // 0..23 -> count
    final bySide = <String, int>{}; // side -> count
    final byFeedingType = <String, int>{}; // feeding type -> count
    final byMilkType = <String, int>{}; // bottle milk type -> count
    final byAmountType = <String, double>{}; // unit -> total amount

    final details = <_NursingDetail>[];
    String lastTimeLabel = '-';
    DateTime? latest;

    int totalDuration = 0;

    for (final n in nursings) {
      // saat dağılımı (startTime "HH:mm")
      final h = _parseHourSafe(n.startTime);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

      // side / feedingType
      bySide[_normalize(n.side)] = (bySide[_normalize(n.side)] ?? 0) + 1;
      byFeedingType[_normalize(n.feedingType)] =
          (byFeedingType[_normalize(n.feedingType)] ?? 0) + 1;

      // milkType (şişe için)
      if (n.milkType != null) {
        byMilkType[_normalize(n.milkType!)] =
            (byMilkType[_normalize(n.milkType!)] ?? 0) + 1;
      }

      // amountType toplam
      byAmountType[n.amountType] = (byAmountType[n.amountType] ?? 0) + n.amount;

      // süre
      totalDuration += n.duration;

      // detay listesi
      details.add(
        _NursingDetail(
          side: n.side,
          feedingType: n.feedingType,
          milkType: n.milkType,
          time: n.startTime,
          duration: n.duration,
          amount: n.amount,
          amountType: n.amountType,
          createdAt: n.createdAt,
        ),
      );

      // son emzirme
      final ct = _tryParseDateTime(n.createdAt);
      if (ct != null && (latest == null || ct.isAfter(latest))) {
        latest = ct;
        lastTimeLabel = n.startTime;
      }
    }

    final total = nursings.length;
    final avgDuration = total == 0 ? 0 : (totalDuration / total).round();

    // kronolojik detay
    details.sort((a, b) {
      final at = _parseTime(a.time), bt = _parseTime(b.time);
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });

    // grafik veri
    final byHour = <_KV>[];
    for (int h = 0; h < 24; h++) {
      byHour.add(_KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)));
    }
    final sideList = bySide.entries.map((e) => _KV(e.key, e.value)).toList()
      ..sort((a, b) => b.v.compareTo(a.v));
    final feedingTypeList =
        byFeedingType.entries.map((e) => _KV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));
    final milkTypeList =
        byMilkType.entries.map((e) => _KV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));
    final amountTypeList =
        byAmountType.entries.map((e) => _AmountKV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const SizedBox(height: 16),

        _SectionCard(
          title: "Distribution by hour",
          subtitle: "When nursing sessions occurred",
          leading: "🤱",
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
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  pointColorMapper: (e, _) => byHourColor(e.v),
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
          leading: "⏱️",
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
                  pointColorMapper: (e, _) => sideChartColor(e.v),
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
          title: "Feeding types",
          subtitle: "Nursing vs bottle feeding",
          leading: "🍼",
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
                  pointColorMapper: (e, _) => feedingTypesColor(e.v),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
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
            leading: "🐄",
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
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
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
            leading: "🥛",
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
                    pointColorMapper: (datum, index) {
                      if (index == 0) {
                        return Colors.pinkAccent;
                      } else {
                        return Colors.teal;
                      }
                    },
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    name: 'Amount',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        _SectionCard(
          title: "Sessions",
          subtitle: "Chronological list for ${_rangeLabel(_mode)}",
          leading: "⏱️",
          child: Column(
            children: [
              for (final d in details)
                _NursingTile(
                  side: d.side,
                  feedingType: d.feedingType,
                  milkType: d.milkType,
                  time: d.time,
                  duration: d.duration,
                  amount: d.amount,
                  amountType: d.amountType,
                ),
            ],
          ),
        ),
        SizedBox(height: 16),
        nursingTips(),
      ],
    );
  }

  Widget nursingTips() {
    return _SectionCard(
      title: "AI Nursing Tips",
      leading: "🤖",
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("💡", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Your feeding intervals are very consistent. This helps establish a great routine!",
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
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("🌡️", style: TextStyle(fontSize: 20)),
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
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("💪", style: TextStyle(fontSize: 20)),
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

  Color byHourColor(int count) {
    if (count >= 2) {
      return const Color(0xFF2ECC71); // y
    } else if (count >= 1 && count < 2) {
      return const Color(0xFFFF7F50); // mercan
    } else if (count >= 0.5 && count < 1) {
      // Biraz daha parlak/aydınlık
      final base = const Color(0xFFF1C40F);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness((hsl.lightness * 1.10).clamp(0, 1)).toColor();
    } else if (count < 0.5) {
      return const Color(0xFF3498DB);
    } else {
      return Colors.teal;
    }
  }

  Color sideChartColor(int count) {
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

  Color feedingTypesColor(int count) {
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

  // ---- Helpers ----
  int _parseHourSafe(String hhmm) {
    final h = int.tryParse(hhmm.split(':').first);
    return (h == null || h < 0 || h > 23) ? 0 : h;
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final p = timeStr.split(':');
      return DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  DateTime? _tryParseDateTime(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  String _normalize(String s) => s.trim().toLowerCase();
}

// --- view models / tiles ---

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
    this.padding = const EdgeInsets.all(16),
    this.subtitle,
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
            const Color(0xFFff9aa2),
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
                  color: const Color(0xFFff9aa2),
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
              feedingType.toLowerCase() == 'nursing'
                  ? Icons.child_care
                  : Icons.local_drink,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      '${duration}min',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    if (amount > 0) ...[
                      const Text(' • '),
                      Text(
                        '${amount.toStringAsFixed(1)} $amountType',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                    if (milkType != null) ...[
                      const Text(' • '),
                      Text(
                        milkType!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
    final activeFill = const Color(0xFFff9aa2); // aktif buton zemini
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
