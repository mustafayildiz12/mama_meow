import 'package:mama_meow/service/reminders/reminder_scheduler.dart';

export 'package:mama_meow/models/reminders/reminder_item.dart';
export 'package:mama_meow/service/reminders/reminder_config.dart';
export 'package:mama_meow/service/reminders/reminder_scheduler.dart';
export 'package:mama_meow/service/reminders/reminder_store.dart';

/// Tüm kategorilerdeki hatırlatıcı bildirimlerini (eski ID'ler dahil) iptal
/// eder ve hatırlatıcı listelerini siler. Çıkış ve hesap silmede çağrılır;
/// hata fırlatmaz.
Future<void> cancelAndClearAllReminders() =>
    ReminderScheduler.instance.cancelAndClearAll();
