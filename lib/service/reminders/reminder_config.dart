import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

/// Hatırlatıcı kategorileri.
///
/// DİKKAT: [idIndex] işletim sistemine kurulmuş bildirim ID'lerinin bir
/// parçasıdır (bkz. [ReminderConfig.notificationId]); değerleri asla
/// değiştirmeyin, yeni kategori eklenirse sıradaki boş index'i verin.
enum ReminderCategory {
  nursing(0),
  solid(1),
  sleep(2),
  diaper(3),
  pumping(4),
  medicine(5);

  const ReminderCategory(this.idIndex);

  final int idIndex;

  ReminderConfig get config => ReminderConfig.of(this);
}

/// Bir hatırlatıcı kategorisinin tüm sabitleri: Android kanalı, bildirim
/// metinleri, kalıcı depolama anahtarları, ekran metinleri, görünüm ve
/// analytics isimleri.
///
/// Bildirim ID şeması (32-bit int içinde, kategoriler arası çakışmasız):
///
///     id = 100_000_000 + idIndex * 10_000_000 + reminderId * 10 + slot
///
/// - slot 0 = günlük (7 günün hepsi seçili → tek bildirim, iOS 64 limiti),
///   slot 1..7 = haftanın günü (1 = Mon … 7 = Sun).
/// - reminderId < 1_000_000 olduğu sürece kategoriler çakışmaz;
///   en büyük ID 159_999_999 < 2^31 - 1.
/// - 90001-90003 → ReEngagementService (sabit, bu aralığın dışında).
/// - Eski şema (≤ 1.0.19): `legacyIdBase + reminderId * 10 + weekday`
///   (8000…13000 tabanlı; reminderId ≥ 100 olunca komşu kategoriye taşıyordu).
///   Eski ID'ler her iptal/yeniden kurulumda ayrıca iptal edilir.
class ReminderConfig {
  ReminderConfig._({
    required this.category,
    required this.label,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.notificationTitle,
    required this.notificationBodyPrefix,
    required this.legacyIdBase,
    required this.storageKey,
    required this.nextIdKey,
    required this.cardIcon,
    required this.editorIcon,
    required this.gradient,
    required this.accent,
    required this.managerScreenName,
    required this.editorScreenName,
  });

  final ReminderCategory category;

  /// Ekran metinlerinde kullanılan ad: "Diaper" → "Diaper Reminders".
  final String label;

  final String channelId;
  final String channelName;
  final String channelDescription;

  final String notificationTitle;

  /// Gövde: `'$notificationBodyPrefix HH:mm'`.
  final String notificationBodyPrefix;

  final int legacyIdBase;

  /// GetStorage ("info") anahtarları — mevcut kullanıcı verisi, değiştirmeyin.
  final String storageKey;
  final String nextIdKey;

  final IconData cardIcon;
  final IconData editorIcon;

  /// İkon zemini (ilk renk) için yumuşak tonlar. Aktiviteler renkle değil
  /// ikonla ayrışır: zeminler pembe / şeftali dönüşümlüdür (bkz. ActivityKind).
  final List<Color> gradient;

  /// Vurgu rengi (ikon, seçili gün çipi) — tüm kategorilerde Active Berry.
  final Color accent;

  final String managerScreenName;
  final String editorScreenName;

  String get screenTitle => '$label Reminders';
  String get newReminderTitle => 'New $label Reminder';
  String get editReminderTitle => 'Edit $label Reminder';

  String notificationBody(TimeOfDay t) =>
      '$notificationBodyPrefix${_two(t.hour)}:${_two(t.minute)}';

  static const int idRangeStart = 100000000;
  static const int _idCategoryStride = 10000000;
  static const int maxReminderId = 999999;

  // Eski şemadaki ID aralığı (re-engagement 90001+ hariç).
  static const int _legacyRangeStart = 8000;
  static const int _legacyRangeEnd = 90000;

  int notificationId(int reminderId, int slot) {
    assert(reminderId >= 0 && reminderId <= maxReminderId);
    assert(slot >= 0 && slot <= 7);
    return idRangeStart +
        category.idIndex * _idCategoryStride +
        reminderId * 10 +
        slot;
  }

  int legacyNotificationId(int reminderId, int weekday) =>
      legacyIdBase + reminderId * 10 + weekday;

