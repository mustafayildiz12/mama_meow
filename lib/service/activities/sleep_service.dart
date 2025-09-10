// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// TercihService sınıfı, Firebase Realtime Database ile etkileşim için gerekli metodları içerir.
/// Kullanıcı tercihleri, sınav bilgileri ve diğer verilerin yönetimini sağlar.
class SleepService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Yeni bir kullanıcıyı Firebase'e ekler.
  /// @param user - Eklenecek kullanıcı modeli
  Future<void> addSleep(SleepModel sleepModel) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('sleeps')
        .child(user.uid)
        .child(createdAt)
        .set(sleepModel.toJson());
  }

  Future<List<SleepModel>> getSleepList() async {
    final List<SleepModel> sleeps = [];

    final user = authenticationService.getUser()!;
    final DatabaseReference ref = _realtimeDatabase
        .ref('sleeps')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;

      if (raw is Map) {
        for (final value in raw.values) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            final model = SleepModel.fromJson(map);

            sleeps.add(model);
          }
        }
      } // 2) Kaynak veri LIST ise (örn: [null, {...}, null, {...}])
      else if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final model = SleepModel.fromJson(map);

            sleeps.add(model);
          }
        }
      }
    }

    return sleeps;
  }

  Stream<int> todaySleepCountStream() {
    final user = authenticationService.getUser()!;
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

extension _Today on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

final SleepService sleepService = SleepService();
