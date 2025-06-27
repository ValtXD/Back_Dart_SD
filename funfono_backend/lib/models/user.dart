// funfono_backend/lib/models/user.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  @JsonKey(name: 'full_name')
  final String fullName; // Tornar não nulo, pois será usado para login
  final String email;
  final String? phone;
  @JsonKey(name: 'password_hash')
  final String passwordHash;
  @JsonKey(name: 'is_in_therapy')
  final bool? isInTherapy;

  User({
    String? id,
    required this.fullName, // Marcado como required
    required this.email,
    this.phone,
    required this.passwordHash,
    this.isInTherapy,
  }) : id = id ?? const Uuid().v4();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}