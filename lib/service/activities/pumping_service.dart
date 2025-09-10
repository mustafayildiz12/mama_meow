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

  Future<List<PumpingModel>> getDiaperList() async {
    final List<PumpingModel> pumpings = [];
    final user = authenticationService.getUser()!;
    final DatabaseReference ref = _realtimeDatabase
        .ref('pumpings')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;

      if (raw is Map) {
        for (final value in raw.values) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            final model = PumpingModel.fromMap(map);

            pumpings.add(model);
          }
        }
      } // 2) Kaynak veri LIST ise (örn: [null, {...}, null, {...}])
      else if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final model = PumpingModel.fromMap(map);

            pumpings.add(model);
          }
        }
      }
    }

    return pumpings;
  }

  Stream<int> todayPumpingCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('pumpings').child(user.uid);

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

final PumpingService pumpingService = PumpingService();
