import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

class MedicineModel {
  final String startTime; // "HH:mm"
  final String medicineName;
  final String amountType;

  /// Doz miktarı. Eski kayıtlar int, yenileri ondalıklı olabilir.
  final num amount;
  final String createdAt;

  MedicineModel({
    required this.startTime,
    required this.medicineName,
    required this.amountType,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'startTime': startTime,
    'medicineName': medicineName,
    'amountType': amountType,
    'amount': amount,
    'createdAt': createdAt,
  };

  /// `amount` int, double veya sayısal metin ("2,5") olabilir.
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      startTime: recordString(map['startTime']),
      medicineName: recordString(map['medicineName']),
      createdAt: recordString(map['createdAt']),
      amount: recordNum(map['amount']),
      amountType: recordString(map['amountType']),
    );
  }

  /// Kullanıcının seçtiği saate göre olayın gerçek zamanı; `createdAt`
  /// okunamazsa null.
  DateTime? get eventAt {
    final saved = parseCreatedAt(createdAt);
    return saved == null ? null : resolveEventTime(saved, startTime);
  }
}
