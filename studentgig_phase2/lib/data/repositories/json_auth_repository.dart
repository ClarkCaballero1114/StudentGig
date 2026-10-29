import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studentgig/core/error/auth_failure.dart';
import 'package:studentgig/domain/entities/app_user.dart';
import 'package:studentgig/domain/repositories/auth_repository.dart';

class JsonAuthRepository implements AuthRepository {
  JsonAuthRepository({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _databaseKey = 'studentgig_json_database';
  final Future<SharedPreferences> Function() _preferencesLoader;
  final _sessionChanges = StreamController<AppUser?>.broadcast();
  final _random = Random.secure();

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield await _readCurrentUser();
    yield* _sessionChanges.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final database = await _readDatabase();
    final normalizedEmail = _normalizeEmail(email);
    final userData = _users(database).cast<Map<String, dynamic>?>().firstWhere(
          (user) => user?['email'] == normalizedEmail,
          orElse: () => null,
        );

    if (userData == null ||
        _passwordHash(userData['passwordSalt'] as String, password) !=
            userData['passwordHash']) {
      throw const AuthFailure(AuthFailureCode.wrongCredentials);
    }

    database['currentUserId'] = userData['id'];
    await _writeDatabase(database);
    final user = _toAppUser(userData);
    _sessionChanges.add(user);
    return user;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    if (password.length < 8) {
      throw const AuthFailure(AuthFailureCode.weakPassword);
    }
    final database = await _readDatabase();
    final normalizedEmail = _normalizeEmail(email);
    if (_users(database).any((user) => user['email'] == normalizedEmail)) {
      throw const AuthFailure(AuthFailureCode.emailAlreadyInUse);
    }

    final salt = _randomHex(16);
    final id = _randomHex(16);
    final userData = <String, dynamic>{
      'id': id,
      'email': normalizedEmail,
      'displayName': displayName.trim(),
      'role': role.name,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'passwordSalt': salt,
      'passwordHash': _passwordHash(salt, password),
    };

    _users(database).add(userData);
    database['currentUserId'] = id;
    await _writeDatabase(database);

    final user = _toAppUser(userData);
    _sessionChanges.add(user);
    return user;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw const AuthFailure(AuthFailureCode.weakPassword);
    }
    final database = await _readDatabase();
    final normalizedEmail = _normalizeEmail(email);
    final userData = _users(database).cast<Map<String, dynamic>?>().firstWhere(
          (user) => user?['email'] == normalizedEmail,
          orElse: () => null,
        );
    if (userData == null) {
      throw const AuthFailure(AuthFailureCode.emailNotFound);
    }

    final salt = _randomHex(16);
    userData['passwordSalt'] = salt;
    userData['passwordHash'] = _passwordHash(salt, newPassword);
    await _writeDatabase(database);

    if (database['currentUserId'] == userData['id']) {
      _sessionChanges.add(_toAppUser(userData));
    }
  }

  @override
  Future<void> signOut() async {
    final database = await _readDatabase();
    database['currentUserId'] = null;
    await _writeDatabase(database);
    _sessionChanges.add(null);
  }

  Future<AppUser?> _readCurrentUser() async {
    final database = await _readDatabase();
    final currentUserId = database['currentUserId'];
    if (currentUserId is! String) return null;

    for (final user in _users(database)) {
      if (user['id'] == currentUserId) return _toAppUser(user);
    }
    return null;
  }

  Future<Map<String, dynamic>> _readDatabase() async {
    final preferences = await _preferencesLoader();
    final serialized = preferences.getString(_databaseKey);
    if (serialized == null) {
      return <String, dynamic>{
        'version': 1,
        'users': <Map<String, dynamic>>[],
        'currentUserId': null,
      };
    }

    final decoded = jsonDecode(serialized);
    if (decoded is! Map<String, dynamic> || decoded['users'] is! List) {
      throw const FormatException(
          'The local StudentGig JSON database is invalid.');
    }
    return decoded;
  }

  Future<void> _writeDatabase(Map<String, dynamic> database) async {
    final preferences = await _preferencesLoader();
    final saved =
        await preferences.setString(_databaseKey, jsonEncode(database));
    if (!saved) {
      throw StateError('Could not save the local StudentGig JSON database.');
    }
  }

  List<Map<String, dynamic>> _users(Map<String, dynamic> database) {
    final users = database['users'] as List;
    if (users.any((user) => user is! Map<String, dynamic>)) {
      throw const FormatException(
        'A user record in the local StudentGig JSON database is invalid.',
      );
    }
    return users.cast<Map<String, dynamic>>();
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _passwordHash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _randomHex(int bytes) {
    return List<int>.generate(bytes, (_) => _random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  AppUser _toAppUser(Map<String, dynamic> data) => AppUser(
        id: data['id'] as String,
        email: data['email'] as String,
        displayName: data['displayName'] as String,
        role: UserRole.values.byName(data['role'] as String),
        createdAt: DateTime.parse(data['createdAt'] as String).toLocal(),
      );
}
