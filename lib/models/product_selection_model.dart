class ProductSelectionModel {
  final String productId;
  final String name;
  final String? description;
  final String brand;
  final String weight;
  final String unit;
  final String? imageUrl;
  final bool active;
  final String? createdAt;
  final String? updatedAt;
  final SubcategoryInfo subcategory;
  final CategoryInfo category;
  final SupercategoryInfo supercategory;

  ProductSelectionModel({
    required this.productId,
    required this.name,
    this.description,
    required this.brand,
    required this.weight,
    required this.unit,
    this.imageUrl,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    required this.subcategory,
    required this.category,
    required this.supercategory,
  });

  factory ProductSelectionModel.fromJson(Map<String, dynamic> json) {
    return ProductSelectionModel(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      brand: json['brand'] ?? '',
      weight: json['weight'] ?? '',
      unit: json['unit'] ?? '',
      imageUrl: json['image_url'],
      active: json['active'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      subcategory: SubcategoryInfo.fromJson(json['subcategory'] ?? {}),
      category: CategoryInfo.fromJson(json['category'] ?? {}),
      supercategory: SupercategoryInfo.fromJson(json['supercategory'] ?? {}),
    );
  }
}

class SubcategoryInfo {
  final String id;
  final String name;

  SubcategoryInfo({
    required this.id,
    required this.name,
  });

  factory SubcategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubcategoryInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class CategoryInfo {
  final String id;
  final String name;

  CategoryInfo({
    required this.id,
    required this.name,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class SupercategoryInfo {
  final String id;
  final String name;

  SupercategoryInfo({
    required this.id,
    required this.name,
  });

  factory SupercategoryInfo.fromJson(Map<String, dynamic> json) {
    return SupercategoryInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
} 