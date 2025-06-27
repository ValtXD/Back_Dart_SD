// funfono_backend/lib/repositories/auth_repository.dart

import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
// Certifique-se de que a importação do User model seja do pacote:
import 'package:funfono_backend/models/user.dart'; // <-- Mantenha esta linha

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
      final existingUserByEmail = await findUserByEmail(email);
      if (existingUserByEmail != null) {
        return null;
      }
      final existingUserByFullName = await findUserByFullName(fullName);
      if (existingUserByFullName != null) {
        return null;
      }

      final user = User(
        id: const Uuid().v4(),
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
      print('Erro no PostgreSQL ao registrar: $e');
      rethrow;
    } catch (e) {
      print('Erro desconhecido ao registrar: $e');
      rethrow;
    }
  }

  Future<User?> findUserByEmail(String email) async {
    try {
      final results = await _connection.query(
        'SELECT id, full_name, email, phone, password_hash, is_in_therapy FROM users WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (results.isNotEmpty) {
        final row = results.first.toColumnMap();
        return User(
          id: row['id'] as String,
          fullName: row['full_name'] as String,
          email: row['email'] as String,
          phone: row['phone'] as String?,
          passwordHash: row['password_hash'] as String,
          isInTherapy: row['is_in_therapy'] as bool?,
        );
      }
      return null;
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao buscar usuário por email: $e');
      rethrow;
    } catch (e) {
      print('Erro desconhecido ao buscar usuário por email: $e');
      rethrow;
    }
  }

  Future<User?> findUserByFullName(String fullName) async {
    try {
      final results = await _connection.query(
        'SELECT id, full_name, email, phone, password_hash, is_in_therapy FROM users WHERE full_name = @fullName',
        substitutionValues: {'fullName': fullName},
      );

      if (results.isNotEmpty) {
        final row = results.first.toColumnMap();
        return User(
          id: row['id'] as String,
          fullName: row['full_name'] as String,
          email: row['email'] as String,
          phone: row['phone'] as String?,
          passwordHash: row['password_hash'] as String,
          isInTherapy: row['is_in_therapy'] as bool?,
        );
      }
      return null;
    } on PostgreSQLException catch (e) {
      print('Erro no PostgreSQL ao buscar usuário por nome completo: $e');
      rethrow;
    } catch (e) {
      print('Erro desconhecido ao buscar usuário por nome completo: $e');
      rethrow;
    }
  }
}