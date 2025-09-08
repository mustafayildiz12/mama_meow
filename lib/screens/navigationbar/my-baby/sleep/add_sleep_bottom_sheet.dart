import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';

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

/// Dropdown seçenekleri
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

/// ---- Bottom Sheet (Çoklu aralık + dropdown + not) ----
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
  // Her aralık için 0..2160 dk tutacağız (tek slider prensibi)
  final List<RangeValues> _ranges = [];
  // Dropdown + Not
  String? _startOfSleep;
  String? _endOfSleep;
  String? _howItHappened;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStartEnds != null &&
        widget.initialStartEnds!.length.isEven &&
        widget.initialStartEnds!.isNotEmpty) {
      for (int i = 0; i < widget.initialStartEnds!.length; i += 2) {
        final s = widget.initialStartEnds![i].clamp(0, kMaxMinutes).toDouble();
        final eRaw = widget.initialStartEnds![i + 1]
            .clamp(0, kMaxMinutes)
            .toDouble();
        final e = (eRaw <= s)
            ? (s + 30).clamp(0, kMaxMinutes).toDouble()
            : eRaw;
        _ranges.add(RangeValues(s, e));
      }
    } else {
      // Varsayılan tek aralık: 22:00 → 01:30 (+1)
      _ranges.add(RangeValues(22 * 60, 25 * 60 + 30));
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

  /// Tek bir RangeValues -> split edilmiş (gün içi) segment listesi
  List<SleepInterval> _splitToDaySegments(RangeValues r) {
    final s = r.start.round();
    final e = r.end.round();
    if (e <= kDayMinutes) {
      return [SleepInterval(startMinute: s, endMinute: e)];
    } else {
      return [
        SleepInterval(
          startMinute: s.clamp(0, kDayMinutes),
          endMinute: kDayMinutes,
        ),
        SleepInterval(
          startMinute: 0,
          endMinute: (e - kDayMinutes).clamp(0, kDayMinutes),
        ),
      ];
    }
  }

  /// Tüm aralıkları gün içi segmanlara çevirip (split), çakışma kontrolü
  bool _hasOverlapAfterSplit() {
    final segs = <SleepInterval>[];
    for (final r in _ranges) {
      if ((r.end - r.start) < kMinDuration)
        return true; // çok kısa: hatalı sayalım
      segs.addAll(_splitToDaySegments(r));
    }
    segs.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    for (int i = 1; i < segs.length; i++) {
      if (segs[i].startMinute < segs[i - 1].endMinute) return true; // çakışma
    }
    return false;
  }

  String _dateLabel(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd.$mm.$yyyy";
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(20);
    final total = _totalAll();
    final hasOverlap = _hasOverlapAfterSplit();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.kLightOrange,
            borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                /*
                 const SizedBox(height: 8),Ğ
                Row(
                  children: [
                    Text(
                      "Date — ${_dateLabel(widget.sleepDate)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Visibility(
                      visible: false, // TODO ilerde açabiliriz tekrardan
                      child: IconButton(
                        tooltip: "Add Interval",
                        onPressed: () {
                          setState(() {
                            _ranges.add(RangeValues(12 * 60, 13 * 60));
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ),
                  ],
                ),
                */
                if (hasOverlap)
                  Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Aralıklar çakışıyor veya çok kısa. Kaydetmeden önce saatleri düzelt.",
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
                      Text(
                        "Total: ${_fmtDuration(total)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Builder(
                  builder: (context) {
                    final r = _ranges.first;
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
                            Row(
                              children: [
                                Text(
                                  "Sleep Interval",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Visibility(
                                  visible: false,
                                  maintainAnimation: true,
                                  maintainSize: true,
                                  maintainState: true,
                                  child: IconButton(
                                    tooltip: "Kaldır",
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      // setState(() => _ranges.removeAt(i));
                                    },
                                  ),
                                ),
                              ],
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
                            Row(
                              children: const [
                                Text(
                                  "00:00",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  "24:00 | +1",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  "36:00",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              min: 0,
                              activeColor: AppColors.kDeepOrange,
                              inactiveColor: AppColors.kOrange,
                              max: kMaxMinutes.toDouble(),
                              divisions: kMaxMinutes ~/ kStepMinutes,
                              values: r,
                              labels: RangeLabels(startLabel, endLabel),
                              onChanged: (v) {
                                setState(() {
                                  var s = v.start;
                                  var e = v.end;
                                  if (e - s < kMinDuration)
                                    e = (s + kMinDuration).clamp(
                                      0,
                                      kMaxMinutes.toDouble(),
                                    );
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
                                    "Gece yarısını aşıyor",
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
                  },
                ),

                //TODO çoklu istenirse açalım
                //rangeList(),
                const SizedBox(height: 16),

                _ChipPickerSection(
                  title: "Start of sleep",
                  items: SleepOptions.startOfSleepOptions,
                  value: _startOfSleep,
                  onChanged: (v) => setState(() => _startOfSleep = v),
                  iconBuilder: _iconForStartOfSleep,
                ),
                const SizedBox(height: 16),

                _ChipPickerSection(
                  title: "End of sleep",
                  items: SleepOptions.endOfSleepOptions,
                  value: _endOfSleep,
                  onChanged: (v) => setState(() => _endOfSleep = v),
                  iconBuilder: _iconForEndOfSleep,
                ),
                const SizedBox(height: 16),

                _ChipPickerSection(
                  title: "How it happened",
                  items: SleepOptions.howItHappenedOptions,
                  value: _howItHappened,
                  onChanged: (v) => setState(() => _howItHappened = v),
                  iconBuilder: _iconForHowItHappened,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Note",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (_ranges.isEmpty || hasOverlap)
                                ? null
                                : () async {
                                    final meta = SleepMeta(
                                      startOfSleep: _startOfSleep,
                                      endOfSleep: _endOfSleep,
                                      howItHappened: _howItHappened,
                                      note: _noteCtrl.text.isEmpty
                                          ? null
                                          : _noteCtrl.text,
                                    );

                                    // 1) SleepModel listesi oluştur
                                    final models = buildSleepModels(
                                      day: widget.sleepDate,
                                      ranges: _ranges,
                                      meta: meta,
                                      splitWrapAcrossMidnight:
                                          true, // wrap'ı iki modele böl
                                    );

                                    for (SleepModel sleepModel in models) {
                                      await sleepService.addSleep(sleepModel);
                                    }

                                    Navigator.pop(context);
                                  },
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      case "under 10 min to fall asleep":
        return Icons.timer;
      case "10-30 min":
        return Icons.av_timer;
      case "more than 30 min":
        return Icons.hourglass_bottom;
      default:
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
        return Icons.baby_changing_station; // uygun değilse Icons.monitor_heart
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

  Expanded rangeList() {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        itemCount: _ranges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final r = _ranges[i];
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
                  Row(
                    children: [
                      Text(
                        "${i + 1}. Sleep",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Visibility(
                        visible: false,
                        maintainAnimation: true,
                        maintainSize: true,
                        maintainState: true,
                        child: IconButton(
                          tooltip: "Kaldır",
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() => _ranges.removeAt(i));
                          },
                        ),
                      ),
                    ],
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
                  Row(
                    children: const [
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
                    activeColor: AppColors.kDeepOrange,
                    inactiveColor: AppColors.kLightOrange,
                    min: 0,
                    max: kMaxMinutes.toDouble(),
                    divisions: kMaxMinutes ~/ kStepMinutes,
                    values: r,
                    labels: RangeLabels(startLabel, endLabel),
                    onChanged: (v) {
                      setState(() {
                        var s = v.start;
                        var e = v.end;
                        if (e - s < kMinDuration)
                          e = (s + kMinDuration).clamp(
                            0,
                            kMaxMinutes.toDouble(),
                          );
                        _ranges[i] = RangeValues(s, e);
                      });
                    },
                  ),
                  if (crossesMidnight)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "After midnight",
                          style: TextStyle(
                            color: AppColors.kDeepOrange,
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
        },
      ),
    );
  }

  String _fmtHHmm(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _fmtDateTime(DateTime dt) {
    // yyyy-MM-dd HH:mm
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  /// RangeValues(0..2160) -> SleepModel list
  /// - splitWrapAcrossMidnight: true ise 24:00'ı geçen aralık 2 modele bölünür.
  ///   false ise tek model döner (endTime < startTime kalabilir; backend'in wrap kuralını biliyorsan bunu seçebilirsin).
  List<SleepModel> buildSleepModels({
    required DateTime day, // seçilen gün (sadece tarih kısmı kullanılır)
    required List<RangeValues> ranges, // 0..36 saat RangeValues listesi
    required SleepMeta meta, // dropdown & not
    bool splitWrapAcrossMidnight = true,
  }) {
    final List<SleepModel> out = [];

    DateTime _withTime(DateTime base, int minutes) =>
        DateTime(base.year, base.month, base.day, minutes ~/ 60, minutes % 60);

    for (final r in ranges) {
      final s = r.start.round();
      final e = r.end.round();

      final crosses = e > kDayMinutes;

      if (crosses && splitWrapAcrossMidnight) {
        // Parça 1: [start .. 24:00] (bugün)
        final start1 = s % kDayMinutes;
        final end1 = kDayMinutes;
        out.add(
          SleepModel(
            startTime: _fmtHHmm(start1),
            endTime: _fmtHHmm(
              end1,
            ), // 24:00 = 00:00 gibi gösterilmez; 24:00 pratikte gün sonu
            sleepDate: _fmtDateTime(_withTime(day, start1)),
            sleepNote: meta.note,
            startOfSleep: meta.startOfSleep,
            endOfSleep: meta.endOfSleep,
            howItHappened: meta.howItHappened,
          ),
        );

        // Parça 2: [00:00 .. (e-1440)] (ertesi gün)
        final nextDay = day.add(const Duration(days: 1));
        final start2 = 0;
        final end2 = (e - kDayMinutes).clamp(0, kDayMinutes);
        out.add(
          SleepModel(
            startTime: _fmtHHmm(start2),
            endTime: _fmtHHmm(end2),
            sleepDate: _fmtDateTime(_withTime(nextDay, start2)),
            sleepNote: meta.note,
            startOfSleep: meta.startOfSleep,
            endOfSleep: meta.endOfSleep,
            howItHappened: meta.howItHappened,
          ),
        );
      } else {
        // Tek model: aynı gün (veya wrap'i tek kayıtta tutmak istiyorsan)
        final startM = s % kDayMinutes;
        final endM = (crosses ? e - kDayMinutes : e).clamp(0, kDayMinutes);
        final dateForThis = crosses ? day.add(const Duration(days: 1)) : day;

        out.add(
          SleepModel(
            startTime: _fmtHHmm(startM),
            endTime: _fmtHHmm(endM),
            sleepDate: _fmtDateTime(_withTime(dateForThis, startM)),
            sleepNote: meta.note,
            startOfSleep: meta.startOfSleep,
            endOfSleep: meta.endOfSleep,
            howItHappened: meta.howItHappened,
          ),
        );
      }
    }

    return out;
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

class _InfoBanner extends StatelessWidget {
  final String text;
  final bool isWarning;
  const _InfoBanner({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange.shade50 : Colors.grey.shade50;
    final border = isWarning ? Colors.orange.shade200 : Colors.black12;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.nights_stay : Icons.info_outline,
            size: 18,
            color: isWarning ? Colors.orange : Colors.black54,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ChipPickerSection extends StatelessWidget {
  final String title; // örn: "Start of sleep"
  final List<String> items; // seçenekler
  final String? value; // seçili değer
  final ValueChanged<String> onChanged;
  final IconData Function(String) iconBuilder;

  const _ChipPickerSection({
    required this.title,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        // Sağa kaydırılabilir sıra
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChipTile(
                    label: it,
                    selected: it == value,
                    icon: iconBuilder(it),
                    onTap: () => onChanged(it),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ChipTile({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.kOrange : AppColors.kLightOrange;
    final border = selected ? AppColors.kDeepOrange : Colors.black12;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 96,
          height: 96, // kare
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? AppColors.kDeepOrange : Colors.black54,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
