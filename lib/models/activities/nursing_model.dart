import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

class NursingModel {
  final String side; // "Left", "Right" (biberonda boş)
  final String startTime; // "HH:mm"
  final int duration; // minutes
  final String feedingType; // "nursing" or "bottle"
  final String? milkType; // only if feedingType is "bottle"
  final String amountType; // "oz" or "ml"
  final num amount; // amount value
  final String createdAt; // ISO string

  NursingModel({
    required this.side,
    required this.startTime,
    required this.duration,
    required this.feedingType,
    this.milkType,
    required this.amountType,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'side': side,
    'startTime': startTime,
    'duration': duration,
    'feedingType': feedingType,
    'milkType': milkType,
    'amountType': amountType,
    'amount': amount,
    'createdAt': createdAt,
  };

  factory NursingModel.fromMap(Map<String, dynamic> map) {
    return NursingModel(
      side: recordString(map['side']),
      startTime: recordString(map['startTime']),
      duration: recordInt(map['duration']),
      feedingType: recordString(map['feedingType']),
      milkType: recordStringOrNull(map['milkType']),
      amountType: recordString(map['amountType']),
      amount: recordNum(map['amount']),
      createdAt: recordString(map['createdAt']),
    );
  }

  bool get isBottle => feedingType.trim().toLowerCase() == 'bottle';

  /// Miktar ml cinsinden (oz → ml dönüşümüyle).
  double get amountMl {
    final v = amount.toDouble();
    return amountType.trim().toLowerCase() == 'oz' ? v * ozToMl : v;
  }

  static const double ozToMl = 29.5735;

  /// Kullanıcının seçtiği saate göre olayın gerçek zamanı; `createdAt`
  /// okunamazsa null.
  DateTime? get eventAt {
    final saved = parseCreatedAt(createdAt);
    return saved == null ? null : resolveEventTime(saved, startTime);
  }
}
