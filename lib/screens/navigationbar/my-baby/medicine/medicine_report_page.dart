import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';

class MedicineReportPage extends StatefulWidget {
  const MedicineReportPage({super.key});

  @override
  State<MedicineReportPage> createState() => _MedicineReportPageState();
}

class _MedicineReportPageState extends State<MedicineReportPage> {
  late Future<List<MedicineModel>> _futureToday;

  @override
  void initState() {
    super.initState();
    _futureToday = _fetchTodayMedicines();
  }

  Future<void> _refresh() async {
    setState(() => _futureToday = _fetchTodayMedicines());
    await _futureToday;
  }

  Future<List<MedicineModel>> _fetchTodayMedicines() async {
    final all = await medicineService.getMedicineList();

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final result = <MedicineModel>[];
    for (final medicine in all) {
      final datePart = _safeDatePart(medicine.createdAt);
      if (datePart == todayKey) {
        result.add(medicine);
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
          title: const Text("Today's Medicine Report"),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<MedicineModel>>(
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
              final medicines = snapshot.data ?? [];
              if (medicines.isEmpty) {
                return const _CenteredMessage(
                  emoji: '💊',
                  title: 'No medicine records today',
                  subtitle: 'Log a medicine to see insights here.',
                );
              }

              // ---- Aggregate ----
              final byHourRaw = <int, int>{}; // 0..23 -> count
              final byMedicine = <String, int>{}; // medicine name -> count
              final byAmountType = <String, double>{}; // amount type -> total amount
              final medicineDetails = <_MedicineDetail>[];

              String? lastMedicineTime;
              DateTime? latestTime;

              for (final medicine in medicines) {
                // Parse hour from startTime
                final h = _parseHourSafe(medicine.startTime);
                byHourRaw[h] = (byHourRaw[h] ?? 0) + 1;

                // Count by medicine name
                final medicineName = _normalizeLabel(medicine.medicineName);
                byMedicine[medicineName] = (byMedicine[medicineName] ?? 0) + 1;

                // Sum by amount type
                final amountKey = medicine.amountType;
                byAmountType[amountKey] = (byAmountType[amountKey] ?? 0) + medicine.amount;

                // Medicine details for list
                medicineDetails.add(_MedicineDetail(
                  name: medicine.medicineName,
                  time: medicine.startTime,
                  amount: medicine.amount,
                  amountType: medicine.amountType,
                  createdAt: medicine.createdAt,
                ));

                // Find latest medicine time
                final medicineTime = _parseDateTime(medicine.createdAt);
                if (medicineTime != null && (latestTime == null || medicineTime.isAfter(latestTime))) {
                  latestTime = medicineTime;
                  lastMedicineTime = medicine.startTime;
                }
              }

              final totalMedicines = medicines.length;
              final uniqueMedicines = byMedicine.keys.length;

              // Sort medicine details by time
              medicineDetails.sort((a, b) {
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

              final medicineList = byMedicine.entries
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
                    total: totalMedicines,
                    unique: uniqueMedicines,
                    lastTime: lastMedicineTime ?? '-',
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
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                            color: AppColors.kDeepOrange,
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

                  _SectionCard(
                    title: "Today's medicines",
                    subtitle: "Chronological list",
                    child: Column(
                      children: [
                        for (final detail in medicineDetails)
                          _MedicineTile(
                            name: detail.name,
                            time: detail.time,
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
    // Expected format: "yyyy-MM-dd HH:mm"
    final parts = createdAt.split(' ');
    if (parts.isNotEmpty) return parts.first;
    return createdAt;
  }

  int _parseHourSafe(String hhmm) {
    final h = int.tryParse(hhmm.split(':').first);
    return (h == null || h < 0 || h > 23) ? 0 : h;
  }

  DateTime? _parseDateTime(String createdAt) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parseStrict(createdAt);
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

class _MedicineDetail {
  final String name;
  final String time;
  final double amount;
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
      title: "Today • $dateLabel",
      subtitle: "Summary of medicines",
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

class _MedicineTile extends StatelessWidget {
  final String name;
  final String time;
  final double amount;
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$amount $amountType',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
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