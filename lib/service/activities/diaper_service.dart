// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class DiaperService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addDiaper(DiaperModel diaper) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('diapers')
        .child(user.uid)
        .child(createdAt)
        .set(diaper.toMap());
  }

  Future<List<DiaperModel>> getDiaperList() async {
    final List<DiaperModel> diapers = [];
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('diapers').child(user.uid);
    final snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          for (final value in raw.values) {
            if (value is Map) {
              diapers.add(DiaperModel.fromMap(Map<String, dynamic>.from(value)));
            }
          }
        } else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              diapers.add(DiaperModel.fromMap(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
    return diapers;
  }

  /// Belirli bir tarih aralığındaki diaper kayıtları (anahtar = epoch ms)
  Future<List<DiaperModel>> getUserDiapersInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('diapers').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs   = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final list = <DiaperModel>[];
    for (final child in snap.children) {
      final val = child.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        // Map'te createdAt yoksa key'den ISO üret:
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(
            int.parse(child.key!),
            isUtc: false,
          ).toIso8601String(),
        );
        list.add(DiaperModel.fromMap(map));
      }
    }
    return list;
  }

  /// Günlük
  Future<List<DiaperModel>> todayDiapers() async {
    final now = DateTime.now().toLocal();
    return getUserDiapersInRange(now.startOfDay, now.endOfDay);
  }

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<DiaperModel>> weekDiapers() async {
    final now = DateTime.now().toLocal();
    return getUserDiapersInRange(now.startOfWeekTR, now.endOfWeekTR);
  }

  /// Aylık
  Future<List<DiaperModel>> monthDiapers() async {
    final now = DateTime.now().toLocal();
    return getUserDiapersInRange(now.startOfMonth, now.endOfMonth);
  }

  Stream<int> todayDiaperCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('diapers').child(user.uid);

    final now = DateTime.now().toLocal();
    final startMs = now.startOfDay.millisecondsSinceEpoch;
    final endMs   = now.endOfDay.millisecondsSinceEpoch;

    return ref
        .orderByKey()
        .startAt(startMs.toString())
        .endAt(endMs.toString())
        .onValue
        .map((event) => event.snapshot.children.length);
  }
}

extension DateParts on DateTime {
  DateTime get startOfDay   => DateTime(year, month, day);
  DateTime get endOfDay     => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeekTR {
    final diff = weekday - DateTime.monday; // Pazartesi=1
    return DateTime(year, month, day).subtract(Duration(days: diff)).startOfDay;
  }
  DateTime get endOfWeekTR  => startOfWeekTR.add(const Duration(days: 6)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month, 1).startOfDay;
  DateTime get endOfMonth {
    final firstNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(milliseconds: 1));
  }
}

final DiaperService diaperService = DiaperService();
