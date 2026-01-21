import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_pdf_builder.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/pumping_ai_service.dart'
    hide PumpingAiCompute;
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
// GlassSegmented widget'ını kendi dosyandan import etmeyi unutma.

enum PumpingReportMode { today, week, month }

class PumpingReportPage extends StatefulWidget {
  const PumpingReportPage({super.key});

  @override
  State<PumpingReportPage> createState() => _PumpingReportPageState();
}

class _PumpingReportPageState extends State<PumpingReportPage> {
  PumpingReportMode _mode = PumpingReportMode.today;
  late Future<List<PumpingModel>> _future;

  bool isLoading = false;

  // ✅ cache
  List<PumpingModel>? _cachedPumpings;
  PumpingReportComputed? _cachedComputed;
  PumpingReportMode? _cachedMode;

  @override
  void initState() {
    _future = _fetchByMode(_mode);
    analyticService.screenView('pumping_report_page');
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF8FAFC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  Future<List<PumpingModel>> _fetchByMode(PumpingReportMode mode) {
    switch (mode) {
      case PumpingReportMode.today:
        return pumpingService.todayPumpings();
      case PumpingReportMode.week:
        return pumpingService.weekPumpings();
      case PumpingReportMode.month:
        return pumpingService.monthPumpings();
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchByMode(_mode));
    await _future;
  }

  String _rangeLabel(PumpingReportMode mode) {
    final now = DateTime.now();
    if (mode == PumpingReportMode.today) {
      return DateFormat('EEEE, d MMM').format(now);
    } else if (mode == PumpingReportMode.week) {
      final s = now.startOfWeekTR, e = now.endOfWeekTR;
      return "${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM').format(e)}";
    } else {
      final s = now.startOfMonth, e = now.endOfMonth;
      return "${DateFormat('MMM yyyy').format(s)} (1–${DateFormat('d').format(e)})";
    }
  }

  String _buildPdfFileName(PumpingReportMode mode) {
    final now = DateTime.now();

    switch (mode) {
      case PumpingReportMode.today:
        final d = DateFormat('dd_MM_yyyy').format(now);
        return 'pumping_daily_$d.pdf';

      case PumpingReportMode.week:
        final start = now.startOfWeekTR;
        final end = now.endOfWeekTR;
        final a = DateFormat('dd_MM_yyyy').format(start);
        final b = DateFormat('dd_MM_yyyy').format(end);
        return 'pumping_weekly_${a}_$b.pdf';

      case PumpingReportMode.month:
        final m = DateFormat('MM_yyyy').format(now);
        return 'pumping_monthly_$m.pdf';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoader(
      inAsyncCall: isLoading,
      child: Container(
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
              "🫗  Pumping Reports",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                onPressed: () async {
                  if (isLoading) return; // ✅ double tap guard
                  if (!mounted) return;

                  setState(() => isLoading = true);

                  try {
                    // ✅ 1) Data
                    final pumpings = _cachedPumpings ?? await _future;

                    if (pumpings.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No pumping data to export.'),
                        ),
                      );
                      return;
                    }

                    // ✅ 2) Compute (cache-safe) -> PumpingAiCompute
                    final computed =
                        (_cachedComputed != null && _cachedMode == _mode)
                        ? _cachedComputed!
                        : PumpingAiCompute.compute(
                            pumpings: pumpings,
                            mode: _mode,
                          );

                    // ✅ 3) AI (computed üzerinden payload kur)
                    final ai = await PumpingAIService().analyzePumpingReport(
                      mode: _mode,
                      rangeLabel: _rangeLabel(_mode),
                      pumpings:
                          pumpings, // (istersen serviste hiç kullanma; sadece payload için computed kullan)
                      computed: computed, // ✅ esas
                      userLanguage: "en",
                      notes: const [],
                    );

                    // ✅ 4) PDF bytes
                    final bytes = await PumpingReportPdfBuilder.build(
                      format: PdfPageFormat.a4,
                      mode: _mode,
                      rangeLabel: _rangeLabel(_mode),
                      pumpings: pumpings,
                      computed: computed, // ✅ PDF'de header vb için de kullan
                      ai: ai,
                    );

                    // ✅ 5) Save & open
                    final filename = _buildPdfFileName(_mode);
                    final filepath = await globalFunctions.downloadBytes(
                      bytes,
                      filename,
                    );
                    await OpenFilex.open(filepath);
                  } catch (e) {
                    customSnackBar.warning('PDF error: $e');
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                },
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
                  child: FutureBuilder<List<PumpingModel>>(
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
                      final pumpings = snapshot.data ?? [];
                      if (pumpings.isEmpty) {
                        return const _CenteredMessage(
                          emoji: '🍼',
                          title: 'No record found',
                          subtitle:
                              "You'll see it here when you add pumping for this interval.",
                        );
                      }
                      return _buildReportBody(context, pumpings);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- RAPOR GÖVDESİ (seçili aralık) ----
  Widget _buildReportBody(BuildContext context, List<PumpingModel> pumpings) {
    final c = (_cachedComputed != null && _cachedMode == _mode)
        ? _cachedComputed!
        : PumpingAiCompute.compute(pumpings: pumpings, mode: _mode);

    final totalMinutes = c.totalMinutes;
    final sessions = c.sessions;
    final avgMinutes = c.avgSessionMinutes;

    // hour chart data
    final byHour = <_KV>[];
    for (int h = 0; h < 24; h++) {
      byHour.add(_KV(h.toString().padLeft(2, '0'), c.minutesByHour[h] ?? 0));
    }

    // side distribution (UI pie sen count kullanıyordu, süre daha doğru)
    final leftMinutes = c.leftMinutes;
    final rightMinutes = c.rightMinutes;

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

    String lastSessionTime = '-';
    if (sortedByTime.isNotEmpty) {
      final last = sortedByTime.last;
      final dt = DateTime.tryParse(last.createdAt);
      lastSessionTime = dt != null
          ? DateFormat('HH:mm').format(dt)
          : last.startTime;
    }

    final longest = pumpings.map((p) => _PumpingWithDur(p, p.duration)).toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeaderCard(
          dateLabel: _rangeLabel(_mode),
          total: _fmtMin(totalMinutes),
          sessions: sessions,
          avg: _fmtMin(avgMinutes),
          lastSessionTime: lastSessionTime,
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: "Distribution by hour",
          subtitle: "Sum of minutes per hour (00–23)",
          leading: "📊",
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
                  pointColorMapper: (e, _) => byHourColor(e.v),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  dataLabelMapper: (e, _) => e.v == 0 ? "" : _fmtMin(e.v),
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
          leading: "📊",
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
                    _KV('Left', leftMinutes),
                    _KV('Right', rightMinutes),
                  ],
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
          title: "Longest sessions",
          subtitle: "Top 5 by duration",
          leading: "⚡",
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
        SizedBox(height: 16),
        pumpingTips(),
      ],
    );
  }

  Widget pumpingTips() {
    return _SectionCard(
      title: "AI Pumping Tips",
      leading: "💡",
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFFf6a192),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("⏰", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Your morning sessions yield the highest volume. Consider pumping earlier when possible",
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
                  color: Color(0xFFf6a192),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("💧", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Stay hydrated! Drink water before and during pumping sessions for better output",
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
                  color: Color(0xFFf6a192),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("😌", style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Try relaxation techniques or looking at baby photos to help with let-down reflex",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color byHourColor(int count) {
    if (count >= 120) {
      return const Color(0xFF2ECC71); // y
    } else if (count >= 60 && count < 120) {
      return const Color(0xFFFF7F50); // mercan
    } else if (count >= 30 && count < 60) {
      // Biraz daha parlak/aydınlık
      final base = const Color(0xFFF1C40F);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness((hsl.lightness * 1.10).clamp(0, 1)).toColor();
    } else if (count < 30) {
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

  // ---- Helpers ----
  int _hourFromRecord(PumpingModel p) {
    final dt = DateTime.tryParse(p.createdAt);
    if (dt != null) return dt.hour;
    final hh = int.tryParse(p.startTime.split(':').first);
    return (hh == null || hh < 0 || hh > 23) ? 0 : hh;
  }

  String _bestTime(PumpingModel p) {
    final dt = DateTime.tryParse(p.createdAt);
    return dt != null ? DateFormat('HH:mm').format(dt) : p.startTime;
  }

  String _bestLabel(PumpingModel p) => _bestTime(p);

  String _fmtMin(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}

// --- küçük view modelleri ---

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

// ---- UI PARTIALS (diğer raporlarla aynı) ----

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
            const Color(0xFFffcab0),
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
                    color: const Color(0xFFffd3a5),
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
  final String total;
  final int sessions;
  final String avg;
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
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      title: "Pumping Overview",
      subtitle: dateLabel,
      leading: "🍼",
      child: Row(
        children: [
          Expanded(
            child: _StatTile(title: "Total", value: total),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _StatTile(title: "Sessions", value: "$sessions"),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _StatTile(title: "Avg", value: avg),
          ),
          const SizedBox(width: 4),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isLeft ? Colors.blue : Colors.purple).withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isLeft ? Colors.blue : Colors.purple).withValues(
                  alpha: 0.2,
                ),
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
    final h = minutes ~/ 60, m = minutes % 60;
    if (minutes == 0) return "0m";
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }
}

class _GlassSegmented extends StatelessWidget {
  final PumpingReportMode value;
  final ValueChanged<PumpingReportMode> onChanged;

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
    final activeFill = const Color(0xFFffcab0); // aktif buton zemini
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
                    selected: value == PumpingReportMode.today,
                    onTap: () => onChanged(PumpingReportMode.today),
                    activeFg: activeFg,
                    inactiveFg: inactiveFg,
                    activeFill: activeFill,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentButton(
                    label: 'Weekly',
                    selected: value == PumpingReportMode.week,
                    onTap: () => onChanged(PumpingReportMode.week),
                    activeFg: activeFg,
                    inactiveFg: inactiveFg,
                    activeFill: activeFill,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentButton(
                    label: 'Monthly',
                    selected: value == PumpingReportMode.month,
                    onTap: () => onChanged(PumpingReportMode.month),
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
