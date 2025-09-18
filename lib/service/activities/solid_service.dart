import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class SolidService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addSolid(SolidModel solid) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('solids')
        .child(user.uid)
        .child(createdAt)
        .set(solid.toMap());
  }

  Future<List<SolidModel>> getUserSolidList() async {
    final List<SolidModel> sleeps = [];
    final user = authenticationService.getUser()!;
    final DatabaseReference ref = _realtimeDatabase
        .ref('solids')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;

        if (raw is Map) {
          for (final value in raw.values) {
            if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              final model = SolidModel.fromMap(map);

              sleeps.add(model);
            }
          }
        } // 2) Kaynak veri LIST ise (örn: [null, {...}, null, {...}])
        else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final model = SolidModel.fromMap(map);

              sleeps.add(model);
            }
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }

    return sleeps;
  }

  /// Belirli bir tarih aralığındaki solid'leri getirir (anahtar = epoch ms)
  Future<List<SolidModel>> getUserSolidsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('solids').child(user.uid);

    final startMs = start.toLocal().millisecondsSinceEpoch.toString();
    final endMs = end.toLocal().millisecondsSinceEpoch.toString();

    final snap = await ref.orderByKey().startAt(startMs).endAt(endMs).get();

    final list = <SolidModel>[];
    for (final child in snap.children) {
      final val = child.value;
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        // DB'ye yazarken createdAt alanı map'te yoksa key'den üretelim:
        map.putIfAbsent(
          'createdAt',
          () => DateTime.fromMillisecondsSinceEpoch(
            int.parse(child.key!),
            isUtc: false,
          ).toIso8601String(),
        );
        list.add(SolidModel.fromMap(map));
      }
    }
    return list;
  }

  Stream<int> todaySolidCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('solids').child(user.uid);

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

  /// TR için Pazartesi başlangıç
  DateTime get startOfWeekTR {
    // DateTime.monday = 1
    final diff = weekday - DateTime.monday; // Pazartesi ise 0
    return DateTime(year, month, day).subtract(Duration(days: diff)).startOfDay;
  }

  DateTime get endOfWeekTR =>
      startOfWeekTR.add(const Duration(days: 6)).endOfDay;

  // Aylık
  DateTime get startOfMonth => DateTime(year, month, 1).startOfDay;
  DateTime get endOfMonth {
    final firstNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(milliseconds: 1));
  }

  int get daysInMonth {
    final firstNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }
}

final SolidService solidService = SolidService();
