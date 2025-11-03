import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<AnimationController> _rotationControllers;
  late AnimationController _bloomController;
  late Animation<double> _bloomIntensityAnimation;
  late Animation<double> _bloomSpreadAnimation;
  late AnimationController _iconMorphController;
  late Animation<double> _iconMorphAnimation;
  late AnimationController _iconBreathingController;
  late Animation<double> _iconBreathingAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'DocuMate',
      description:
          'Your ultimate solution for managing and organizing important documents.',
      mainIcon: Icons.shield,
      hasLock: true,
      showFloatingIcons: false,
    ),
    OnboardingPage(
      title: 'Easy Document Capture',
      description:
          'Scan documents on the go. Turn your phone into a powerful portable scanner.',
      mainIcon: Icons.camera_alt,
      floatingIcon1: Icons.crop_free,
      floatingIcon2: Icons.article,
    ),
    OnboardingPage(
      title: 'Automated Data Extraction',
      description:
          'Instantly pull key information from your documents. No more manual data entry.',
      mainIcon: Icons.document_scanner,
      floatingIcon1: Icons.data_object,
      floatingIcon2: Icons.storage,
    ),
    OnboardingPage(
      title: 'Smart Reminders',
      description:
          'Never miss a deadline. Get intelligent reminders for important dates.',
      mainIcon: Icons.notifications,
      floatingIcon1: Icons.alarm,
      floatingIcon2: Icons.calendar_month,
      isReverse: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Rotating ring controllers - continuous rotation (one per page, never stops)
    _rotationControllers = List.generate(
      _pages.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12),
      )..repeat(), // Start all immediately and keep running
    );

    // Bloom pulse controller - triggered on page change only
    _bloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bloomIntensityAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _bloomController,
        curve: Curves.easeOutExpo,
      ),
    );

    _bloomSpreadAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(
        parent: _bloomController,
        curve: Curves.easeOutExpo,
      ),
    );

    // Icon morph controller - triggered on page change only
    _iconMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconMorphAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _iconMorphController,
        curve: Curves.easeOutExpo,
      ),
    );

    // Icon breathing controller - continuous loop
    _iconBreathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _iconBreathingAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _iconBreathingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bloomController.dispose();
    _iconMorphController.dispose();
    _iconBreathingController.dispose();
    for (var controller in _rotationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // PageView with ONLY graphics and text
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  // Trigger haptic feedback
                  HapticFeedback.lightImpact();
                  // Trigger bloom pulse animation (one-time)
                  _bloomController.forward(from: 0.0);
                  // Trigger icon morph animation (one-time)
                  _iconMorphController.forward(from: 0.0).then((_) {
                    _iconMorphController.reverse();
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index], index);
                },
              ),
            ),
            // STATIC bottom section - OUTSIDE PageView, NEVER MOVES
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildPageIndicator(),
                  const SizedBox(height: 24),
                  _buildButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page, int pageIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Illustration - NEVER fades, always visible
          _buildIllustration(page, pageIndex),
          const Spacer(),
          // Animated text content only
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutExpo,
            switchOutCurve: Curves.easeInExpo,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutExpo,
                  )),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<int>(pageIndex),
              children: [
                // Title
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _currentPage == 0 ? 36 : 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildIllustration(OnboardingPage page, int pageIndex) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationControllers[pageIndex],
          _bloomController,
          _iconMorphController,
          _iconBreathingController,
        ]),
        builder: (context, _) {
          // Rotation angle for the ring
          final rotationAngle = _rotationControllers[pageIndex].value *
              2 *
              math.pi *
              (page.isReverse ? -1 : 1);

          // Pulse expansion for the ring
          final pulseValue =
              math.sin(_rotationControllers[pageIndex].value * 2 * math.pi * 3);
          final expandSize = 260 + (pulseValue * 15);

          // Bloom intensity multiplier (1.0 normally, up to 2.5 during bloom pulse)
          final bloomIntensity = _bloomIntensityAnimation.value;
          final bloomSpread = _bloomSpreadAnimation.value;

          // Calculate glow position on the ring (follows the bright spot)
          final glowX = math.cos(rotationAngle) * 115;
          final glowY = math.sin(rotationAngle) * 115;

          // Combined icon scale (breathing + morph)
          final breathingScale = _iconBreathingAnimation.value;
          final morphScale = _iconMorphAnimation.value;
          final combinedIconScale = breathingScale * morphScale;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Static base glow - always present, professional subtle look
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E81F3).withOpacity(0.12),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: const Color(0xFF5E81F3).withOpacity(0.08),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),

              // Subtle moving glow that follows the ring highlight
              Positioned(
                left: 130 + glowX - 50,
                top: 130 + glowY - 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Subtle traveling light - professional look
                      BoxShadow(
                        color: const Color(0xFF5E81F3)
                            .withOpacity(0.15 * bloomIntensity),
                        blurRadius: 60 * bloomSpread,
                        spreadRadius: 20 * bloomSpread,
                      ),
                      BoxShadow(
                        color: const Color(0xFF5E81F3)
                            .withOpacity(0.1 * bloomIntensity),
                        blurRadius: 80 * bloomSpread,
                        spreadRadius: 30 * bloomSpread,
                      ),
                    ],
                  ),
                ),
              ),

              // Rotating gradient ring (continuous rotation)
              Transform.rotate(
                angle: rotationAngle,
                child: Container(
                  width: expandSize,
                  height: expandSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF5E81F3),
                        const Color(0xFF5E81F3).withOpacity(0.6),
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF5E81F3).withOpacity(0.6),
                        const Color(0xFF5E81F3),
                      ],
                      stops: const [0.0, 0.15, 0.3, 0.7, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // Inner dark circle - solid to cover glow behind icon
              Container(
                width: 252,
                height: 252,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF121212),
                ),
              ),

              // Main Icon with breathing + morph animations
              Transform.scale(
                scale: combinedIconScale,
                child: page.hasLock
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            page.mainIcon,
                            size: 100,
                            color: const Color(0xFF5E81F3),
                          ),
                          const Icon(
                            Icons.lock,
                            size: 40,
                            color: Color(0xFF121212),
                          ),
                        ],
                      )
                    : Icon(
                        page.mainIcon,
                        size: 100,
                        color: const Color(0xFF5E81F3),
                      ),
              ),

              // Floating Icon 1 (top-left)
              if (page.showFloatingIcons && page.floatingIcon1 != null)
                Positioned(
                  left: 30,
                  top: 60,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      page.floatingIcon1,
                      size: 20,
                      color: const Color(0xFF5E81F3),
                    ),
                  ),
                ),

              // Floating Icon 2 (bottom-right)
              if (page.showFloatingIcons && page.floatingIcon2 != null)
                Positioned(
                  right: 25,
                  bottom: 50,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      page.floatingIcon2,
                      size: 28,
                      color: const Color(0xFF5E81F3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 6 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF5E81F3)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final isLastPage = _currentPage == _pages.length - 1;

    if (isLastPage) {
      // Only "Get Started" button on last page
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _completeOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5E81F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF3E63DD).withOpacity(0.3),
          ),
          child: const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // "Skip" and "Next" buttons for other pages
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _skipToEnd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E81F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF3E63DD).withOpacity(0.3),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData mainIcon;
  final IconData? floatingIcon1;
  final IconData? floatingIcon2;
  final bool hasLock;
  final bool showFloatingIcons;
  final bool isReverse;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.mainIcon,
    this.floatingIcon1,
    this.floatingIcon2,
    this.hasLock = false,
    this.showFloatingIcons = true,
    this.isReverse = false,
  });
}
