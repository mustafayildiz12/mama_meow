import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';

// GlassSegmented'i kendi dosyandan import et.
enum ReportMode { today, week, month }

class MedicineReportPage extends StatefulWidget {
  const MedicineReportPage({super.key});
  @override
  State<MedicineReportPage> createState() => _MedicineReportPageState();
}

class _MedicineReportPageState extends State<MedicineReportPage> {
  ReportMode _mode = ReportMode.today;
  late Future<List<MedicineModel>> _future;

  @override
  void initState() {
    _future = _fetchByMode(_mode);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF8FAFC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  Future<List<MedicineModel>> _fetchByMode(ReportMode mode) {
    switch (mode) {
      case ReportMode.today:
        return medicineService.todayMedicines();
      case ReportMode.week:
        return medicineService.weekMedicines();
      case ReportMode.month:
        return medicineService.monthMedicines();
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
            "💊  Medicine Reports",
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
                child: FutureBuilder<List<MedicineModel>>(
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
                    final medicines = snapshot.data ?? [];
                    if (medicines.isEmpty) {
                      return const _CenteredMessage(
                        emoji: '💊',
                        title: 'No record found',
                        subtitle:
                            'You will see it here when you add medication for this period.',
                      );
                    }
                    return _buildReportBody(context, medicines);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili tarih aralığı) ----
  Widget _buildReportBody(BuildContext context, List<MedicineModel> medicines) {
    final byHourRaw = <int, int>{}; // 0..23 -> count
    final byMedicine = <String, int>{}; // ilac adı -> count
    final byAmountType = <String, double>{}; // birim -> toplam miktar
    final details = <_MedicineDetail>[];

    String lastTime = '-';
    DateTime? latest;

    for (final m in medicines) {
      // saat (startTime "HH:mm" tercih; yoksa createdAt)
      final h = _parseHourSafe(m.startTime, createdAt: m.createdAt);
      byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

      final nameKey = _normalize(m.medicineName);
      byMedicine[nameKey] = (byMedicine[nameKey] ?? 0) + 1;

      byAmountType[m.amountType] = (byAmountType[m.amountType] ?? 0) + m.amount;

      details.add(
        _MedicineDetail(
          name: m.medicineName,
          time: _bestTime(m),
          amount: m.amount,
          amountType: m.amountType,
          createdAt: m.createdAt,
        ),
      );

      final ct = _tryParseDateTime(m.createdAt);
      if (ct != null && (latest == null || ct.isAfter(latest))) {
        latest = ct;
        lastTime = _bestTime(m);
      }
    }

    final total = medicines.length;
    final unique = byMedicine.keys.length;

    details.sort((a, b) {
      final at = _parseTime(a.time), bt = _parseTime(b.time);
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });

    final byHour = <_KV>[];
    for (int h = 0; h < 24; h++) {
      byHour.add(_KV(h.toString().padLeft(2, '0'), (byHourRaw[h] ?? 0)));
    }

    final medicineList =
        byMedicine.entries.map((e) => _KV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));

    final amountTypeList =
        byAmountType.entries.map((e) => _AmountKV(e.key, e.value)).toList()
          ..sort((a, b) => b.v.compareTo(a.v));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeaderCard(
          dateLabel: _rangeLabel(_mode),
          total: total,
          unique: unique,
          lastTime: lastTime,
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Distribution by hour",
          subtitle: "When medicines were given",
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
                  color: Color(0xFF059669),
                  name: 'Count',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Medicine types",
          subtitle: "Distribution by medicine name",
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
                  dataSource: medicineList,
                  xValueMapper: (e, _) => e.k,
                  yValueMapper: (e, _) => e.v,
                  pointColorMapper: (datum, index) => Color(0xFF059669),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  explode: true,
                  explodeIndex: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

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
          child: Column(
            children: [
              for (final d in details)
                _MedicineTile(
                  name: d.name,
                  time: d.time,
                  amount: d.amount,
                  amountType: d.amountType,
                ),
            ],
          ),
        ),
        SizedBox(height: 16),
        medicineTips(),
      ],
    );
  }

  Widget medicineTips() {
    return _SectionCard(
      title: "AI Medicine Tips",
      leading: "💡",
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFFdc2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("⚠️", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Always double-check dosage amounts before administering medication",
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
                  color: Color(0xFFdc2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("🌡️", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Store all medications in a cool, dry place away from children",
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
                  color: Color(0xFFdc2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("📞", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Contact pediatrician if you notice any unusual reactions or side effects",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Helpers ----
  int _parseHourSafe(String hhmm, {required String createdAt}) {
    final h = int.tryParse(hhmm.split(':').first);
    if (h != null && h >= 0 && h <= 23) return h;
    final dt = _tryParseDateTime(createdAt);
    return dt?.hour ?? 0;
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final p = timeStr.split(':');
      return DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  DateTime? _tryParseDateTime(String s) {
    // Önce ISO deneriz (service putIfAbsent ile ISO yazıyor olabilir),
    // sonra 'yyyy-MM-dd HH:mm' deneriz.
    try {
      return DateTime.parse(s);
    } catch (_) {
      /* continue */
    }
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  String _bestTime(MedicineModel m) {
    final t = m.startTime;
    if (t.trim().isNotEmpty) return t;
    final dt = _tryParseDateTime(m.createdAt);
    return dt != null ? DateFormat('HH:mm').format(dt) : '-';
  }

  String _normalize(String s) => s.trim().toLowerCase();
}

// --- küçük view modelleri ---

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

class _MedicineDetail {
  final String name;
  final String time;
  final int amount;
  final String amountType;
  final String createdAt;
  _MedicineDetail({
    required this.name,
    required this.time,
    required this.amount,
    required this.amountType,
    required this.createdAt,
  });
}

// ---- UI parçaları (diğer raporlarla aynı stil) ----

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
  final String? leading;
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
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
            const Color(0xFFb5e2d6),
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
              if (leading != null)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFa8d5ba),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(leading!, style: TextStyle(fontSize: 24)),
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
  final int total;
  final int unique;
  final String lastTime;
  const _HeaderCard({
    required this.dateLabel,
    required this.total,
    required this.unique,
    required this.lastTime,
  });
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: "Medicine Overview ",
      subtitle: dateLabel,
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: "$total"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Types", value: "$unique"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(title: "Last time", value: lastTime),
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

class _MedicineTile extends StatelessWidget {
  final String name;
  final String time;
  final int amount;
  final String amountType;
  const _MedicineTile({
    required this.name,
    required this.time,
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
              color: AppColors.kLightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medication,
              color: AppColors.kDeepOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$amount $amountType',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.kDeepOrange,
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
