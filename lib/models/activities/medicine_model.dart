class MedicineModel {
  final String startTime;
  final String medicineName;
  final String amountType;
  final double amount;
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

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      startTime: map['startTime'] as String,
      medicineName: map['medicineName'] as String,
      createdAt: map['createdAt'] as String,
      amount: map['amount'] as double,
      amountType: map['amountType'] as String,
    );
  }
}
