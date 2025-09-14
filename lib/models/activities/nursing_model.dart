class NursingModel {
  final String side; // "left", "right"
  final String startTime; // "HH:mm"
  final int duration; // minutes
  final String feedingType; // "nursing" or "bottle"
  final String? milkType; // only if feedingType is "bottle"
  final String amountType; // "oz" or "ml"
  final double amount; // amount value
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
      side: map['side'] as String,
      startTime: map['startTime'] as String,
      duration: map['duration'] as int,
      feedingType: map['feedingType'] as String,
      milkType: map['milkType'] as String?,
      amountType: map['amountType'] as String,
      amount: map['amount'] as double,
      createdAt: map['createdAt'] as String,
    );
  }
}