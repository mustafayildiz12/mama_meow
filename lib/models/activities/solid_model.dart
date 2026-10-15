import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

enum Reaction {
  loveIt, // "love it"
  meh, // "meh"
  hatedIt, // "hated it"
  allergicOrSensitivity, // "allergic or sensitivity"
}

String reactionToText(Reaction r) {
  switch (r) {
    case Reaction.loveIt:
      return "love it";
    case Reaction.meh:
      return "meh";
    case Reaction.hatedIt:
      return "hated it";
    case Reaction.allergicOrSensitivity:
      return "allergic or sensitivity";
  }
}

Reaction? reactionFromText(String? s) {
  switch (s) {
    case "love it":
      return Reaction.loveIt;
    case "meh":
      return Reaction.meh;
    case "hated it":
      return Reaction.hatedIt;
    case "allergic or sensitivity":
      return Reaction.allergicOrSensitivity;
    default:
      return null;
  }
}

class SolidModel {
  final String solidName;
  final String solidAmount; // adet/porisyon metni (ör: "2")
  final String createdAt; // ISO-8601 (DateTime.now().toIso8601String())
  final String eatTime; // "HH:mm"
  final Reaction? reactions;

  const SolidModel({
    required this.solidName,
    required this.solidAmount,
    required this.createdAt,
    required this.eatTime,
    this.reactions,
  });

  Map<String, dynamic> toMap() => {
    'solidName': solidName,
    'solidAmount': solidAmount,
    'createdAt': createdAt,
    'eatTime': eatTime,
    'reactions': reactions == null ? null : reactionToText(reactions!),
  };

  factory SolidModel.fromMap(Map<String, dynamic> map) {
    return SolidModel(
      solidName: map['solidName']?.toString() ?? "",
      solidAmount: map['solidAmount']?.toString() ?? "0",
      createdAt: map['createdAt']?.toString() ?? "",
      eatTime: map['eatTime']?.toString() ?? "",
      reactions: reactionFromText(map['reactions']?.toString()),
    );
  }

  /// [solidAmount] sayısal değeri ("1.5" ve "1,5" dahil); okunamazsa null.
  /// `int.tryParse(solidAmount)` yerine bunu kullanın ("1.5" → 0 olmasın).
  num? get amountValue => parseLooseNum(solidAmount);

  /// Kullanıcının seçtiği yeme saatine göre olayın gerçek zamanı; `createdAt`
  /// okunamazsa null.
  DateTime? get eventAt {
    final saved = parseCreatedAt(createdAt);
    return saved == null ? null : resolveEventTime(saved, eatTime);
  }
}
