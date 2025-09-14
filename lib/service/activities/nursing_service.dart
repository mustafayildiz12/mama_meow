// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// NursingService sınıfı, Firebase Realtime Database ile etkileşim için gerekli metodları içerir.
/// Emzirme kayıtlarının yönetimini sağlar.
class NursingService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Yeni bir emzirme kaydını Firebase'e ekler.
  /// @param nursing - Eklenecek emzirme modeli
  Future<void> addNursing(NursingModel nursing) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('nursing')
        .child(user.uid)
        .child(createdAt)
        .set(nursing.toMap());
  }

  Future<List<NursingModel>> getNursingList() async {
    final List<NursingModel> nursings = [];
    final user = authenticationService.getUser()!;

    final DatabaseReference ref = _realtimeDatabase
        .ref('nursing')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;

        if (raw is Map) {
          for (final value in raw.values) {
            if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              final model = NursingModel.fromMap(map);

              nursings.add(model);
            }
          }
        } else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final model = NursingModel.fromMap(map);

              nursings.add(model);
            }
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }

    return nursings;
  }

  Stream<int> todayNursingCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('nursing').child(user.uid);

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

final NursingService nursingService = NursingService();