import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/journal/add_journal_note_bottom_sheet.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/activities/journal_service.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
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
      initialChildSize: 0.92,
      minChildSize: 0.6,
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2x2 grid — responsive olarak Wrap kullanalım
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SummaryCard<int>(
                            title: "Sleep",
                            icon: Icons.nightlight_round,
                            stream: sleepService.todaySleepCountStream(),
                            color: Colors.blue.shade200.withValues(alpha: 0.6),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Solid",
                            icon: Icons.restaurant,
                            stream: solidService.todaySolidCountStream(),
                            color: Colors.orange.shade200.withValues(
                              alpha: 0.6,
                            ),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Pumping",
                            icon: Icons.published_with_changes,
                            stream: pumpingService.todayPumpingCountStream(),
                            color: Colors.pink.shade200.withValues(alpha: 0.6),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Diaper",
                            icon: Icons.baby_changing_station,
                            stream: diaperService.todayDiaperCountStream(),
                            color: Colors.green.shade200.withValues(alpha: 0.6),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Medicine",
                            icon: Icons.medication,
                            stream: medicineService.todayMedicineCountStream(),
                            color: Colors.red.shade200.withValues(alpha: 0.6),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Nursing",
                            icon: Icons.child_care,
                            stream: nursingService.todayNursingCountStream(),
                            color: Colors.teal.shade200.withValues(alpha: 0.6),
                            valueBuilder: (v) => "$v",
                          ),
                          _SummaryCard<int>(
                            title: "Notes",
                            icon: Icons.edit_note,
                            stream: journalService.todayNoteCountStream(),
                            color: Colors.purple.shade200.withValues(
                              alpha: 0.6,
                            ),
                            valueBuilder: (v) => "$v",
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Today's Notes Section
                      Text(
                        "Today's Notes",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Notes List
                      StreamBuilder(
                        stream: journalService.todayNotesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Failed to load notes',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final notes = snapshot.data ?? [];

                          if (notes.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.note_add_outlined,
                                    size: 48,
                                    color: Colors.purple.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No notes yet today',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple.shade700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Add Note" to capture your thoughts',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.purple.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: notes
                                .map((note) => _NoteCard(note: note))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Add Note Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => const AddJournalNoteBottomSheet(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note'),
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

/// Individual note card widget
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final JournalModel note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.edit_note, size: 20, color: Colors.purple.shade400),
            ],
          ),

          const SizedBox(height: 12),

          // Note content
          Text(
            note.noteText,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