  /// Bildirim ID'si (yeni ya da eski şemada) herhangi bir hatırlatıcıya mı ait?
  static bool isReminderNotificationId(int id) {
    final newEnd =
        idRangeStart + ReminderCategory.values.length * _idCategoryStride;
    return (id >= idRangeStart && id < newEnd) ||
        (id >= _legacyRangeStart && id < _legacyRangeEnd);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static ReminderConfig of(ReminderCategory c) => switch (c) {
    ReminderCategory.nursing => nursing,
    ReminderCategory.solid => solid,
    ReminderCategory.sleep => sleep,
    ReminderCategory.diaper => diaper,
    ReminderCategory.pumping => pumping,
    ReminderCategory.medicine => medicine,
  };

  static final ReminderConfig nursing = ReminderConfig._(
    category: ReminderCategory.nursing,
    label: 'Nursing',
    channelId: 'nursing_reminders',
    channelName: 'Nursing Reminders',
    channelDescription: 'Nursing-related scheduled reminders',
    notificationTitle:
        'Time for a cozy cuddle & feed! 🤱🐾 Coo Care Baby Tracker’s got your back',
    notificationBodyPrefix: '👶 Time ',
    legacyIdBase: 8000,
    storageKey: 'nursing_reminders_list_v1',
    nextIdKey: 'nursing_reminders_next_id_v1',
    cardIcon: Icons.access_time,
    editorIcon: Icons.access_time,
    gradient: const [AppColors.pinkTint, AppColors.peachTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'reminder_manager_page',
    editorScreenName: 'nursing_reminder_sheet',
  );

  static final ReminderConfig solid = ReminderConfig._(
    category: ReminderCategory.solid,
    label: 'Solid',
    channelId: 'solid_reminders',
    channelName: 'Solid Reminders',
    channelDescription: 'Solid-food related scheduled reminders',
    notificationTitle: 'You’re doing great, mama — time to feed 💕🐱',
    notificationBodyPrefix: '👶 Time ',
    legacyIdBase: 9000,
    storageKey: 'solid_reminders_list_v1',
    nextIdKey: 'solid_reminders_next_id_v1',
    cardIcon: Icons.restaurant,
    editorIcon: Icons.access_time,
    gradient: const [AppColors.peachTint, AppColors.pinkTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'solid_reminder_manager',
    editorScreenName: 'solid_reminder_editor',
  );

  static final ReminderConfig sleep = ReminderConfig._(
    category: ReminderCategory.sleep,
    label: 'Sleep',
    channelId: 'sleep_reminders',
    channelName: 'Sleep Reminders',
    channelDescription: 'Sleep-related scheduled reminders',
    notificationTitle: 'Purrfect time for a nap, little dreamer 😺💤',
    notificationBodyPrefix: '👶 Time ',
    legacyIdBase: 10000,
    storageKey: 'sleep_reminders_list_v1',
    nextIdKey: 'sleep_reminders_next_id_v1',
    cardIcon: Icons.nightlight_round,
    editorIcon: Icons.nightlight_round,
    gradient: const [AppColors.pinkTint, AppColors.peachTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'sleep_reminder_manager',
    editorScreenName: 'sleep_reminder_editor',
  );

  static final ReminderConfig diaper = ReminderConfig._(
    category: ReminderCategory.diaper,
    label: 'Diaper',
    channelId: 'diaper_reminders',
    channelName: 'Diaper Reminders',
    channelDescription: 'Diaper-change related scheduled reminders',
    notificationTitle: 'Diaper duty, mama! You got this 💪😺',
    notificationBodyPrefix: '👶 Time ',
    legacyIdBase: 11000,
    storageKey: 'diaper_reminders_list_v1',
    nextIdKey: 'diaper_reminders_next_id_v1',
    cardIcon: Icons.baby_changing_station,
    editorIcon: Icons.baby_changing_station,
    gradient: const [AppColors.peachTint, AppColors.pinkTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'diaper_reminder_manager',
    editorScreenName: 'diaper_reminder_editor',
  );

  static final ReminderConfig pumping = ReminderConfig._(
    category: ReminderCategory.pumping,
    label: 'Pumping',
    channelId: 'pumping_reminders',
    channelName: 'Pumping Reminders',
    channelDescription: 'Breast milk pumping scheduled reminders',
    notificationTitle: 'Little paws need milk power! 🐾💖 Ready to pump?',
    notificationBodyPrefix: '👶 Time ',
    legacyIdBase: 12000,
    storageKey: 'pumping_reminders_list_v1',
    nextIdKey: 'pumping_reminders_next_id_v1',
    cardIcon: Icons.health_and_safety,
    editorIcon: Icons.alarm,
    gradient: const [AppColors.pinkTint, AppColors.peachTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'pumping_reminder_manager',
    editorScreenName: 'pumping_reminder_editor',
  );

  static final ReminderConfig medicine = ReminderConfig._(
    category: ReminderCategory.medicine,
    label: 'Medicine',
    channelId: 'medicine_reminders',
    channelName: 'Medicine Reminders',
    channelDescription: 'Medication intake scheduled reminders',
    notificationTitle: 'Coo Care Baby Tracker – Medicine Reminder',
    notificationBodyPrefix: 'Time ',
    legacyIdBase: 13000,
    storageKey: 'medicine_reminders_list_v1',
    nextIdKey: 'medicine_reminders_next_id_v1',
    cardIcon: Icons.medical_services,
    editorIcon: Icons.medical_services,
    gradient: const [AppColors.peachTint, AppColors.pinkTint],
    accent: AppColors.activeBerry,
    managerScreenName: 'medicine_reminder_manager',
    editorScreenName: 'medicine_reminder_editor',
  );
}
