import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mama_meow/constants/app_colors.dart';

import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/models/activities/journal_model.dart';

import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/activities/journal_service.dart';

import 'package:mama_meow/screens/navigationbar/my-baby/journal/add_journal_note_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/analytic_service.dart';

class JournalDiaryPage extends StatefulWidget {
  const JournalDiaryPage({super.key});

  @override
  State<JournalDiaryPage> createState() => _JournalDiaryPageState();
}

class _JournalDiaryPageState extends State<JournalDiaryPage> {
  late Future<_TodayBundle> _future;

  // Seçilen gün (gün duyarlı olsun diye 00:00'a sabitlenir)
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());

  bool get _isToday => DateUtils.isSameDay(_selectedDay, DateTime.now());

  @override
  void initState() {
    super.initState();
    analyticService.screenView('journal_screen');
    _future = _loadFor(_selectedDay);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadFor(_selectedDay));
    try {
      await _future;
    } catch (_) {
      // Hata FutureBuilder'da gösteriliyor.
    }
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = DateUtils.dateOnly(day);
      _future = _loadFor(_selectedDay);
    });
  }

  Future<_TodayBundle> _loadFor(DateTime day) async {
    final start = DateUtils.dateOnly(day.toLocal());
    final end = DateTime(start.year, start.month, start.day, 23, 59, 59, 999);

    // Tüm aktiviteler seçilen günün aralığıyla, paralel çekilir.
    final (
      solids,
      pumpings,
      medicines,
      sleeps,
      nursings,
      diapers,
      notes,
    ) = await (
      solidService.getUserSolidsInRange(start, end),
      pumpingService.getUserPumpingsInRange(start, end),
      medicineService.getUserMedicinesInRange(start, end),
      sleepService.getUserSleepsInRange(start, end),
      nursingService.getUserNursingsInRange(start, end),
      diaperService.getUserDiapersInRange(start, end),
      journalService.getNotesInRange(start, end),
    ).wait;

    return _TodayBundle(
      solids: solids,
      sleeps: sleeps,
      nursings: nursings,
      diapers: diapers,
      pumpings: pumpings,
      medicines: medicines,
      // Liste en yeniden eskiye sıralı → en yeni not ilk eleman.
      note: notes.isNotEmpty ? notes.first : null,
    );
  }

  // eski _todayHeaderTR yerine:
  String _headerFor(DateTime day) {
    // Örn: 7 October Tuesday (mevcut İngilizce biçimi koruyorum)
    final d = DateFormat('d MMMM', 'en_US').format(day);
    final w = DateFormat('EEEE', 'en_US').format(day);
    return "$d ${_capitalizeTR(w)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActivitySheetFrame(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context, _) => _sheetBody(context, theme),
    );
  }

  Widget _sheetBody(BuildContext context, ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
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
          "📓 Journal",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_TodayBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snap.hasError) {
              debugPrint('Journal load failed: ${snap.error}');
              return _errorBox(
                "We couldn't load this day. Pull to refresh and try again.",
              );
            }
            final data = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  children: [
                    // Geri (önceki gün)
                    IconButton(
                      tooltip: 'Previous day',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _selectDay(
                        DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day - 1,
                        ),
                      ),
                    ),

                    // Ortada tarih
                    Expanded(
                      child: Center(
                        child: Text(
                          _headerFor(_selectedDay),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),

                    // İleri (sonraki gün)
                    IconButton(
                      tooltip: 'Next day',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _isToday
                          ? null
                          : () => _selectDay(
                              DateTime(
                                _selectedDay.year,
                                _selectedDay.month,
                                _selectedDay.day + 1,
                              ),
                            ),
                    ),

                    // Takvim aç
                    IconButton(
                      tooltip: 'Pick a date',
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDay,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && mounted) _selectDay(picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SOLID
                _CategoryCard(
                  title: "Solid",
                  icon: Icons.restaurant,
                  color: Colors.orange.shade200,
                  emptyText: "No solid record for today.",
                  children: [
                    for (int i = 0; i < data.solids.length; i++)
                      _NumberedEntry(
                        index: i + 1,
                        title: data.solids[i].solidName,
                        bullets: [
                          "Amount: ${data.solids[i].solidAmount}",
                          _clockLine(data.solids[i].eatTime),
                          if (data.solids[i].reactions != null)
                            "Reaction: ${data.solids[i].reactions!.name}",
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // SLEEP
                _CategoryCard(
                  title: "Sleep",
                  icon: Icons.nightlight_round,
                  color: Colors.blue.shade200,
                  emptyText: "No sleep record for today.",
                  children: [..._sleepEntries(data.sleeps)],
                ),
                const SizedBox(height: 12),

                // NURSING
                _CategoryCard(
                  title: "Nursing",
                  icon: Icons.child_care,
                  color: Colors.teal.shade200,
                  emptyText: "No nursing record for today.",
                  children: [
                    for (int i = 0; i < data.nursings.length; i++)
                      _NumberedEntry(
                        index: i + 1,
                        title:
                            "${data.nursings[i].feedingType} • ${data.nursings[i].side}",
                        bullets: [
                          if (data.nursings[i].duration > 0)
                            "Time: ${_fmtMin(data.nursings[i].duration)}",
                          if ((data.nursings[i].amountType).isNotEmpty &&
                              data.nursings[i].amount > 0)
                            "Amount: ${data.nursings[i].amount.toStringAsFixed(1)} ${data.nursings[i].amountType}",
                          if ((data.nursings[i].milkType ?? '').isNotEmpty)
                            "Milk Type: ${data.nursings[i].milkType}",
                          _clockLine(data.nursings[i].startTime),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // DIAPER
                _CategoryCard(
                  title: "Diaper",
                  icon: Icons.baby_changing_station,
                  color: Colors.green.shade200,
                  emptyText: "No diaper record for today.",
                  children: [
                    for (int i = 0; i < data.diapers.length; i++)
                      _NumberedEntry(
                        index: i + 1,
                        title: data.diapers[i].diaperName,
                        bullets: [_clockLine(data.diapers[i].diaperTime)],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // PUMPING
                _CategoryCard(
                  title: "Pumping",
                  icon: Icons.published_with_changes,
                  color: Colors.pink.shade200,
                  emptyText: "No pumping record for today.",
                  children: [
                    for (int i = 0; i < data.pumpings.length; i++)
                      _NumberedEntry(
                        index: i + 1,
                        title: data.pumpings[i].isLeft ? "Left" : "Right",
                        bullets: [
                          "Time: ${_fmtMin(data.pumpings[i].duration)}",
                          _clockLine(data.pumpings[i].startTime),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // MEDICINE
                _CategoryCard(
                  title: "Medicine",
                  icon: Icons.medication,
                  color: Colors.red.shade200,
                  emptyText: "No medicine record for today.",
                  children: [
                    for (int i = 0; i < data.medicines.length; i++)
                      _NumberedEntry(
                        index: i + 1,
                        title: data.medicines[i].medicineName,
                        bullets: [
                          "Amount: ${data.medicines[i].amount} ${data.medicines[i].amountType}",
                          _clockLine(data.medicines[i].startTime),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 12),

                _isToday
                    ? Text(
                        "Daily Note",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade700,
                        ),
                      )
                    : Text(
                        '${_headerFor(_selectedDay)} Daily Note',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade700,
                        ),
                      ),
                const SizedBox(height: 8),
                if (data.note != null)
                  _NotePreview(note: data.note!)
                else
                  _EmptyNoteHint(),

                const SizedBox(height: 12),
                if (_isToday)
                  SizedBox(
                    width: double.infinity,
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
                        final changed = await showActivitySheet<bool>(
                          context,
                          (_) => const AddJournalNoteBottomSheet(),
                        );
                        // not eklenmiş/silinmiş olabilir → yenile
                        if (changed == true && mounted) _refresh();
                      },
                      icon: const Icon(Icons.edit_note),
                      label: Text(data.note == null ? "Add Note" : "Edit Note"),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- helpers ----

  List<Widget> _sleepEntries(List<SleepModel> sleeps) {
    // kronolojik sırala
    final sorted = [...sleeps]
      ..sort((a, b) {
        final aDt = _combine(a.sleepDate, a.startTime);
        final bDt = _combine(b.sleepDate, b.startTime);
        return (aDt ?? DateTime(0)).compareTo(bDt ?? DateTime(0));
      });

    final out = <Widget>[];
    for (int i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final durMin = _durationMin(s);
      out.add(
        _NumberedEntry(
          index: i + 1,
          title: "${s.startTime} – ${s.endTime}",
          bullets: [
            if (durMin > 0) "Time: ${_fmtMin(durMin)}",
            if ((s.howItHappened ?? '').isNotEmpty) "How: ${s.howItHappened}",
            if ((s.startOfSleep ?? '').isNotEmpty) "Start: ${s.startOfSleep}",
            if ((s.endOfSleep ?? '').isNotEmpty) "End: ${s.endOfSleep}",
          ],
        ),
      );
    }
    return out;
  }

  static DateTime? _combine(String dateStr, String hhmm) {
    try {
      final dateOnly = dateStr.split(' ').first; // yyyy-MM-dd
      final ymd = DateFormat('yyyy-MM-dd').parseStrict(dateOnly);
      final p = hhmm.split(':');
      final h = int.parse(p[0]), m = int.parse(p[1]);
      return DateTime(ymd.year, ymd.month, ymd.day, h, m);
    } catch (_) {
      return null;
    }
  }

  static int _durationMin(SleepModel s) {
    final a = _combine(s.sleepDate, s.startTime);
    var b = _combine(s.sleepDate, s.endTime);
    if (a == null || b == null) return 0;
    if (b.isBefore(a)) b = b.add(const Duration(days: 1));
    return b.difference(a).inMinutes;
  }

  static String _fmtMin(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (minutes == 0) return "0 mn";
    if (h == 0) return "$m mn";
    if (m == 0) return "$h h";
    return "$h h $m mn";
  }

  static String _clockLine(String timeHHmm) => "⏰ $timeHHmm";

  static String _capitalizeTR(String s) {
    if (s.isEmpty) return s;
    // TR özel durumlar için kaba ama yeterli
    final first = s.characters.first.toUpperCase();
    return first + s.characters.skip(1).join();
  }

  /// Kaydırılabilir: çekerek yenileme hata durumunda da çalışır.
  Widget _errorBox(String msg) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(msg, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- küçük view parçaları ---

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String emptyText;
  final List<Widget> children;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (children.isEmpty)
            Text(
              emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            )
          else
            Column(children: children),
        ],
      ),
    );
  }
}

class _NumberedEntry extends StatelessWidget {
  final int index;
  final String title;
  final List<String> bullets;
  const _NumberedEntry({
    required this.index,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.kLightOrange,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.kDeepOrange.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "$index",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final b in bullets.where((e) => e.trim().isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "• $b",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePreview extends StatelessWidget {
  final JournalModel note;
  const _NotePreview({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Last Note • ${note.formattedTime}",
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(note.noteText, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyNoteHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.note_add_outlined, color: Colors.purple.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "There are no notes for today yet. You can write something using ‘Add Note’.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek payload
class _TodayBundle {
  final List<SolidModel> solids;
  final List<SleepModel> sleeps;
  final List<NursingModel> nursings;
  final List<DiaperModel> diapers;
  final List<PumpingModel> pumpings;
  final List<MedicineModel> medicines;
  final JournalModel? note;
  _TodayBundle({
    required this.solids,
    required this.sleeps,
    required this.nursings,
    required this.diapers,
    required this.pumpings,
    required this.medicines,
    required this.note,
  });
}
