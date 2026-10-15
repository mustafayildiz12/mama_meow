import 'package:timezone/timezone.dart' as tz;

/// [hour]:[minute] saatinin (verildiyse [weekday] gününde) yerel saatle bir
/// sonraki oluşumu.
///
/// Gün eklemeyi `Duration` ile değil takvim alanlarıyla yapar; böylece yaz
/// saati (DST) geçişlerinde duvar saati kaymaz.
tz.TZDateTime nextInstanceOf({
  required int hour,
  required int minute,
  int? weekday,
  tz.TZDateTime? from,
}) {
  final now = from ?? tz.TZDateTime.now(tz.local);
  var days = weekday == null ? 0 : (weekday - now.weekday + 7) % 7;

  tz.TZDateTime at(int addDays) => tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + addDays,
    hour,
    minute,
  );

  var result = at(days);
  if (!result.isAfter(now)) {
    days += weekday == null ? 1 : 7;
    result = at(days);
  }
  return result;
}

/// [from]'dan [days] takvim günü sonrası, saat [hour]:00 (DST güvenli).
tz.TZDateTime atHourAfterDays(
  tz.TZDateTime from, {
  required int days,
  required int hour,
}) {
  return tz.TZDateTime(
    from.location,
    from.year,
    from.month,
    from.day + days,
    hour,
  );
}
