/// Car Model
/// Represents car listing data from the API
library;

import 'package:json_annotation/json_annotation.dart';

part 'car_model.g.dart';

@JsonSerializable()
class CarModel {
  final String id;
  @JsonKey(name: 'seller_id')
  final String sellerId;
  final String title;
  final String description;
  final String make;
  final String model;
  final int year;
  final int mileage;
  final double price;
  final String condition;
  final String transmission;
  @JsonKey(name: 'fuel_type')
  final String fuelType;
  final String color;
  final String vin;
  @JsonKey(defaultValue: [])
  final List<String> images;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String status;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'views_count')
  final int viewsCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'chat_only', defaultValue: false)
  final bool chatOnly;

  // Joins/Extras
  @JsonKey(name: 'is_favorited')
  final bool isFavorited;
  @JsonKey(name: 'is_owner')
  final bool isOwner;
  @JsonKey(name: 'seller_name')
  final String? sellerName;
  @JsonKey(name: 'seller_photo')
  final String? sellerPhoto;
  @JsonKey(name: 'seller_rating')
  final double? sellerRating;
  @JsonKey(name: 'seller_phone')
  final String? sellerPhone;

  CarModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    required this.price,
    required this.condition,
    required this.transmission,
    required this.fuelType,
    required this.color,
    required this.vin,
    required this.images,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isFeatured,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.isFavorited = false,
    this.isOwner = false,
    this.sellerName,
    this.sellerPhoto,
    this.sellerRating,
    this.sellerPhone,
    this.chatOnly = false,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelToJson(this);

  CarModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    String? make,
    String? model,
    int? year,
    int? mileage,
    double? price,
    String? condition,
    String? transmission,
    String? fuelType,
    String? color,
    String? vin,
    List<String>? images,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    String? status,
    bool? isFeatured,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isFavorited,
    bool? isOwner,
    String? sellerName,
    String? sellerPhoto,
    double? sellerRating,
    String? sellerPhone,
    bool? chatOnly,
  }) {
    return CarModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      vin: vin ?? this.vin,
      images: images ?? this.images,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isFavorited: isFavorited ?? this.isFavorited,
      isOwner: isOwner ?? this.isOwner,
      sellerName: sellerName ?? this.sellerName,
      sellerPhoto: sellerPhoto ?? this.sellerPhoto,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      chatOnly: chatOnly ?? this.chatOnly,
    );
  }
}
