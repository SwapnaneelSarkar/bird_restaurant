class CategoryModel {
  final int id;
  final String name;
  final int displayOrder;
  final bool active;

  CategoryModel({
    required this.id,
    required this.name,
    this.displayOrder = 0,
    this.active = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      displayOrder: json['display_order'],
      active: json['active'] == 1,
    );
  }
}
