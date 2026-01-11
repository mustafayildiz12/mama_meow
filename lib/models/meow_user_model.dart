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
    this.babyPicture,
  });

  factory MeowUserModel.fromMap(Map<String, dynamic> map) {
    return MeowUserModel(
      userName: map['userName'],
      userPassword: map['userPassword'],
      uid: map['uid'],
      userEmail: map["userEmail"],
      status: map["status"],
      createDateTimeStamp: map["createDateTimeStamp"] ?? 0,
      ageRange: map['ageRange'],
      babyName: map['babyName'],
      babyPicture: map['babyPicture'],
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
  final String? babyPicture;

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
      'babyPicture': babyPicture,
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
    String? babyPicture,
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
      babyPicture: babyPicture ?? this.babyPicture,
    );
  }
}
