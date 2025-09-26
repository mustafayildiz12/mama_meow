// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class MedicineService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addMedicine(MedicineModel medicine) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('medicine')
        .child(user.uid)
        .child(createdAt)
        .set(medicine.toMap());
  }

  Future<List<MedicineModel>> getMedicineList() async {
    final List<MedicineModel> medicines = [];
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('medicine').child(user.uid);
    final snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          for (final v in raw.values) {
            if (v is Map) medicines.add(MedicineModel.fromMap(Map<String, dynamic>.from(v)));
          }
        } else if (raw is List) {
          for (final v in raw) {
            if (v is Map) medicines.add(MedicineModel.fromMap(Map<String, dynamic>.from(v)));
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
    }
    return medicines;
  }

  /// Belirli tarih aralığı (Realtime DB key=epoch ms)
  Future<List<MedicineModel>> getUserMedicinesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('medicine').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs   = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final list = <MedicineModel>[];
    for (final c in snap.children) {
      final val = c.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        // Map'te createdAt yoksa key'den ISO üretelim:
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(int.parse(c.key!), isUtc: false).toIso8601String(),
        );
        list.add(MedicineModel.fromMap(map));
      }
    }
    return list;
  }

  Future<List<MedicineModel>> todayMedicines() async {
    final now = DateTime.now().toLocal();
    return getUserMedicinesInRange(now.startOfDay, now.endOfDay);
  }

  Future<List<MedicineModel>> weekMedicines() async {
    final now = DateTime.now().toLocal();
    return getUserMedicinesInRange(now.startOfWeekTR, now.endOfWeekTR);
  }

  Future<List<MedicineModel>> monthMedicines() async {
    final now = DateTime.now().toLocal();
    return getUserMedicinesInRange(now.startOfMonth, now.endOfMonth);
  }

  Stream<int> todayMedicineCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('medicine').child(user.uid);

    final now = DateTime.now().toLocal();
    final startMs = now.startOfDay.millisecondsSinceEpoch;
    final endMs   = now.endOfDay.millisecondsSinceEpoch;

    return ref
        .orderByKey()
        .startAt(startMs.toString())
        .endAt(endMs.toString())
        .onValue
        .map((e) => e.snapshot.children.length);
  }
}

extension DateParts on DateTime {
  DateTime get startOfDay   => DateTime(year, month, day);
  DateTime get endOfDay     => DateTime(year, month, day, 23, 59, 59, 999);

  /// TR: Pazartesi başlangıç
  DateTime get startOfWeekTR {
    final diff = weekday - DateTime.monday;
    return DateTime(year, month, day).subtract(Duration(days: diff)).startOfDay;
  }
  DateTime get endOfWeekTR  => startOfWeekTR.add(const Duration(days: 6)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month, 1).startOfDay;
  DateTime get endOfMonth {
    final firstNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(milliseconds: 1));
  }
}

final MedicineService medicineService = MedicineService();
