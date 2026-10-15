class MeowUserModel {
  MeowUserModel({
    this.userName,
    this.uid,
    this.userEmail,
    this.status,
    this.createDateTimeStamp,
    this.babyName,
    this.ageRange,
    this.babyPicture,
  });

  factory MeowUserModel.fromMap(Map<String, dynamic> map) {
    return MeowUserModel(
      userName: map['userName']?.toString(),
      uid: map['uid']?.toString(),
      userEmail: map["userEmail"]?.toString(),
      status: (map["status"] as num?)?.toInt(),
      createDateTimeStamp: (map["createDateTimeStamp"] as num?)?.toInt() ?? 0,
      ageRange: map['ageRange']?.toString(),
      babyName: map['babyName']?.toString(),
      babyPicture: map['babyPicture']?.toString(),
    );
  }

  final String? userName;
  final String? uid;
  final String? userEmail;

  /// 1 = hesap kalıcı olarak silinmiş olarak işaretli.
  final int? status;
  final int? createDateTimeStamp;
  final String? babyName;
  final String? ageRange;
  final String? babyPicture;

  // Not: Şifre hiçbir koşulda veritabanına yazılmaz (eskiden `userPassword`
  // düz metin olarak saklanıyordu).
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'uid': uid,
      'userEmail': userEmail,
      'status': status,
      'createDateTimeStamp': createDateTimeStamp,
      'babyName': babyName,
      'ageRange': ageRange,
      'babyPicture': babyPicture,
    };
  }

  MeowUserModel copyWith({
    String? userName,
    String? uid,
    String? userEmail,
    int? status,
    int? createDateTimeStamp,
    String? babyName,
    String? ageRange,
    String? babyPicture,
  }) {
    return MeowUserModel(
      userName: userName ?? this.userName,
      uid: uid ?? this.uid,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      createDateTimeStamp: createDateTimeStamp ?? this.createDateTimeStamp,
      babyName: babyName ?? this.babyName,
      ageRange: ageRange ?? this.ageRange,
      babyPicture: babyPicture ?? this.babyPicture,
    );
  }
}
