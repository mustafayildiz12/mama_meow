class DiaperModel {
  final String diaperName;
  final String createdAt; // ISO-8601 (DateTime.now().toIso8601String())
  final String diaperTime;

  DiaperModel({
    required this.diaperName,
    required this.createdAt,
    required this.diaperTime,
  }); // "HH:mm"

  Map<String, dynamic> toMap() => {
    'diaperName': diaperName,
    'createdAt': createdAt,
    'diaperTime': diaperTime,
  };

  factory DiaperModel.fromMap(Map<String, dynamic> map) {
    return DiaperModel(
      diaperName: map['diaperName'] as String,
      createdAt: map['createdAt'] as String,
      diaperTime: map['diaperTime'] as String,
    );
  }
}
