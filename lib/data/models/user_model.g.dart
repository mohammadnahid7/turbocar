// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  name: json['full_name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  dateOfBirth: json['dob'] == null
      ? null
      : DateTime.parse(json['dob'] as String),
  gender: json['gender'] as String?,
  profilePicture: json['profile_photo_url'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  isVerified: json['is_verified'] as bool?,
  isDealer: json['is_dealer'] as bool?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'dob': instance.dateOfBirth?.toIso8601String(),
  'gender': instance.gender,
  'profile_photo_url': instance.profilePicture,
  'created_at': instance.createdAt?.toIso8601String(),
  'is_verified': instance.isVerified,
  'is_dealer': instance.isDealer,
};
