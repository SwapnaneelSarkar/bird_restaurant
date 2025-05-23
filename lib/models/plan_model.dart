// lib/models/plan_model.dart
class PlanModel {
  final String id;
  final String title;
  final String description;
  final List<String> features;
  final double price;
  final bool isPopular;
  final String buttonText;

  const PlanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.features,
    required this.price,
    this.isPopular = false,
    required this.buttonText,
  });
}

