import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentgig/domain/entities/app_user.dart';
import 'package:studentgig/features/auth/application/auth_providers.dart';
import 'package:studentgig/features/auth/presentation/forgot_password_screen.dart';
import 'package:studentgig/features/auth/presentation/login_screen.dart';
import 'package:studentgig/features/auth/presentation/register_screen.dart';
import 'package:studentgig/features/dashboard/presentation/dashboard_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const studentHome = '/student';
  static const employerHome = '/employer';

  static const authRoutes = {login, register, forgotPassword};
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final currentUser = ref.read(currentUserProvider);
      final profile = currentUser.valueOrNull;
      final location = state.matchedLocation;
      final onAuthRoute = AppRoutes.authRoutes.contains(location);

      if (currentUser.isLoading) return null;

      if (profile == null) {
        return onAuthRoute ? null : AppRoutes.login;
      }

      if (location == AppRoutes.studentHome && !profile.isStudent) {
        return AppRoutes.employerHome;
      }
      if (location == AppRoutes.employerHome && profile.isStudent) {
        return AppRoutes.studentHome;
      }

      if (onAuthRoute) {
        return profile.isStudent
            ? AppRoutes.studentHome
            : AppRoutes.employerHome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (_, __) => const DashboardScreen(role: UserRole.student),
      ),
      GoRoute(
        path: AppRoutes.employerHome,
        builder: (_, __) => const DashboardScreen(role: UserRole.employer),
      ),
    ],
  );
});
