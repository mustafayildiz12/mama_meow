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

class JournalDiaryPage extends StatefulWidget {
  const JournalDiaryPage({super.key});

  @override
  State<JournalDiaryPage> createState() => _JournalDiaryPageState();
}

class _JournalDiaryPageState extends State<JournalDiaryPage> {
  late Future<_TodayBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadToday();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadToday());
    await _future;
  }

  Future<_TodayBundle> _loadToday() async {
    final now = DateTime.now().toLocal();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    // Solid: hazır aralık metodu var
    final solids = await solidService.getUserSolidsInRange(start, end);

    // Pumping & Medicine: servislerde today* metotlarını eklemiştik
    final pumpings = await pumpingService.todayPumpings();
    final medicines = await medicineService.todayMedicines();

    // Sleep / Nursing / Diaper: listeyi alıp bugüne filtrele
    final sleepsAll = await sleepService.getSleepList();
    final sleeps = sleepsAll.where((s) {
      final dateOnly = s.sleepDate.split(' ').first;
      final key = DateFormat('yyyy-MM-dd').format(now);
      return dateOnly == key;
    }).toList();

    final nursingsAll = await nursingService.getNursingList();
    final nursings = nursingsAll.where((n) {
      final dt = _tryParseIso(n.createdAt);
      if (dt == null) return false;
      return dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          dt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();

    final diapersAll = await diaperService.getDiaperList();
    final diapers = diapersAll.where((d) {
      final dt = _tryParseIso(d.createdAt);
      if (dt == null) return false;
      return dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          dt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();

    // Notes: bugünün notları (varsa en yenisini gösteririz)
    final notes = await journalService
        .todayNotesOnce(); // küçük yardımcı ekleyebilirsin; yoksa stream alıp first kullan
    return _TodayBundle(
      solids: solids,
      sleeps: sleeps,
      nursings: nursings,
      diapers: diapers,
      pumpings: pumpings,
      medicines: medicines,
      note: notes.isNotEmpty ? notes.last : null,
    );
  }

  String _todayHeaderTR() {
    final now = DateTime.now();
    // 26 Eylül Cuma
    final d = DateFormat('d MMMM', 'en_US').format(now);
    final w = DateFormat('EEEE', 'en_US').format(now);
    return "$d ${_capitalizeTR(w)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
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
                  return _errorBox(snap.error.toString());
                }
                final data = snap.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text(
                      _todayHeaderTR(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                      ),
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
                                "Süre: ${_fmtMin(data.nursings[i].duration)}",
                              if ((data.nursings[i].amountType).isNotEmpty &&
                                  data.nursings[i].amount > 0)
                                "Miktar: ${data.nursings[i].amount.toStringAsFixed(1)} ${data.nursings[i].amountType}",
                              if ((data.nursings[i].milkType ?? '').isNotEmpty)
                                "Süt türü: ${data.nursings[i].milkType}",
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
                            bullets: [
                              _clockLine(
                                _bestTimeFromISO(data.diapers[i].createdAt) ??
                                    data.diapers[i].diaperTime,
                              ),
                            ],
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
                              "Süre: ${_fmtMin(data.pumpings[i].duration)}",
                              _clockLine(
                                _bestTimeFromISO(data.pumpings[i].createdAt) ??
                                    data.pumpings[i].startTime,
                              ),
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
                              "Miktar: ${data.medicines[i].amount} ${data.medicines[i].amountType}",
                              _clockLine(
                                _bestTimeFromISO(data.medicines[i].createdAt) ??
                                    data.medicines[i].startTime,
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 12),

                    // BUGÜNÜN NOTU
                    Text(
                      "Daily Note",
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
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) =>
                                const AddJournalNoteBottomSheet(),
                          ).then((v) {
                            // not eklenmiş olabilir → yenile
                            if (v == true) {
                              _refresh();
                            }
                          });
                        },
                        icon: const Icon(Icons.edit_note),
                        label: Text(
                          data.note == null ? "Add Note" : "Edit Note",
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---- helpers ----

  static DateTime? _tryParseIso(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String? _bestTimeFromISO(String iso) {
    final dt = _tryParseIso(iso);
    return dt != null ? DateFormat('HH:mm').format(dt) : null;
  }

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
            if (durMin > 0) "Süre: ${_fmtMin(durMin)}",
            if ((s.howItHappened ?? '').isNotEmpty) "Nasıl: ${s.howItHappened}",
            if ((s.startOfSleep ?? '').isNotEmpty)
              "Başlangıç: ${s.startOfSleep}",
            if ((s.endOfSleep ?? '').isNotEmpty) "Bitiş: ${s.endOfSleep}",
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
    if (minutes == 0) return "0 dk";
    if (h == 0) return "$m dk";
    if (m == 0) return "$h sa";
    return "$h sa $m dk";
  }

  static String _clockLine(String timeHHmm) => "⏰ $timeHHmm";

  static String _capitalizeTR(String s) {
    if (s.isEmpty) return s;
    // TR özel durumlar için kaba ama yeterli
    final first = s.characters.first.toUpperCase();
    return first + s.characters.skip(1).join();
  }

  Widget _errorBox(String msg) {
    return Center(
      child: Container(
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
            "Son Not • ${note.formattedTime}",
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
