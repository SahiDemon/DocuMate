import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:documate/theme/app_theme.dart';
import 'package:documate/screens/welcome_screen.dart';
import 'package:documate/screens/home_screen.dart';
import 'package:documate/screens/new_home_screen.dart';
import 'package:documate/screens/splash_screen.dart';
import 'package:documate/screens/onboarding_screen.dart';
import 'package:documate/screens/auth/login_screen.dart';
import 'package:documate/screens/auth/register_screen.dart';
import 'package:documate/screens/auth/forgot_password_screen.dart';
import 'package:documate/screens/storage_onboarding_screen.dart';
import 'package:documate/screens/storage_privacy_screen.dart';
import 'package:documate/screens/storage_settings_screen.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:documate/services/firebase_auth_service.dart';

List<CameraDescription>? cameras;

// Global storage services - initialized once at app startup
late StorageService storageService;
late CloudSyncService cloudSyncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('✓ Firebase initialized');
  
  // Disable Firebase App Check for development (speeds up auth)
  // WARNING: Re-enable for production!
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  print('⚠️ Firebase reCAPTCHA disabled for testing');

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DocumentModelAdapter());

  // ==================== STORAGE INITIALIZATION ====================
  // Initialize encrypted local storage with AES-256
  storageService = StorageService();
  await storageService.initialize();
  print('✓ StorageService initialized');

  // Initialize cloud sync service
  cloudSyncService = CloudSyncService(storageService);
  print('✓ CloudSyncService initialized');

  // ==================== AUTO-SYNC ON STARTUP ====================
  // If backup is enabled, automatically download and merge from Google Drive
  // This runs in background and does not block app startup
  final backupEnabled = await cloudSyncService.isBackupEnabled();
  if (backupEnabled) {
    final signedIn = await cloudSyncService.isSignedIn();
    if (signedIn) {
      print('🔄 Running auto-sync on startup...');
      // Run sync in background (fire and forget)
      cloudSyncService.autoSyncOnStartup().catchError((e) {
        print('⚠ Auto-sync error (non-blocking): $e');
      });
    }
  }
  // ================================================================

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing camera: $e');
    cameras = [];
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  // Check if user has completed storage onboarding
  final storageOnboardingComplete = await storageService.getSetting(
    'storage_onboarding_complete',
    defaultValue: false,
  ) as bool;

  runApp(MyApp(
    showWelcome: !hasSeenWelcome,
    storageOnboardingComplete: storageOnboardingComplete,
  ));
}

class MyApp extends StatelessWidget {
  final bool showWelcome;
  final bool storageOnboardingComplete;

  const MyApp({
    super.key,
    required this.showWelcome,
    required this.storageOnboardingComplete,
  });

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
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/storage-onboarding': (context) => StorageOnboardingScreen(
              storageService: storageService,
              cloudSyncService: cloudSyncService,
            ),
        '/storage-privacy': (context) => const StoragePrivacyScreen(),
        '/storage-settings': (context) => StorageSettingsScreen(
              storageService: storageService,
              cloudSyncService: cloudSyncService,
            ),
      },
    );
  }
}
