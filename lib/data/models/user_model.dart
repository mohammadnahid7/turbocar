/// User Model
/// Represents user data from the API
library;

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  @JsonKey(name: 'full_name')
  final String name;
  final String email;
  final String? phone;
  @JsonKey(name: 'dob')
  final DateTime? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePicture;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'is_verified')
  final bool? isVerified;
  @JsonKey(name: 'is_dealer')
  final bool? isDealer;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profilePicture,
    this.createdAt,
    this.isVerified,
    this.isDealer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? profilePicture,
    DateTime? createdAt,
    bool? isVerified,
    bool? isDealer,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isDealer: isDealer ?? this.isDealer,
    );
  }
}
