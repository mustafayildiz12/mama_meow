import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/activities/solid_service.dart';

// Senin servislerin:

// (Opsiyonel) Toplam aktivite için combineLatest kullanacaksan:
// dependencies: rxdart: ^0.27.7 (pubspec.yaml)
// import 'package:rxdart/rxdart.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  String _todayText() {
    final now = DateTime.now();
    // Türkçe biçim (örn: 13 Eylül 2025, Cumartesi)
    final locale = 'en_EN';
    final date = DateFormat('d MMMM y, EEEE', locale).format(now);
    return "Today • $date";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // (Opsiyonel) Toplam Aktivite için combineLatest:
    // final totalStream = Rx.combineLatest4<int, int, int, int, int>(
    //   sleepService.todaySleepCountStream(),
    //   solidService.todaySolidCountStream(),
    //   pumpingService.todayPumpingCountStream(),
    //   diaperService.todayDiaperCountStream(),
    //   (a, b, c, d) => a + b + c + d,
    // );

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.kLightOrange,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _todayText(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // (Opsiyonel) Toplam Aktivite kartı
              // StreamBuilder<int>(
              //   stream: totalStream,
              //   builder: (context, snapshot) {
              //     final count = snapshot.data ?? 0;
              //     return _TotalCard(count: count);
              //   },
              // ),
              // const SizedBox(height: 12),

              // 2x2 grid — responsive olarak Wrap kullanalım
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard<int>(
                      title: "Sleep",

                      icon: Icons.nightlight_round,
                      stream: sleepService.todaySleepCountStream(),
                      color: theme.primaryColorLight.withValues(alpha: 0.15),
                      valueBuilder: (v) => "$v",
                    ),
                    _SummaryCard<int>(
                      title: "Solid",
                      icon: Icons.restaurant,
                      stream: solidService.todaySolidCountStream(),
                      color: theme.highlightColor.withValues(alpha: 0.15),
                      valueBuilder: (v) => "$v",
                    ),
                    _SummaryCard<int>(
                      title: "Pumping",
                      icon: Icons
                          .published_with_changes, // veya breast-pump simge yoksa alternatif
                      stream: pumpingService.todayPumpingCountStream(),
                      color: theme.focusColor.withValues(alpha: 0.15),
                      valueBuilder: (v) => "$v",
                    ),
                    _SummaryCard<int>(
                      title: "Diaper",
                      icon: Icons.baby_changing_station,
                      stream: diaperService.todayDiaperCountStream(),
                      color: theme.secondaryHeaderColor.withValues(alpha: 0.15),
                      valueBuilder: (v) => "$v",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: SizedBox()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.grey.shade200,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back"),
                    ),
                  ),
                ],
              ),

              // İsteğe bağlı: “Detaya git” butonu (zaten ayrı detay sayfan var demiştin)
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton.icon(
              //     onPressed: () {
              //       // Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailedReportPage()));
              //     },
              //     icon: const Icon(Icons.chevron_right),
              //     label: const Text("Detaylı rapora git"),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek bir özet kutucuğu (stream ile gerçek zamanlı)
class _SummaryCard<T> extends StatelessWidget {
  const _SummaryCard({
    required this.title,

    required this.icon,
    required this.stream,
    required this.color,
    required this.valueBuilder,
  });

  final String title;

  final IconData icon;
  final Stream<T> stream;
  final Color color;
  final String Function(T value) valueBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // genişlik: ekrana göre 2 sütun gibi dursun
    final double maxWidth =
        (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<T>(
                stream: stream,
                builder: (context, snapshot) {
                  final isLoading = !snapshot.hasData && !snapshot.hasError;
                  final valueText = snapshot.hasData
                      ? valueBuilder(snapshot.data as T)
                      : (snapshot.hasError ? "—" : "…");

                  return Column(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                valueText,
                                key: ValueKey(valueText),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (Opsiyonel) Toplam kartı
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primaryColorLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toplam Aktivite",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Bugün yapılan tüm aktivitelerin toplamı",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$count",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
