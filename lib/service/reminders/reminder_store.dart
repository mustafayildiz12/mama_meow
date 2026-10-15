import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';

/// Bir kategorinin hatırlatıcı listesi (GetStorage "info" kovası).
class ReminderStore {
  const ReminderStore(this.config);

  factory ReminderStore.of(ReminderCategory category) =>
      ReminderStore(category.config);

  final ReminderConfig config;

  /// Bozuk kayıtları atlayarak tümünü yükler.
  Future<List<ReminderItem>> loadAll() async {
    final raw = infoStorage.read(config.storageKey);
    if (raw is! String || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(ReminderItem.tryParse)
          .whereType<ReminderItem>()
          .toList();
    } catch (e) {
      debugPrint('ReminderStore(${config.category.name}) load failed: $e');
      return [];
    }
  }

  Future<void> saveAll(List<ReminderItem> items) async {
    await infoStorage.write(
      config.storageKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Yeni id üretir (mevcut kayıtlarla çakışmaz).
  Future<int> nextId() async {
    final stored = infoStorage.read(config.nextIdKey);
    var id = stored is int && stored > 0 ? stored : 1;
    for (final it in await loadAll()) {
      if (it.reminderId >= id) id = it.reminderId + 1;
    }
    await infoStorage.write(config.nextIdKey, id + 1);
    return id;
  }

  Future<bool> hasActive() async => (await loadAll()).any((e) => e.isActive);

  Future<void> clear() async {
    await infoStorage.remove(config.storageKey);
    await infoStorage.remove(config.nextIdKey);
  }
}
