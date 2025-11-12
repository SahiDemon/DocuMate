import 'package:flutter/material.dart';
import 'package:documate/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:documate/screens/auth/login_screen.dart';
import 'package:documate/screens/category_management_screen.dart';
import 'package:documate/utils/transitions.dart';
import 'package:documate/main.dart' as main_app;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _user = _authService.getCurrentUser();
    });
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(subtleScaleSlideRoute(page: const LoginScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.displayName ?? 'Your Name';
    final email = _user?.email ?? 'you@example.com';
    final photo = _user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: const Color(0xFFE5E5E5),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.015,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      color: const Color(0xFFE5E5E5),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Picture and Info
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                const Color(0xFF5E81F3).withOpacity(0.2),
                            backgroundImage:
                                photo != null ? NetworkImage(photo) : null,
                            child: photo == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0]
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Color(0xFF5E81F3),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5E81F3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF121212),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 12),
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person,
                              title: 'Account Information',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.lock,
                              title: 'Password & Security',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.credit_card,
                              title: 'Subscription',
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Settings Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 12),
                          child: Text(
                            'SETTINGS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.category,
                              title: 'Manage Categories',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CategoryManagementScreen(
                                      storageService: main_app.storageService,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.notifications,
                              title: 'Notification Settings',
                              onTap: () => Navigator.pushNamed(
                                  context, '/notification-settings'),
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.cloud,
                              title: 'Storage & Backup',
                              onTap: () => Navigator.pushNamed(
                                  context, '/storage-settings'),
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.palette,
                              title: 'Appearance',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.key,
                              title: 'Encryption Key Info',
                              onTap: _showEncryptionKeyInfo,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Log Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 12),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF5E81F3),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEncryptionKeyInfo() async {
    final key = await main_app.storageService.getCurrentEncryptionKey();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5E81F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.key,
                color: Color(0xFF5E81F3),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Encryption Key',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your device is secured with AES-256 encryption.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5E81F3).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Key Status: Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Key Preview:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key != null ? '${key.substring(0, 16)}...' : 'Not available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5E81F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF5E81F3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This key is synced via Google Drive and follows you across devices.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF5E81F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
