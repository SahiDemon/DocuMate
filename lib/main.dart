import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:documate/theme/app_theme.dart';
import 'package:documate/screens/welcome_screen.dart';
import 'package:documate/screens/home_screen.dart';
import 'package:documate/screens/new_home_screen.dart';
import 'package:documate/screens/splash_screen.dart';
import 'package:documate/screens/onboarding_screen.dart';
import 'package:documate/models/document_model.dart';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DocumentModelAdapter());

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing camera: $e');
    cameras = [];
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  runApp(MyApp(showWelcome: !hasSeenWelcome));
}

class MyApp extends StatelessWidget {
  final bool showWelcome;

  const MyApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuMate',
      debugShowCheckedModeBanner: false,
      theme: DocuMateTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const NewHomeScreen(),
        '/old-home': (context) => const HomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
