class CustomSolidModel {
  final String name;
  final String solidLink;

  CustomSolidModel({required this.name, required this.solidLink});

  Map<String, dynamic> toMap() => {'name': name, 'solidLink': solidLink};

  factory CustomSolidModel.fromMap(Map<String, dynamic> map) {
    return CustomSolidModel(
      name: map['name'] as String,
      solidLink: map['solidLink'] as String,
    );
  }
}
