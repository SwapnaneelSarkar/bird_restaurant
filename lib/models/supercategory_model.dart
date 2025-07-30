class SupercategoryModel {
  final String id;
  final String name;
  final String image;

  SupercategoryModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory SupercategoryModel.fromJson(Map<String, dynamic> json) {
    return SupercategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
} 