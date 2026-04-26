import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/timer_provider.dart';
import 'services/notification_service.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise local notifications
  await NotificationService.instance.init();
  
  // Initialise router to check permission status
  await AppRouter.init();

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use .value for the AuthProvider singleton
        ChangeNotifierProvider.value(value: AuthProvider.instance),
        
        // Use ProxyProviders to automatically initialize data when the user logs in
        ChangeNotifierProxyProvider<AuthProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider(),
          update: (_, auth, workout) => workout!..update(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (_) => GoalProvider(),
          update: (_, auth, goal) => goal!..update(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, GoalProvider, StatsProvider>(
          create: (_) => StatsProvider(),
          update: (_, auth, goal, stats) => stats!..update(auth.user?.uid, goal),
        ),

        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp.router(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}