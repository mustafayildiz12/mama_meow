class MeowUserModel {
  MeowUserModel({
    this.userName,
    this.userPassword,
    this.uid,
    this.userEmail,
    this.status,
    this.createDateTimeStamp,
    this.babyName,
    this.ageRange,
  });

  factory MeowUserModel.fromMap(Map<String, dynamic> map) {
    return MeowUserModel(
      userName: map['userName'],
      userPassword: map['userPassword'],
      uid: map['uid'],
      userEmail: map["userEmail"],
      status: map["status"],
      createDateTimeStamp: map["createDateTimeStamp"] ?? 0,

      babyName: map['babyName'],
    );
  }

  final String? userName;
  final String? userPassword;
  final String? uid;
  final String? userEmail;
  final int? status;
  final int? createDateTimeStamp;
  final String? babyName;
  final String? ageRange;

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userPassword': userPassword,
      'uid': uid,
      'userEmail': userEmail,
      'status': status,
      'createDateTimeStamp': createDateTimeStamp,

      'babyName': babyName,
      'ageRange': ageRange,
    };
  }

  /// copyWith metodu
  MeowUserModel copyWith({
    String? userName,
    String? userPassword,
    String? uid,
    String? userEmail,
    int? status,
    int? createDateTimeStamp,

    String? babyName,
    String? ageRange,
  }) {
    return MeowUserModel(
      userName: userName ?? this.userName,
      userPassword: userPassword ?? this.userPassword,
      uid: uid ?? this.uid,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      createDateTimeStamp: createDateTimeStamp ?? this.createDateTimeStamp,
      babyName: babyName ?? this.babyName,
      ageRange: ageRange ?? this.ageRange,
    );
  }
}
