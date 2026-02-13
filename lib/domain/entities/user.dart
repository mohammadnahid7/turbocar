/// User Entity
/// Domain entity representing a user
library;

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profilePicture;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profilePicture,
    required this.createdAt,
  });
}
