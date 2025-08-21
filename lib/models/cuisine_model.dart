import 'package:equatable/equatable.dart';

class Cuisine extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  const Cuisine({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, imageUrl];
}

