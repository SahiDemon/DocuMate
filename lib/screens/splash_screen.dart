import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:documate/screens/onboarding_screen.dart';
import 'package:documate/screens/new_home_screen.dart';

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

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_welcome') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              hasSeenOnboarding
                  ? const NewHomeScreen()
                  : const OnboardingScreen(),
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
