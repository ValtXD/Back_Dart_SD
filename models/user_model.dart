class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String passwordHash;
  final bool isInTherapy;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.isInTherapy,
    required this.createdAt,
  });

  /// Método público para hash de senha
  static String hashPassword(String password) {
    // Em produção, substitua por:
    // import 'package:crypto/crypto.dart';
    // return sha256.convert(utf8.encode(password)).toString();
    return 'hashed_${password.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      passwordHash: hashPassword(json['password']?.toString() ?? ''),
      isInTherapy: json['isInTherapy']?.toString().toLowerCase() == 'true',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'isInTherapy': isInTherapy,
    'createdAt': createdAt.toIso8601String(),
  };
}