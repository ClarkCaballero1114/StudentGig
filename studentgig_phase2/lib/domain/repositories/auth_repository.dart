import 'package:studentgig/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the locally signed-in profile and subsequent session changes.
  Stream<AppUser?> watchCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  });

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  });

  Future<void> signOut();
}
