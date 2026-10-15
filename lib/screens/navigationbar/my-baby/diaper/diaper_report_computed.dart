import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/utils/date_range.dart';

class DiaperReportComputed {
  final int totalCount;
  final String lastChangeLabel; // "HH:mm" or "-"
  final int avgGapMinutes;
  final int maxGapMinutes;

  final Map<String, int> distHourCount; // "00".."23" -> count
  final Map<String, int> typeCounts; // wet/poop/mixed/pee/other/dry

  final List<DiaperDetail> timeline; // chronological

  DiaperReportComputed({
    required this.totalCount,
    required this.lastChangeLabel,
    required this.avgGapMinutes,
    required this.maxGapMinutes,
    required this.distHourCount,
    required this.typeCounts,
    required this.timeline,
  });

  /// Kayıtlardan rapor metrikleri. Sıralama, saat dağılımı, aralıklar ve
  /// "son değişim" kullanıcının seçtiği saate (`diaperTime`) göredir;
  /// `createdAt` yalnızca günü belirlemek için kullanılır.
  factory DiaperReportComputed.fromDiapers(List<DiaperModel> diapers) {
    final sorted = sortDiapersByEventTime(diapers);

    final times = sorted.map((d) => d.eventAt).whereType<DateTime>().toList();
    final gaps = <int>[
      for (var i = 1; i < times.length; i++)
        times[i].difference(times[i - 1]).inMinutes,
    ];

    final byHourRaw = <int, int>{};
    final byType = <String, int>{};
    final timeline = <DiaperDetail>[];

    for (final d in sorted) {
      final hour = d.eventAt?.hour ?? parseHourMinute(d.diaperTime)?.$1 ?? 0;
      byHourRaw[hour] = (byHourRaw[hour] ?? 0) + 1;

      final type = diaperTypeKey(d.diaperName);
      byType[type] = (byType[type] ?? 0) + 1;

      timeline.add(
        DiaperDetail(
          time: diaperDisplayTime(d),
          label: d.diaperName,
          createdAt: d.createdAt,
        ),
      );
    }

    return DiaperReportComputed(
      totalCount: diapers.length,
      lastChangeLabel: sorted.isEmpty ? '-' : diaperDisplayTime(sorted.last),
      avgGapMinutes: gaps.isEmpty
          ? 0
          : (gaps.reduce((a, b) => a + b) / gaps.length).round(),
      maxGapMinutes: gaps.isEmpty ? 0 : gaps.reduce((a, b) => a > b ? a : b),
      distHourCount: {
        for (var h = 0; h < 24; h++)
          h.toString().padLeft(2, '0'): byHourRaw[h] ?? 0,
      },
      typeCounts: byType,
      timeline: timeline,
    );
  }
}

class DiaperDetail {
  final String time; // HH:mm
  final String label; // diaperName
  final String createdAt; // ISO

  DiaperDetail({
    required this.time,
    required this.label,
    required this.createdAt,
  });
}

/// Olay zamanına göre kronolojik sıralı kopya (zamanı okunamayanlar sonda).
List<DiaperModel> sortDiapersByEventTime(Iterable<DiaperModel> diapers) {
  final list = [...diapers];
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  list.sort((a, b) => (a.eventAt ?? epoch).compareTo(b.eventAt ?? epoch));
  return list;
}

/// Bez adını rapor kategorisine indirger: pee/poop/mixed/wet/dry/other.
String diaperTypeKey(String diaperName) {
  final name = diaperName.trim().toLowerCase();
  if (name.contains('pee')) return 'pee';
  if (name.contains('poo') || name.contains('dirty')) return 'poop';
  if (name.contains('mixed')) return 'mixed';
  if (name.contains('wet')) return 'wet';
  if (name.contains('dry')) return 'dry';
  return 'other';
}

/// Gösterilecek saat: kullanıcının seçtiği "HH:mm", yoksa kaydetme saati.
String diaperDisplayTime(DiaperModel d) {
  final hm = parseHourMinute(d.diaperTime);
  if (hm != null) {
    return '${hm.$1.toString().padLeft(2, '0')}:'
        '${hm.$2.toString().padLeft(2, '0')}';
  }
  final at = d.eventAt;
  return at != null ? DateFormat('HH:mm').format(at) : '-';
}
