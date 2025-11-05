import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Storage Privacy Screen - explains privacy features before completing setup
class StoragePrivacyScreen extends StatefulWidget {
  const StoragePrivacyScreen({super.key});

  @override
  State<StoragePrivacyScreen> createState() => _StoragePrivacyScreenState();
}

class _StoragePrivacyScreenState extends State<StoragePrivacyScreen> {
  void _handleContinue() {
    HapticFeedback.mediumImpact();
    // Navigate to storage onboarding to choose local/cloud
    Navigator.of(context).pushReplacementNamed('/storage-onboarding');
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
              const SizedBox(height: 60),

              // Shield icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5E81F3).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5E81F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 40,
                      color: Color(0xFF121212),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Your Privacy, Our Priority',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We are committed to protecting your data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 48),

              // Privacy Feature 1
              _buildPrivacyFeature(
                icon: Icons.cloud_off,
                title: 'We don\'t store your data',
                description:
                    'Your documents and personal information are stored only on your device or your chosen cloud provider. We have no access to them.',
              ),

              const SizedBox(height: 20),

              // Privacy Feature 2
              _buildPrivacyFeature(
                icon: Icons.lock,
                title: 'End-to-End Encryption',
                description:
                    'Everything you store is encrypted with a key that only you hold. This ensures that no one, not even us, can access your files.',
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF3E63DD).withOpacity(0.3),
                  ),
                  child: const Row(
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

  Widget _buildPrivacyFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5E81F3).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5E81F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
