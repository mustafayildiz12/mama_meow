import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';

// GlassSegmented widget'ını kendi dosyandan import et.
enum ReportMode { today, week, month }

class DiaperReportPage extends StatefulWidget {
  const DiaperReportPage({super.key});
  @override
  State<DiaperReportPage> createState() => _DiaperReportPageState();
}

class _DiaperReportPageState extends State<DiaperReportPage> {
  ReportMode _mode = ReportMode.today;
  late Future<List<DiaperModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchByMode(_mode);
  }

  Future<List<DiaperModel>> _fetchByMode(ReportMode mode) {
    switch (mode) {
      case ReportMode.today:
        return diaperService.todayDiapers();
      case ReportMode.week:
        return diaperService.weekDiapers();
      case ReportMode.month:
        return diaperService.monthDiapers();
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
            "🚼  Diaper Reports",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        
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
                child: FutureBuilder<List<DiaperModel>>(
                  future: _future,
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
                        title: 'No record found',
                        subtitle:
                            "You'll see it here when you add a diaper change for this period.",
                      );
                    }
                    return _buildReportBody(context, diapers);
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
  Widget _buildReportBody(BuildContext context, List<DiaperModel> diapers) {
    final byHourRaw = <int, int>{}; // 0..23 -> count
    final byType = <String, int>{}; // wet/dirty/mixed/pee/poop/other

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

    // Son değişim saati
    String lastChange = '-';
    if (sortedByTime.isNotEmpty) {
      final dt = DateTime.tryParse(sortedByTime.last.createdAt);
      lastChange = dt != null
          ? DateFormat('HH:mm').format(dt)
          : sortedByTime.last.diaperTime;
    }

    // Ortalama ve max aralık (dakika)
    final gaps = _computeGapsInMinutes(sortedByTime);
    final avgGapMin = gaps.isEmpty
        ? 0
        : (gaps.reduce((a, b) => a + b) / gaps.length).round();
    final maxGapMin = gaps.isEmpty ? 0 : gaps.reduce((a, b) => a > b ? a : b);

    // Dağılımlar
    for (final d in diapers) {
      final h = _hourFromRecord(d);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

      final typeKey = _typeKey(_normalize(d.diaperName));
      byType[typeKey] = (byType[typeKey] ?? 0) + 1;
    }

    final byHour = <_KV>[];
    for (int h = 0; h < 24; h++) {
      byHour.add(_KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)));
    }
    final byTypeList = byType.entries.map((e) => _KV(e.key, e.value)).toList()
      ..sort((a, b) => b.v.compareTo(a.v));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeaderCard(
          dateLabel: _rangeLabel(_mode),
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
                  pointColorMapper: (datum, index) => Color(0xFF059669),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
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
              series: <CircularSeries<_KV, String>>[
                PieSeries<_KV, String>(
                  dataSource: byTypeList,
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
          title: "Timeline",
          subtitle: "Chronological diaper changes for ${_rangeLabel(_mode)}",
          child: Column(
            children: [
              for (final d in sortedByTime)
                _TimelineTile(time: _bestTime(d), label: d.diaperName),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Helpers ----
  int _hourFromRecord(DiaperModel d) {
    final dt = DateTime.tryParse(d.createdAt);
    if (dt != null) return dt.hour;
    final hh = int.tryParse(d.diaperTime.split(':').first);
    return (hh == null || hh < 0 || hh > 23) ? 0 : hh;
  }

  String _bestTime(DiaperModel d) {
    final dt = DateTime.tryParse(d.createdAt);
    return dt != null ? DateFormat('HH:mm').format(dt) : d.diaperTime;
  }

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
    if (name.contains('pee')) return 'pee';
    if (name.contains('poo') || name.contains('poop') || name.contains('dirty'))
      return 'poop';
    if (name.contains('mixed')) return 'mixed';
    if (name.contains('wet')) return 'wet';
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

class _KV {
  final String k;
  final int v;
  _KV(this.k, this.v);
}

// ---- UI PARTIALS (senin stilde) ----

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

  const _SectionCard({
    required this.title,
    required this.child,
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
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      title: "Range • $dateLabel",
      subtitle: "Summary of diaper changes",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: total),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _StatTile(title: "Avg", value: avgGap),
          ),
          const SizedBox(width: 2),
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
      height: 86,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
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
              color: Color(0xFFA8E6CF),
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
