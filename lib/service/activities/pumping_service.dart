// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class PumpingService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addPumping(PumpingModel pumping) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('pumpings')
        .child(user.uid)
        .child(createdAt)
        .set(pumping.toMap());
  }

  /// Tüm liste (aralıksız)
  Future<List<PumpingModel>> getPumpingList() async {
    final List<PumpingModel> list = [];
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('pumpings').child(user.uid);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;
      if (raw is Map) {
        for (final v in raw.values) {
          if (v is Map) list.add(PumpingModel.fromMap(Map<String, dynamic>.from(v)));
        }
      } else if (raw is List) {
        for (final v in raw) {
          if (v is Map) list.add(PumpingModel.fromMap(Map<String, dynamic>.from(v)));
        }
      }
    }
    return list;
  }

  /// GEÇİCİ UYUMLULUK: Eski ismi çağıran yerler kırılmasın diye bırakıldı.
  @Deprecated('Use getPumpingList()')
  Future<List<PumpingModel>> getDiaperList() => getPumpingList();

  /// Belirli tarih aralığı (key = epoch ms)
  Future<List<PumpingModel>> getUserPumpingsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('pumpings').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs   = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final out = <PumpingModel>[];
    for (final child in snap.children) {
      final val = child.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(int.parse(child.key!), isUtc: false).toIso8601String(),
        );
        out.add(PumpingModel.fromMap(map));
      }
    }
    return out;
  }

  Future<List<PumpingModel>> todayPumpings() async {
    final now = DateTime.now().toLocal();
    return getUserPumpingsInRange(now.startOfDay, now.endOfDay);
  }

  Future<List<PumpingModel>> weekPumpings() async {
    final now = DateTime.now().toLocal();
    return getUserPumpingsInRange(now.startOfWeekTR, now.endOfWeekTR);
  }

  Future<List<PumpingModel>> monthPumpings() async {
    final now = DateTime.now().toLocal();
    return getUserPumpingsInRange(now.startOfMonth, now.endOfMonth);
  }

  Stream<int> todayPumpingCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('pumpings').child(user.uid);
    final now = DateTime.now().toLocal();
    final startMs = now.startOfDay.millisecondsSinceEpoch.toString();
    final endMs   = now.endOfDay.millisecondsSinceEpoch.toString();

    return ref
        .orderByKey()
        .startAt(startMs)
        .endAt(endMs)
        .onValue
        .map((e) => e.snapshot.children.length);
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
    final firstNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(milliseconds: 1));
  }
}

final PumpingService pumpingService = PumpingService();
