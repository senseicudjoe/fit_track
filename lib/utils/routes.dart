import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/permissions_screen.dart';
import '../screens/main/dashboard_screen.dart';
import '../screens/main/log_workout_screen.dart';
import '../screens/main/goals_screen.dart';
import '../screens/main/progress_screen.dart';
import '../screens/main/insights_screen.dart';
import '../screens/main/settings_screen.dart';
import '../screens/workout/timer_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../widgets/bottom_nav.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: AuthProvider.instance, // Watch for auth changes
    redirect: (context, state) {
      final auth = AuthProvider.instance;
      
      // 0. Wait for initialization to avoid flickering
      if (!auth.isInitialized) {
        return null;
      }

      final isLoggedIn = auth.isLoggedIn;
      final isOnboarded = auth.isOnboarded;
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isAuthRoute = isLoggingIn || isRegistering;

      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPermissions = state.matchedLocation == '/permissions';

      // 1. If not logged in and not on an auth route, go to login
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // 2. If logged in but not onboarded, keep user inside onboarding flow.
      if (isLoggedIn && !isOnboarded) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3. After login, send onboarded users to permissions prompt first.
      if (isLoggedIn && isOnboarded && isAuthRoute) {
        return '/permissions';
      }

      // 4. Onboarded users should never re-enter onboarding.
      if (isLoggedIn && isOnboarded && isOnboarding) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Onboarding routes
      GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/log',       builder: (_, __) => const LogWorkoutScreen()),
          GoRoute(path: '/goals',     builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/progress',  builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/insights',  builder: (_, __) => const InsightsScreen()),
          GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
        ],
      ),

      // Full-screen workout routes (no bottom nav)
      GoRoute(path: '/timer',   builder: (_, __) => const TimerScreen()),
      GoRoute(
        path: '/workout/:id',
        builder: (_, state) => WorkoutDetailScreen(
          workoutId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
