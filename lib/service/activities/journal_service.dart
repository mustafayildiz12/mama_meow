// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// JournalService sınıfı, Firebase Realtime Database ile journal notları için etkileşim sağlar.
/// Günlük notların eklenmesi, listelenmesi ve gerçek zamanlı takibi için metodları içerir.
class JournalService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Yeni bir journal notu ekler.
  /// @param journalModel - Eklenecek journal modeli
  Future<void> addJournalNote(JournalModel journalModel) async {
    final user = authenticationService.getUser()!;
    await _realtimeDatabase
        .ref('journal')
        .child(user.uid)
        .child(journalModel.noteId)
        .set(journalModel.toJson());
  }

  /// Belirli bir tarihe ait notları getirir.
  /// @param date - yyyy-MM-dd formatında tarih
  Future<List<JournalModel>> getNotesForDate(String date) async {
    final List<JournalModel> notes = [];

    final user = authenticationService.getUser()!;
    final DatabaseReference ref = _realtimeDatabase
        .ref('journal')
        .child(user.uid);

    final DataSnapshot snapshot = await ref
        .orderByChild('noteDate')
        .equalTo(date)
        .get();

    if (snapshot.exists) {
      final raw = snapshot.value;

      if (raw is Map) {
        for (final value in raw.values) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            final model = JournalModel.fromJson(map);
            notes.add(model);
          }
        }
      }
    }

    // Tarihe göre sırala (en yeni en üstte)
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  /// Bugünkü notların sayısını gerçek zamanlı olarak takip eder.
  Stream<int> todayNoteCountStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('journal').child(user.uid);
    
    final today = _formatDate(DateTime.now());

    return ref
        .orderByChild('noteDate')
        .equalTo(today)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return 0;
          
          final raw = event.snapshot.value;
          if (raw is Map) {
            return raw.length;
          }
          return 0;
        });
  }

  /// Bugünkü notları gerçek zamanlı olarak takip eder.
  Stream<List<JournalModel>> todayNotesStream() {
    final user = authenticationService.getUser()!;
    final ref = FirebaseDatabase.instance.ref('journal').child(user.uid);
    
    final today = _formatDate(DateTime.now());

    return ref
        .orderByChild('noteDate')
        .equalTo(today)
        .onValue
        .map((event) {
          final List<JournalModel> notes = [];
          
          if (!event.snapshot.exists) return notes;
          
          final raw = event.snapshot.value;
          if (raw is Map) {
            for (final value in raw.values) {
              if (value is Map) {
                final map = Map<String, dynamic>.from(value);
                final model = JournalModel.fromJson(map);
                notes.add(model);
              }
            }
          }
          
          // Tarihe göre sırala (en yeni en üstte)
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notes;
        });
  }

  /// Tüm journal notlarını getirir.
  Future<List<JournalModel>> getAllNotes() async {
    final List<JournalModel> notes = [];

    final user = authenticationService.getUser()!;
    final DatabaseReference ref = _realtimeDatabase
        .ref('journal')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;

      if (raw is Map) {
        for (final value in raw.values) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            final model = JournalModel.fromJson(map);
            notes.add(model);
          }
        }
      }
    }

    // Tarihe göre sırala (en yeni en üstte)
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  /// DateTime'ı yyyy-MM-dd formatına çevirir
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
}

final JournalService journalService = JournalService();