import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studentgig/core/error/auth_failure.dart';
import 'package:studentgig/data/repositories/json_auth_repository.dart';
import 'package:studentgig/domain/entities/app_user.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registers a user and restores the session from JSON storage', () async {
    final repository = JsonAuthRepository();
    final user = await repository.register(
      email: '  student@example.com ',
      password: 'secure-pass-1',
      displayName: 'Student One',
      role: UserRole.student,
    );

    expect(user.email, 'student@example.com');
    expect(user.displayName, 'Student One');
    expect(user.isStudent, isTrue);

    final restoredUser = await JsonAuthRepository()
        .watchCurrentUser()
        .first
        .timeout(const Duration(seconds: 1));
    expect(restoredUser?.id, user.id);

    final preferences = await SharedPreferences.getInstance();
    final storedJson = preferences.getString('studentgig_json_database')!;
    final database = jsonDecode(storedJson) as Map<String, dynamic>;
    final storedUser = (database['users'] as List).single as Map;
    expect(storedUser['passwordHash'], isNot('secure-pass-1'));
    expect(storedUser['passwordSalt'], isNotEmpty);
    expect(storedUser.containsKey('password'), isFalse);
  });

  test('rejects duplicate email and invalid credentials', () async {
    final repository = JsonAuthRepository();
    await repository.register(
      email: 'student@example.com',
      password: 'secure-pass-1',
      displayName: 'Student One',
      role: UserRole.student,
    );

    await expectLater(
      repository.register(
        email: 'STUDENT@example.com',
        password: 'secure-pass-2',
        displayName: 'Student Two',
        role: UserRole.employer,
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.code,
          'code',
          AuthFailureCode.emailAlreadyInUse,
        ),
      ),
    );

    await expectLater(
      repository.signIn(
        email: 'student@example.com',
        password: 'wrong-password',
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.code,
          'code',
          AuthFailureCode.wrongCredentials,
        ),
      ),
    );
  });

  test('resets password and signs out the persisted session', () async {
    final repository = JsonAuthRepository();
    await repository.register(
      email: 'employer@example.com',
      password: 'old-password',
      displayName: 'Employer',
      role: UserRole.employer,
    );

    await repository.resetPassword(
      email: 'employer@example.com',
      newPassword: 'new-password',
    );
    await repository.signOut();
    expect(await repository.watchCurrentUser().first, isNull);

    final user = await repository.signIn(
      email: 'employer@example.com',
      password: 'new-password',
    );
    expect(user.isStudent, isFalse);
  });
}
