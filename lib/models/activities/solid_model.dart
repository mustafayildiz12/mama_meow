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

  SolidModel copyWith({
    String? solidName,
    String? solidAmount,
    String? createdAt,
    String? eatTime,
    Reaction? reactions, // null geçmek için explicitlyPassNull kullan
    bool explicitlyNullReaction = false,
  }) {
    return SolidModel(
      solidName: solidName ?? this.solidName,
      solidAmount: solidAmount ?? this.solidAmount,
      createdAt: createdAt ?? this.createdAt,
      eatTime: eatTime ?? this.eatTime,
      reactions: explicitlyNullReaction ? null : (reactions ?? this.reactions),
    );
  }

  Map<String, dynamic> toMap() => {
    'solidName': solidName,
    'solidAmount': solidAmount,
    'createdAt': createdAt,
    'eatTime': eatTime,
    'reactions': reactions == null ? null : reactionToText(reactions!),
  };

  factory SolidModel.fromMap(Map<String, dynamic> map) {
    return SolidModel(
      solidName: map['solidName'] as String,
      solidAmount: map['solidAmount'] as String,
      createdAt: map['createdAt'] as String,
      eatTime: map['eatTime'] as String,
      reactions: reactionFromText(map['reactions'] as String?),
    );
  }
}
