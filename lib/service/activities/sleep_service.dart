// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class SleepService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addSleep(SleepModel sleepModel) async {
    final user = authenticationService.getUser();
    if (user == null) return;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('sleeps')
        .child(user.uid)
        .child(createdAt)
        .set(sleepModel.toJson());
  }

  /// Tüm kayıtlar (anahtar aralığı olmadan okuma)
  Future<List<SleepModel>> getSleepList() async {
    final List<SleepModel> sleeps = [];
    final user = authenticationService.getUser();
    if (user == null) return sleeps;
    final DatabaseReference ref =
        _realtimeDatabase.ref('sleeps').child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;
      if (raw is Map) {
        for (final value in raw.values) {
          if (value is Map) {
            sleeps.add(SleepModel.fromJson(Map<String, dynamic>.from(value)));
          }
        }
      } else if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            sleeps.add(SleepModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    }
    return sleeps;
  }

  /// Belirli bir tarih aralığındaki sleep'leri getirir (anahtar = epoch ms)
  Future<List<SleepModel>> getUserSleepsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser();
    if (user == null) return [];
    final ref = _realtimeDatabase.ref('sleeps').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final list = <SleepModel>[];
    for (final child in snap.children) {
      final val = child.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        // createdAt alanı map’te yoksa key’den üretmek istersen:
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(
            int.parse(child.key!),
            isUtc: false,
          ).toIso8601String(),
        );
        list.add(SleepModel.fromJson(map));
      }
    }
    return list;
  }

  /// Günlük
  Future<List<SleepModel>> todaySleeps() async {
    final now = DateTime.now().toLocal();
    return getUserSleepsInRange(now.startOfDay, now.endOfDay);
  }

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<SleepModel>> weekSleeps() async {
    final now = DateTime.now().toLocal();
    return getUserSleepsInRange(now.startOfWeekTR, now.endOfWeekTR);
  }

  /// Aylık
  Future<List<SleepModel>> monthSleeps() async {
    final now = DateTime.now().toLocal();
    return getUserSleepsInRange(now.startOfMonth, now.endOfMonth);
  }

  /// Bugünkü kayıt sayısı (stream)
  Stream<int> todaySleepCountStream() {
    final user = authenticationService.getUser();
    if (user == null) return Stream.value(0);
    final ref = FirebaseDatabase.instance.ref('sleeps').child(user.uid);

    final now = DateTime.now().toLocal();
    final startMs = now.startOfDay.millisecondsSinceEpoch;
    final endMs = now.endOfDay.millisecondsSinceEpoch;

    return ref
        .orderByKey()
        .startAt(startMs.toString())
        .endAt(endMs.toString())
        .onValue
        .map((event) => event.snapshot.children.length);
  }
}

extension DateParts on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeekTR {
    final diff = weekday - DateTime.monday; // Pazartesi=1
    return DateTime(year, month, day).subtract(Duration(days: diff)).startOfDay;
  }

  DateTime get endOfWeekTR => startOfWeekTR.add(const Duration(days: 6)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month, 1).startOfDay;
  DateTime get endOfMonth {
    final firstNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(milliseconds: 1));
  }
}

final SleepService sleepService = SleepService();
