// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// Emzirme kayıtları servisi (Realtime DB)
class NursingService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addNursing(NursingModel nursing) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('nursing')
        .child(user.uid)
        .child(createdAt)
        .set(nursing.toMap());
  }

  /// Tüm liste (aralıksız okuma)
  Future<List<NursingModel>> getNursingList() async {
    final List<NursingModel> nursings = [];
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('nursing').child(user.uid);
    final snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          for (final value in raw.values) {
            if (value is Map) {
              nursings.add(NursingModel.fromMap(Map<String, dynamic>.from(value)));
            }
          }
        } else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              nursings.add(NursingModel.fromMap(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
    return nursings;
  }

  /// Belirli bir tarih aralığındaki emzirmeleri getir (anahtar = epoch ms)
  Future<List<NursingModel>> getUserNursingsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('nursing').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs   = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final list = <NursingModel>[];
    for (final child in snap.children) {
      final val = child.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        // Map'te createdAt yoksa key'den üretelim (ISO):
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(
            int.parse(child.key!),
            isUtc: false,
          ).toIso8601String(),
        );
        list.add(NursingModel.fromMap(map));
      }
    }
    return list;
  }

  /// Günlük
  Future<List<NursingModel>> todayNursings() async {
    final now = DateTime.now().toLocal();
    return getUserNursingsInRange(now.startOfDay, now.endOfDay);
  }

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<NursingModel>> weekNursings() async {
    final now = DateTime.now().toLocal();
    return getUserNursingsInRange(now.startOfWeekTR, now.endOfWeekTR);
  }

  /// Aylık
  Future<List<NursingModel>> monthNursings() async {
    final now = DateTime.now().toLocal();
    return getUserNursingsInRange(now.startOfMonth, now.endOfMonth);
  }

  /// Bugünkü emzirme sayısı (stream)
  Stream<int> todayNursingCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('nursing').child(user.uid);

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

  /// TR için Pazartesi başlangıçlı hafta
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

final NursingService nursingService = NursingService();
