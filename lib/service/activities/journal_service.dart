// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class JournalService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  DatabaseReference _userRef() {
    final user = authenticationService.getUser()!;
    return _realtimeDatabase.ref('journal').child(user.uid);
  }

  Future<void> addJournalNote(JournalModel journalModel) async {
    await _userRef().child(journalModel.noteId).set(journalModel.toJson());
  }

  // ---- NEW: tek seferlik "bugün" notları
  Future<List<JournalModel>> todayNotesOnce() async {
    final today = _formatDate(DateTime.now());
    return getNotesForDateOnce(today);
  }

  // ---- NEW: tek seferlik "belirli gün" notları
  Future<List<JournalModel>> getNotesForDateOnce(String date) async {
    final snap = await _userRef()
        .orderByChild('noteDate')
        .equalTo(date)
        .get();

    final notes = <JournalModel>[];
    if (snap.exists) {
      final raw = snap.value;
      if (raw is Map) {
        for (final v in raw.values) {
          if (v is Map) {
            notes.add(JournalModel.fromJson(Map<String, dynamic>.from(v)));
          }
        }
      }
    }
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  // Mevcut isim korunuyor ama “Once” versiyonunu kullanman daha pratik:
  Future<List<JournalModel>> getNotesForDate(String date) => getNotesForDateOnce(date);

  // ---- NEW: tarih aralığı (yyyy-MM-dd ile lexicographic)
  Future<List<JournalModel>> getNotesInRange(DateTime start, DateTime end) async {
    final s = _formatDate(start);
    final e = _formatDate(end);
    final snap = await _userRef()
        .orderByChild('noteDate')
        .startAt(s)
        .endAt(e)
        .get();

    final list = <JournalModel>[];
    if (snap.exists) {
      final raw = snap.value;
      if (raw is Map) {
        for (final v in raw.values) {
          if (v is Map) {
            list.add(JournalModel.fromJson(Map<String, dynamic>.from(v)));
          }
        }
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---- NEW: belirli gün için stream (genellenmiş)
  Stream<List<JournalModel>> notesForDateStream(String date) {
    return _userRef()
        .orderByChild('noteDate')
        .equalTo(date)
        .onValue
        .map((event) {
          final notes = <JournalModel>[];
          if (!event.snapshot.exists) return notes;

          final raw = event.snapshot.value;
          if (raw is Map) {
            for (final v in raw.values) {
              if (v is Map) {
                notes.add(JournalModel.fromJson(Map<String, dynamic>.from(v)));
              }
            }
          }
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notes;
        });
  }

  // Mevcut: bugünkü not sayısı
  Stream<int> todayNoteCountStream() {
    final today = _formatDate(DateTime.now());
    return _userRef()
        .orderByChild('noteDate')
        .equalTo(today)
        .onValue
        .map((e) {
          if (!e.snapshot.exists) return 0;
          final raw = e.snapshot.value;
          if (raw is Map) return raw.length;
          return 0;
        });
  }

  // Mevcut: bugünkü not stream’i
  Stream<List<JournalModel>> todayNotesStream() => notesForDateStream(_formatDate(DateTime.now()));

  // Mevcut: tüm notlar (genelde arama/arsiv için)
  Future<List<JournalModel>> getAllNotes() async {
    final snap = await _userRef().get();
    final list = <JournalModel>[];
    if (snap.exists) {
      final raw = snap.value;
      if (raw is Map) {
        for (final v in raw.values) {
          if (v is Map) list.add(JournalModel.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---- NEW: upsert helpers ----

  /// Bugün için yeni bir not ekler (noteId = epoch ms). Günlükte çoklu not’a izin verir.
  Future<String> upsertTodayNote(String text) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final model = JournalModel(
      noteId: id,
      noteText: text,
      noteDate: _formatDate(now),
      createdAt: now.toIso8601String(),
      // diğer alanların varsa doldur
    );
    await addJournalNote(model);
    return id;
  }

  /// Var olan notu günceller (tam model gönder).
  Future<void> updateNote(JournalModel note) async {
    await _userRef().child(note.noteId).update(note.toJson());
  }

  /// Not sil
  Future<void> deleteNote(String noteId) async {
    await _userRef().child(noteId).remove();
  }

  /// (Opsiyonel) Her güne yalnızca bir not istersen:
  /// Varsa o günü günceller, yoksa yeni not oluşturur.
  Future<String> setDailyNote(String text, {DateTime? day}) async {
    final d = day ?? DateTime.now();
    final keyDate = _formatDate(d);
    final existing = await getNotesForDateOnce(keyDate);
    if (existing.isNotEmpty) {
      final latest = existing.first; // en yeniyi güncelle
      final updated = latest.copyWith(
        noteText: text,
        createdAt: DateTime.now().toIso8601String(),
      );
      await updateNote(updated);
      return latest.noteId;
    } else {
      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch.toString();
      final model = JournalModel(
        noteId: id,
        noteText: text,
        noteDate: keyDate,
        createdAt: now.toIso8601String(),
      );
      await addJournalNote(model);
      return id;
    }
  }

  // ---- utils ----
  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
           '${d.month.toString().padLeft(2, '0')}-'
           '${d.day.toString().padLeft(2, '0')}';
  }
}

final JournalService journalService = JournalService();
