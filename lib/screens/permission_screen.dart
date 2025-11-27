import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:documate/main.dart' show storageService;

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  Future<void> _handlePermissions() async {
    setState(() => _isRequesting = true);
    HapticFeedback.mediumImpact();

    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.notification,
        Permission.storage, // For older Android
        Permission.photos, // For Android 13+
      ].request();

      print('Permissions requested: $statuses');

      // Save flag that we've requested permissions
      await storageService.saveSetting('permissions_requested_v2', true);

      if (mounted) {
        // Navigate to storage onboarding (Local vs Cloud)
        Navigator.of(context).pushReplacementNamed('/storage-onboarding');
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        // Proceed anyway
        Navigator.of(context).pushReplacementNamed('/storage-onboarding');
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
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

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E81F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 48,
                    color: Color(0xFF5E81F3),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Permissions Needed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'To provide the best experience, DocuMate needs access to a few things.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // Permission Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildPermissionItem(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera Access',
                        description:
                            'Required to scan documents and capture images directly within the app.',
                      ),
                      const SizedBox(height: 20),
                      _buildPermissionItem(
                        icon: Icons.folder_open_rounded,
                        title: 'Storage Access',
                        description:
                            'Needed to save your encrypted documents and import existing files.',
                      ),
                      const SizedBox(height: 20),
                      _buildPermissionItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notifications',
                        description:
                            'To remind you of important document expirations and deadlines.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _handlePermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF3E63DD).withOpacity(0.3),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Grant Permissions',
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

              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed('/storage-onboarding');
                },
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
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
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
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
