import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// ---- Sabitler ----
const int kDayMinutes = 24 * 60; // 1440
const int kMaxMinutes = 36 * 60; // 2160 (0..36 saat)
const int kStepMinutes = 5; // 5 dakikalık adım
const int kMinDuration = 15; // min 15 dk

/// ---- Modeller ----
class SleepInterval {
  final int startMinute; // 0..1440
  final int endMinute; // 0..1440
  const SleepInterval({required this.startMinute, required this.endMinute});
}

/// Opsiyonel meta (tüm aralıklara ortak)
class SleepMeta {
  final String? startOfSleep; // upset, crying, ...
  final String? endOfSleep; // woke up child, upset, ...
  final String? howItHappened; // nursing, co-sleep, ...
  final String? note;

  const SleepMeta({
    this.startOfSleep,
    this.endOfSleep,
    this.howItHappened,
    this.note,
  });
}

/// Seçenekler
class SleepOptions {
  static const startOfSleepOptions = [
    "upset",
    "crying",
    "content",
    "under 10 min to fall asleep",
    "10-30 min",
    "more than 30 min",
  ];
  static const endOfSleepOptions = [
    "woke up child",
    "upset",
    "content",
    "crying",
  ];
  static const howItHappenedOptions = [
    "nursing",
    "on own in bed",
    "warm or health",
    "next to caregiver",
    "co-sleep",
    "bottle",
    "stroller",
    "car",
    "swing",
  ];
}

/// RangeValues(0..2160 dk) listesini [SleepModel] kayıtlarına çevirir.
///
/// - Aralık tamamen gün içindeyse ([day]) tek kayıt.
/// - 24:00'ı geçiyorsa iki kayda bölünür: [day] start→00:00 ve ertesi gün
///   00:00→bitiş.
/// - Başlangıç da 24:00'dan sonraysa (ör. 00:30(+1)–02:00(+1)) tek kayıt
///   ertesi güne yazılır.
List<SleepModel> buildSleepModels({
  required DateTime day,
  required List<RangeValues> ranges,
  required SleepMeta meta,
}) {
  final nextDay = DateTime(day.year, day.month, day.day + 1);

  SleepModel model(DateTime date, int start, int end) => SleepModel(
    startTime: _fmtHHmm(start),
    endTime: _fmtHHmm(end), // 1440 → "00:00" (gün sonu)
    sleepDate: _fmtDateTime(
      DateTime(date.year, date.month, date.day, start ~/ 60, start % 60),
    ),
    sleepNote: meta.note,
    startOfSleep: meta.startOfSleep,
    endOfSleep: meta.endOfSleep,
    howItHappened: meta.howItHappened,
  );

  final out = <SleepModel>[];
  for (final r in ranges) {
    final s = r.start.round();
    final e = r.end.round();

    if (s >= kDayMinutes) {
      out.add(model(nextDay, s - kDayMinutes, e - kDayMinutes));
    } else if (e > kDayMinutes) {
      out.add(model(day, s, kDayMinutes));
      out.add(model(nextDay, 0, e - kDayMinutes));
    } else {
      out.add(model(day, s, e));
    }
  }
  return out;
}

