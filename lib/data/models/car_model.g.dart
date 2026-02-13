// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModel _$CarModelFromJson(Map<String, dynamic> json) => CarModel(
  id: json['id'] as String,
  sellerId: json['seller_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  make: json['make'] as String,
  model: json['model'] as String,
  year: (json['year'] as num).toInt(),
  mileage: (json['mileage'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  condition: json['condition'] as String,
  transmission: json['transmission'] as String,
  fuelType: json['fuel_type'] as String,
  color: json['color'] as String,
  vin: json['vin'] as String,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  city: json['city'] as String,
  state: json['state'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  status: json['status'] as String,
  isFeatured: json['is_featured'] as bool,
  viewsCount: (json['views_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  isFavorited: json['is_favorited'] as bool? ?? false,
  isOwner: json['is_owner'] as bool? ?? false,
  seller: json['seller'] == null
      ? null
      : SellerModel.fromJson(json['seller'] as Map<String, dynamic>),
  chatOnly: json['chat_only'] as bool? ?? false,
);

Map<String, dynamic> _$CarModelToJson(CarModel instance) => <String, dynamic>{
  'id': instance.id,
  'seller_id': instance.sellerId,
  'title': instance.title,
  'description': instance.description,
  'make': instance.make,
  'model': instance.model,
  'year': instance.year,
  'mileage': instance.mileage,
  'price': instance.price,
  'condition': instance.condition,
  'transmission': instance.transmission,
  'fuel_type': instance.fuelType,
  'color': instance.color,
  'vin': instance.vin,
  'images': instance.images,
  'city': instance.city,
  'state': instance.state,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'status': instance.status,
  'is_featured': instance.isFeatured,
  'views_count': instance.viewsCount,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'chat_only': instance.chatOnly,
  'is_favorited': instance.isFavorited,
  'is_owner': instance.isOwner,
  'seller': instance.seller,
};

SellerModel _$SellerModelFromJson(Map<String, dynamic> json) => SellerModel(
  id: json['id'] as String,
  name: json['name'] as String?,
  profilePhoto: json['profile_photo'] as String?,
  phone: json['phone'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SellerModelToJson(SellerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profile_photo': instance.profilePhoto,
      'phone': instance.phone,
      'rating': instance.rating,
    };
