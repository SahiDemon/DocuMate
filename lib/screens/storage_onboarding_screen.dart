import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:documate/services/firebase_auth_service.dart';

/// StorageOnboardingScreen asks user where they want to store their data
/// on first app launch. Matches the design from the screenshot with beautiful
/// animations and clear privacy messaging.
class StorageOnboardingScreen extends StatefulWidget {
  final StorageService storageService;
  final CloudSyncService cloudSyncService;

  const StorageOnboardingScreen({
    super.key,
    required this.storageService,
    required this.cloudSyncService,
  });

  @override
  State<StorageOnboardingScreen> createState() =>
      _StorageOnboardingScreenState();
}

class _StorageOnboardingScreenState extends State<StorageOnboardingScreen>
    with SingleTickerProviderStateMixin {
  StorageOption _selectedOption = StorageOption.localOnly;
  bool _isLoading = false;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Cloud icon float animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();

    try {
      setState(() => _isLoading = true);

      if (_selectedOption == StorageOption.googleDrive) {
        // ========== GOOGLE DRIVE + FIREBASE AUTH FLOW ==========
        // 1. Sign in with Google (for Drive access)
        final success = await widget.cloudSyncService.signIn();
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google sign-in cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 2. Get the current Google account (already signed in)
        final googleAccount = widget.cloudSyncService.getCurrentAccount();
        if (googleAccount == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to get Google account'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 3. Auto-create Firebase account using the same Google account (no double login)
        final firebaseAuth = FirebaseAuthService();
        final user = await firebaseAuth.signInWithGoogleAccount(googleAccount);

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firebase authentication failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 3. Enable backup and upload initial backup
        await widget.cloudSyncService.setBackupEnabled(true);
        await widget.cloudSyncService.uploadBackup();

        // 4. Mark storage onboarding as complete
        await widget.storageService
            .saveSetting('storage_onboarding_complete', true);

        setState(() => _isLoading = false);

        // 5. Navigate directly to home with success message
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');

          // Show success message
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome to DocuMate!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Signed in as ${user.email ?? "user"}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
        }
      } else {
        // ========== LOCAL ONLY FLOW ==========
        // 1. Disable backup
        await widget.cloudSyncService.setBackupEnabled(false);

        // 2. Mark storage onboarding as complete
        await widget.storageService
            .saveSetting('storage_onboarding_complete', true);

        setState(() => _isLoading = false);

        // 3. Navigate to login/register screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Cloud icon with float animation
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF5E81F3).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_done,
                    size: 100,
                    color: Color(0xFF5E81F3),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Where do you want to\nstore your data?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Choose an option to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // Local Only Option
              _buildStorageOption(
                option: StorageOption.localOnly,
                icon: Icons.smartphone,
                title: 'Local Only',
                description:
                    'Keep your documents stored exclusively on this device.',
                isSelected: _selectedOption == StorageOption.localOnly,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOption = StorageOption.localOnly);
                },
              ),

              const SizedBox(height: 16),

              // Google Drive Option
              _buildStorageOption(
                option: StorageOption.googleDrive,
                icon: Icons.cloud_upload,
                iconWidget: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDkfSxmm6VGtRH18uYZWgM3JHuO17UEoEYt-nDrDj2lNr626lACEca1cmj_qcRJHqLIPItC2r4h7T6JphPV7htdB3WN70Ou2paGmRuseBgoCWZG3hwSXP7n5uKcKAHKQyT2K-B5wRULcbSceZbeuyAzMTl6vR94Gy_ciqt9D-zLXPFIzDjCihi96sY8SXkwrGIX04oZ9z4MyTkACF_Q8jbf5U3D4H37WS3_nr8FXHiEucdbHjY2t0ffAOYkcnEJikSJTUGlgTnYP-U',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.cloud_upload,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                title: 'Local + Backup to Google Drive',
                description:
                    'Store on device and securely back up to your cloud storage.',
                isSelected: _selectedOption == StorageOption.googleDrive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOption = StorageOption.googleDrive);
                },
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF3E63DD).withOpacity(0.3),
                    disabledBackgroundColor:
                        const Color(0xFF5E81F3).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageOption({
    required StorageOption option,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5E81F3).withOpacity(0.1)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5E81F3)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5E81F3).withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 28,
                      color: isSelected
                          ? const Color(0xFF5E81F3)
                          : Colors.white.withOpacity(0.6),
                    ),
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5E81F3)
                      : Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                color: const Color(0xFF121212),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5E81F3),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

enum StorageOption {
  localOnly,
  googleDrive,
}
