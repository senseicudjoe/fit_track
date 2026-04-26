import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../screens/additions/splash_screen.dart';
import '../screens/additions/intro_screen.dart';
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
import '../screens/main/edit_profile_screen.dart';
import '../screens/workout/timer_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../widgets/bottom_nav.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Cache for permissions status to use in the synchronous redirect
  static bool _permissionsHandled = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _permissionsHandled = prefs.getBool('permissions_handled') ?? false;
  }

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AuthProvider.instance,
    redirect: (context, state) {
      final auth = AuthProvider.instance;
      
      if (!auth.isInitialized) {
        return null;
      }

      final isLoggedIn = auth.isLoggedIn;
      final isOnboarded = auth.isOnboarded;
      
      final isSplash = state.matchedLocation == '/';
      final isIntro = state.matchedLocation == '/intro';
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isAuthRoute = isLoggingIn || isRegistering || isSplash || isIntro;

      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPermissions = state.matchedLocation == '/permissions';

      // 1. If not logged in and not on an auth route, go to splash
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/';
      }

      // 2. If logged in but not onboarded, keep user inside onboarding flow.
      if (isLoggedIn && !isOnboarded) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3. Only show permissions if not yet handled
      if (isLoggedIn && isOnboarded && !_permissionsHandled && !isPermissions) {
         // Check again to see if it was just handled in this session
         _checkPermissionsStatus();
         if (!_permissionsHandled) return '/permissions';
      }

      // 4. If logged in, onboarded, and permissions handled, avoid auth/onboarding screens
      if (isLoggedIn && isOnboarded && (isAuthRoute || isOnboarding || (isPermissions && _permissionsHandled))) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/',      builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/intro',  builder: (_, __) => const IntroScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),

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

      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),

      GoRoute(path: '/timer',   builder: (_, __) => const TimerScreen()),
      GoRoute(
        path: '/workout/:id',
        builder: (_, state) => WorkoutDetailScreen(
          workoutId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  static void _checkPermissionsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _permissionsHandled = prefs.getBool('permissions_handled') ?? false;
  }
}
