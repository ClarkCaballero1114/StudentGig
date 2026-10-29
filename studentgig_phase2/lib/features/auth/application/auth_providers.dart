import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentgig/data/repositories/json_auth_repository.dart';
import 'package:studentgig/domain/entities/app_user.dart';
import 'package:studentgig/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => JsonAuthRepository(),
);

/// The locally persisted StudentGig profile for the current session.
final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchCurrentUser(),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// Runs auth actions and exposes loading and error state to the UI.
/// Each method returns true on success. Navigation is handled by the router.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn({required String email, required String password}) =>
      _run(() async {
        await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
      });

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) =>
      _run(() async {
        await ref.read(authRepositoryProvider).register(
              email: email,
              password: password,
              displayName: displayName,
              role: role,
            );
      });

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) =>
      _run(() async {
        await ref.read(authRepositoryProvider).resetPassword(
              email: email,
              newPassword: newPassword,
            );
      });

  Future<bool> signOut() => _run(() async {
        await ref.read(authRepositoryProvider).signOut();
      });

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
