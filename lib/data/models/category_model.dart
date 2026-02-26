class CategoryModel {
  final int? id;
  final String name;

  const CategoryModel({this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as int?,
        name: map['name'] as String,
      );

  CategoryModel copyWith({int? id, String? name}) =>
      CategoryModel(id: id ?? this.id, name: name ?? this.name);
}
