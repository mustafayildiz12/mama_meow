/// Tüm aktiviteler (servisler, rapor sayfaları, AI servisleri, PDF'ler) için
/// ortak rapor dönemi ve tarih aralığı yardımcıları.
library;

/// Rapor ekranlarındaki "Bugün / Hafta / Ay" seçimi.
enum ReportPeriod { today, week, month }

extension DateParts on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Haftanın başlangıcı (Pazartesi 00:00).
  ///
  /// `subtract(Duration(days: n))` yerine takvim aritmetiği kullanılır; böylece
  /// yaz saati geçişi olan haftalarda gün kayması olmaz.
  DateTime get startOfWeekTR =>
      DateTime(year, month, day - (weekday - DateTime.monday));

  /// Haftanın sonu (Pazar 23:59:59.999).
  DateTime get endOfWeekTR => DateTime(
    year,
    month,
    day - (weekday - DateTime.monday) + 6,
    23,
    59,
    59,
    999,
  );

  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Ayın son milisaniyesi. `DateTime(y, 13, 1)` bir sonraki yılın Ocak ayına
  /// normalize edildiği için Aralık ayı ayrıca ele alınmaz.
  DateTime get endOfMonth =>
      DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

  /// Ayın gün sayısı (bir sonraki ayın 0. günü = bu ayın son günü).
  int get daysInMonth => DateTime(year, month + 1, 0).day;
}

/// Kapalı (her iki ucu dahil) tarih aralığı. `end` her zaman günün son
/// milisaniyesidir; mevcut RTDB `startAt/endAt` sorgularıyla uyumludur.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  factory DateRange.forPeriod(ReportPeriod period, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return switch (period) {
      ReportPeriod.today => DateRange(n.startOfDay, n.endOfDay),
      ReportPeriod.week => DateRange(n.startOfWeekTR, n.endOfWeekTR),
      ReportPeriod.month => DateRange(n.startOfMonth, n.endOfMonth),
    };
  }

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);

  /// Aralıktaki takvim günü sayısı (hafta = 7, Şubat = 28/29 ...).
  int get dayCount => _daysBetween(start, end) + 1;

  /// Aralığın bugüne kadar geçen gün sayısı (en az 1). Ortalama "günlük
  /// sıklık" hesaplarında, hafta/ay ortasında sabit 7/30'a bölmek yerine
  /// kullanılır.
  int elapsedDays({DateTime? now}) {
    final n = now ?? DateTime.now();
    final last = n.isBefore(end) ? n : end;
    if (last.isBefore(start)) return 1;
    return _daysBetween(start, last) + 1;
  }

  static int _daysBetween(DateTime a, DateTime b) {
    // UTC'ye çevirerek DST kaynaklı 23/25 saatlik günleri yok sayıyoruz.
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }
}

/// Kullanıcının seçtiği "HH:mm" saatini, kaydın oluşturulma anına ([savedAt])
/// göre tam bir tarihe çevirir.
///
/// Aktivite kayıtlarının anahtarı/`createdAt` alanı *kaydetme* anıdır; olayın
/// gerçek saati ayrıca "HH:mm" olarak tutulur. Seçilen saat kaydetme anından
/// ilerideyse olay bir önceki güne aittir (ör. 23:50'deki bez değişimi 00:05'te
/// kaydedildiyse). Saat okunamazsa [savedAt] döner.
DateTime resolveEventTime(DateTime savedAt, String? hhmm) {
  final parsed = parseHourMinute(hhmm);
  if (parsed == null) return savedAt;
  var t = DateTime(
    savedAt.year,
    savedAt.month,
    savedAt.day,
    parsed.$1,
    parsed.$2,
  );
  // Birkaç dakikalık saat farkı toleransı: "şimdi" seçilip hemen kaydedilen
  // kayıtlar dünü göstermesin.
  if (t.isAfter(savedAt.add(const Duration(minutes: 5)))) {
    t = DateTime(t.year, t.month, t.day - 1, t.hour, t.minute);
  }
  return t;
}

/// "HH:mm" / "H:mm" metnini (saat, dakika) olarak ayrıştırır; geçersizse null.
(int, int)? parseHourMinute(String? hhmm) {
  if (hhmm == null) return null;
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(hhmm);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return (h, min);
}
