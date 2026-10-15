import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/journal_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// Günlük notları: `journal/<uid>/<noteId>`.
class JournalService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Giriş yoksa null (okumalar boş döner).
  DatabaseReference? _userRefOrNull() {
    final user = authenticationService.getUser();
    if (user == null) return null;
    return _realtimeDatabase.ref('journal').child(user.uid);
  }

  /// Yazma işlemleri için; giriş yoksa anlaşılır bir hata fırlatır.
  DatabaseReference _requireUserRef() {
    final ref = _userRefOrNull();
    if (ref == null) {
      throw StateError('Journal write requires a signed-in user.');
    }
    return ref;
  }

  Future<void> addJournalNote(JournalModel journalModel) async {
    await ActivityRtdb.write(
      _requireUserRef().child(journalModel.noteId).set(journalModel.toJson()),
      label: 'journal add',
    );
    unawaited(analyticService.activityLogged('journal'));
  }

  /// Belirli gün (yyyy-MM-dd) notları, en yeni önce.
  Future<List<JournalModel>> getNotesForDateOnce(String date) async {
    final ref = _userRefOrNull();
    if (ref == null) return [];
    final snap = await ref.orderByChild('noteDate').equalTo(date).get();
    return _decodeSorted(snap);
  }

  /// Tarih aralığı (yyyy-MM-dd ile lexicographic), en yeni önce.
  Future<List<JournalModel>> getNotesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final ref = _userRefOrNull();
    if (ref == null) return [];
    final snap = await ref
        .orderByChild('noteDate')
        .startAt(_formatDate(start))
        .endAt(_formatDate(end))
        .get();
    return _decodeSorted(snap);
  }

  /// Var olan notu günceller (tam model gönder).
  Future<void> updateNote(JournalModel note) async {
    await ActivityRtdb.write(
      _requireUserRef().child(note.noteId).update(note.toJson()),
      label: 'journal update',
    );
  }

  /// Not sil
  Future<void> deleteNote(String noteId) async {
    await ActivityRtdb.write(
      _requireUserRef().child(noteId).remove(),
      label: 'journal delete',
    );
  }

  // ---- utils ----
  List<JournalModel> _decodeSorted(DataSnapshot snap) {
    final notes = <JournalModel>[];
    for (final child in snap.children) {
      final value = child.value;
      if (value is! Map) continue;
      try {
        notes.add(JournalModel.fromJson(Map<String, dynamic>.from(value)));
      } catch (e, st) {
        ActivityRtdb.reportNonFatal(
          e,
          st,
          reason: 'Skipped malformed journal record (${child.key})',
        );
      }
    }
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

final JournalService journalService = JournalService();