String _fmtHHmm(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// yyyy-MM-dd HH:mm
String _fmtDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

/// ---- Bottom Sheet (aralık + seçenekler + not) ----
class SleepExtendedMultiSliderBottomSheet extends StatefulWidget {
  final DateTime sleepDate;
  final List<int>? initialStartEnds;

  const SleepExtendedMultiSliderBottomSheet({
    super.key,
    required this.sleepDate,
    this.initialStartEnds,
  });

  @override
  State<SleepExtendedMultiSliderBottomSheet> createState() =>
      _SleepExtendedMultiSliderBottomSheetState();
}

class _SleepExtendedMultiSliderBottomSheetState
    extends State<SleepExtendedMultiSliderBottomSheet> {
  // Her aralık için 0..2160 dk (tek slider prensibi); UI ilk aralığı düzenler.
  final List<RangeValues> _ranges = [];
  String? _startOfSleep;
  String? _endOfSleep;
  String? _howItHappened;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_sleep_sheet');
    final initial = widget.initialStartEnds;
    if (initial != null && initial.isNotEmpty && initial.length.isEven) {
      for (int i = 0; i < initial.length; i += 2) {
        final s = initial[i].clamp(0, kMaxMinutes).toDouble();
        final eRaw = initial[i + 1].clamp(0, kMaxMinutes).toDouble();
        final e = (eRaw <= s)
            ? (s + 30).clamp(0, kMaxMinutes).toDouble()
            : eRaw;
        _ranges.add(RangeValues(s, e));
      }
    } else {
      // Varsayılan: 22:00 → 01:30 (+1)
      _ranges.add(const RangeValues(22 * 60, 25 * 60 + 30));
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ---- Yardımcılar ----

  String _label(int minutes) {
    final plus = minutes >= kDayMinutes ? " (+1)" : "";
    final m = minutes % kDayMinutes;
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}$plus';
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Duration _totalAll() {
    int sum = 0;
    for (final r in _ranges) {
      sum += (r.end - r.start).round();
    }
    return Duration(minutes: sum);
  }

  /// Tek bir RangeValues -> gün içi segmentler (kaydedilecek kayıtlarla aynı).
  List<SleepInterval> _splitToDaySegments(RangeValues r) {
    final s = r.start.round();
    final e = r.end.round();
    if (s >= kDayMinutes) {
      return [
        SleepInterval(startMinute: s - kDayMinutes, endMinute: e - kDayMinutes),
      ];
    }
    if (e <= kDayMinutes) {
      return [SleepInterval(startMinute: s, endMinute: e)];
    }
    return [
      SleepInterval(startMinute: s, endMinute: kDayMinutes),
      SleepInterval(startMinute: 0, endMinute: e - kDayMinutes),
    ];
  }

  /// Aralıklar çok kısa mı ya da gün içi segmentlere bölününce çakışıyor mu?
  bool _hasOverlapAfterSplit() {
    final segs = <SleepInterval>[];
    for (final r in _ranges) {
      if ((r.end - r.start) < kMinDuration) return true; // çok kısa
      segs.addAll(_splitToDaySegments(r));
    }
    segs.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    for (int i = 1; i < segs.length; i++) {
      if (segs[i].startMinute < segs[i - 1].endMinute) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    final meta = SleepMeta(
      startOfSleep: _startOfSleep,
      endOfSleep: _endOfSleep,
      howItHappened: _howItHappened,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    final models = buildSleepModels(
      day: widget.sleepDate,
      ranges: _ranges,
      meta: meta,
    );

    try {
      for (final m in models) {
        await sleepService.addSleep(m);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('addSleep failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final hasOverlap = _hasOverlapAfterSplit();

    return ActivitySheetScaffold(
      initialChildSize: 0.85,
      radius: 20,
      gradient: [Colors.blue.shade200, Colors.purple.shade200],
      onSave: (_ranges.isEmpty || hasOverlap) ? null : _save,
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (hasOverlap)
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "The intervals overlap or are too short. Adjust the times before saving.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Total: ${_fmtDuration(_totalAll())}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => openReminders(context, 'sleepReminders'),
                  icon: const Icon(Icons.alarm_add),
                ),
              ],
            ),
          ),
          _intervalCard(_ranges.first),
          const SizedBox(height: 16),

          ChipPickerSection<String>(
            title: "Start of sleep",
            items: SleepOptions.startOfSleepOptions,
            value: _startOfSleep,
            style: ChipTileStyle.orangeCompact,
            onChanged: (v) => setState(() => _startOfSleep = v),
            iconBuilder: _iconForStartOfSleep,
          ),
          const SizedBox(height: 16),

          ChipPickerSection<String>(
            title: "End of sleep",
            items: SleepOptions.endOfSleepOptions,
            value: _endOfSleep,
            style: ChipTileStyle.orangeCompact,
            onChanged: (v) => setState(() => _endOfSleep = v),
            iconBuilder: _iconForEndOfSleep,
          ),
          const SizedBox(height: 16),

          ChipPickerSection<String>(
            title: "How it happened",
            items: SleepOptions.howItHappenedOptions,
            value: _howItHappened,
            style: ChipTileStyle.orangeCompact,
            onChanged: (v) => setState(() => _howItHappened = v),
            iconBuilder: _iconForHowItHappened,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            onTapOutside: (event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            decoration: const InputDecoration(
              labelText: "Note",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intervalCard(RangeValues r) {
    final startLabel = _label(r.start.round());
    final endLabel = _label(r.end.round());
    final crossesMidnight = r.end > kDayMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "Sleep Interval",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    title: "Start time",
                    value: startLabel,
                    leading: Icons.nightlight_round,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoChip(
                    title: "End Time",
                    value: endLabel,
                    leading: Icons.bedtime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  "00:00",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Spacer(),
                Text(
                  "24:00 | +1",
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Spacer(),
                Text(
                  "36:00",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            RangeSlider(
              min: 0,
              max: kMaxMinutes.toDouble(),
              activeColor: AppColors.kDeepOrange,
              inactiveColor: AppColors.kOrange,
              divisions: kMaxMinutes ~/ kStepMinutes,
              values: r,
              labels: RangeLabels(startLabel, endLabel),
              onChanged: (v) {
                setState(() {
                  final s = v.start;
                  var e = v.end;
                  if (e - s < kMinDuration) {
                    e = (s + kMinDuration).clamp(0, kMaxMinutes.toDouble());
                  }
                  _ranges.first = RangeValues(s, e);
                });
              },
            ),
            if (crossesMidnight)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "It's past midnight",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStartOfSleep(String s) {
    switch (s) {
      case "upset":
        return Icons.sentiment_very_dissatisfied;
      case "crying":
        return Icons.mood_bad;
      case "content":
        return Icons.sentiment_satisfied_alt;
      case "10-30 min":
        return Icons.av_timer;
      case "more than 30 min":
        return Icons.hourglass_bottom;
      default: // "under 10 min to fall asleep"
        return Icons.timer;
    }
  }

  IconData _iconForEndOfSleep(String s) {
    switch (s) {
      case "woke up child":
        return Icons.bedtime_off;
      case "upset":
        return Icons.sentiment_very_dissatisfied;
      case "content":
        return Icons.sentiment_satisfied_alt;
      case "crying":
        return Icons.mood_bad;
      default:
        return Icons.bedtime;
    }
  }

  IconData _iconForHowItHappened(String s) {
    switch (s) {
      case "nursing":
        return Icons.baby_changing_station;
      case "on own in bed":
        return Icons.bedroom_child;
      case "warm or health":
        return Icons.health_and_safety;
      case "next to caregiver":
        return Icons.family_restroom;
      case "co-sleep":
        return Icons.king_bed;
      case "bottle":
        return Icons.local_drink;
      case "stroller":
        return Icons.stroller;
      case "car":
        return Icons.directions_car_filled;
      case "swing":
        return Icons.chair_alt;
      default:
        return Icons.bed;
    }
  }
}

/// ---- Küçük UI parçaları ----
class _InfoChip extends StatelessWidget {
  final String title;
  final String value;
  final IconData leading;
  const _InfoChip({
    required this.title,
    required this.value,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.kLightOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(leading, size: 18, color: AppColors.kDeepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
