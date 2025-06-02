import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthRepository {
  final PostgreSQLConnection _connection;

  AuthRepository(this._connection);

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<User?> registerUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    bool? isInTherapy,
  }) async {
    try {
      final user = User(
        fullName: fullName,
        email: email,
        phone: phone,
        passwordHash: _hashPassword(password),
        isInTherapy: isInTherapy,
      );

      await _connection.execute(
        '''
        INSERT INTO users (id, full_name, email, phone, password_hash, is_in_therapy)
        VALUES (@id, @fullName, @email, @phone, @passwordHash, @isInTherapy)
        ''',
        substitutionValues: {
          'id': user.id,
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'passwordHash': user.passwordHash,
          'isInTherapy': user.isInTherapy,
        },
      );

      return user;
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL: $e');
      rethrow;
    } catch (e) {
      print('Erro desconhecido: $e');
      rethrow;
    }
  }
}