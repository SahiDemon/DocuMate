import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documate/screens/onboarding_screen.dart';
import 'package:documate/screens/new_home_screen.dart';
import 'package:documate/main.dart' show storageService, notificationService;
import 'package:documate/services/firebase_auth_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _zoomAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Pre-warm GoogleSignIn silently to speed up cold-start login.
    _prewarmAuth();

    _navigateToNext();
  }

  void _prewarmAuth() {
    // Fire-and-forget: do not block splash navigation
    Future(() async {
      try {
        final start = DateTime.now().millisecondsSinceEpoch;
        // Lightweight instance without Drive scopes (Drive handled elsewhere)
        final googleSignIn = GoogleSignIn();
        await googleSignIn
            .signInSilently()
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
        final elapsed = DateTime.now().millisecondsSinceEpoch - start;
        // Helpful for measuring cold-start improvements
        // ignore: avoid_print
        print('⚡ Prewarmed GoogleSignIn in ${elapsed}ms');
      } catch (e) {
        // ignore: avoid_print
        print('⚠ Prewarm GoogleSignIn failed: $e');
      }
    });
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_welcome') ?? false;

    // Check if storage onboarding is complete
    final storageOnboardingComplete = await storageService.getSetting(
      'storage_onboarding_complete',
      defaultValue: false,
    ) as bool;

    // Request notification permission on first launch (after onboarding)
    if (hasSeenOnboarding && storageOnboardingComplete) {
      final permissionRequested = await storageService.getSetting(
        'notification_permission_requested',
        defaultValue: false,
      ) as bool;

      if (!permissionRequested) {
        final granted = await notificationService.requestPermission();
        await storageService.saveSetting(
            'notification_permission_requested', true);
        print(granted
            ? '✓ Notification permission granted'
            : '⚠️ Notification permission denied');
      }
    }

    // Check if user is already authenticated (returning user)
    final firebaseAuth = FirebaseAuthService();
    final isLoggedIn = await firebaseAuth.isLoggedIn();
    final currentUser = firebaseAuth.getCurrentUser();

    if (mounted) {
      Widget nextScreen;

      if (!hasSeenOnboarding) {
        // First time user - show app onboarding
        nextScreen = const OnboardingScreen();
      } else if (!storageOnboardingComplete) {
        // Has seen app onboarding but not storage onboarding
        nextScreen =
            const OnboardingScreen(); // This will redirect to storage onboarding
      } else if (isLoggedIn && currentUser != null) {
        // Returning user who is already logged in - go directly to home
        print('✓ Returning user: ${currentUser.email ?? "Anonymous"}');
        
        // CHECK FOR BACKUP AND OFFER TO RESTORE
        // Restore check is now handled in StorageOnboardingScreen
        
        nextScreen = const NewHomeScreen();
      } else {
        // User completed onboarding but not logged in - show login screen
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Animated blue blob - upper right (subtle)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = _animationController.value;
              final pulseValue = math.sin(progress * 2 * 3.14159);
              final size = 500.0 + (pulseValue * 20);

              return Positioned(
                right: -200 + (pulseValue * 10),
                top: -150 + (pulseValue * 8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3E63DD).withOpacity(0.4),
                        const Color(0xFF3E63DD).withOpacity(0.25),
                        const Color(0xFF3E63DD).withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Animated blue blob - bottom left (subtle)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = _animationController.value;
              final pulseValue = math.sin(progress * 2 * 3.14159 + 3.14159);
              final size = 550.0 + (pulseValue * 24);

              return Positioned(
                left: -250 + (pulseValue * 12),
                bottom: -200 + (pulseValue * 10),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF5E81F3).withOpacity(0.45),
                        const Color(0xFF5E81F3).withOpacity(0.3),
                        const Color(0xFF5E81F3).withOpacity(0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Animated blue blob - upper right
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = _animationController.value;
              final pulseValue = math.sin(progress * 2 * 3.14159);
              final size = 500.0 + (pulseValue * 50);

              return Positioned(
                right: -200 + (pulseValue * 30),
                top: -150 + (pulseValue * 25),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3E63DD).withOpacity(0.4),
                        const Color(0xFF3E63DD).withOpacity(0.25),
                        const Color(0xFF3E63DD).withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Animated blue blob - bottom left
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = _animationController.value;
              final pulseValue = math.sin(progress * 2 * 3.14159 + 3.14159);
              final size = 550.0 + (pulseValue * 60);

              return Positioned(
                left: -250 + (pulseValue * 35),
                bottom: -200 + (pulseValue * 30),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF5E81F3).withOpacity(0.45),
                        const Color(0xFF5E81F3).withOpacity(0.3),
                        const Color(0xFF5E81F3).withOpacity(0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Centered Content with zoom + fade
          Center(
            child: ScaleTransition(
              scale: _zoomAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'DocuMate',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Securely managing your documents.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Show an immediate spinner so users see progress during pre-warm/startup
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
