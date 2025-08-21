class SubcategoryModel {
  final String id;
  final String name;
  final String categoryId;
  final int displayOrder;
  final String? description;
  final String? image;
  final bool active;
  final String? createdAt;
  final String? updatedAt;
  final String categoryName;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.displayOrder = 0,
    this.description,
    this.image,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    required this.categoryName,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      description: json['description'],
      image: json['image'],
      active: json['active'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      categoryName: json['category_name'] ?? '',
    );
  }
} 