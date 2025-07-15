class CategoryModel {
  final String id;
  final String name;
  final int displayOrder;
  final bool active;
  final String? createdAt;
  final String? updatedAt;
  final String? image;

  CategoryModel({
    required this.id,
    required this.name,
    this.displayOrder = 0,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      active: json['active'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      image: json['image'],
    );
  }
}
