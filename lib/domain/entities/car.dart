/// Car Entity
/// Domain entity representing a car listing
library;

class Car {
  final String id;
  final String title;
  final String description;
  final int price;
  final int year;
  final int mileage;
  final String company;
  final String category;
  final String city;
  final List<String> images;
  final String userId;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.year,
    required this.mileage,
    required this.company,
    required this.category,
    required this.city,
    required this.images,
    required this.userId,
    this.isSaved = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
