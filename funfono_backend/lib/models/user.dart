import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  
  @JsonKey(name: 'password_hash')
  final String passwordHash;
  
  @JsonKey(name: 'is_in_therapy')
  final bool? isInTherapy;

  User({
    String? id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.passwordHash,
    this.isInTherapy,
  }) : id = id ?? const Uuid().v4();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}