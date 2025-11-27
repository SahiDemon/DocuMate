import 'package:flutter/material.dart';
import 'package:documate/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  State<PasswordSecurityScreen> createState() => _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState extends State<PasswordSecurityScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isChangingPassword = false;

  User? _user;
  bool _isPasswordProvider = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUser() {
    _user = _authService.getCurrentUser();
    _isPasswordProvider =
        _user?.providerData.any((p) => p.providerId == 'password') ?? false;
    setState(() {});
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: _currentPasswordController.text,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Update password
      await _user!.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordReset(_user!.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Password & Security',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isPasswordProvider) ...[
                    // Google Sign-In User
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.g_mobiledata,
                              size: 50,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Signed in with Google',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Password management is handled by Google',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Password Provider User
                    if (!_isChangingPassword) ...[
                      // Change Password Button
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keep your account secure with a strong password',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => _isChangingPassword = true),
                                icon: const Icon(Icons.edit),
                                label: const Text('Change Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _sendPasswordResetEmail,
                                icon: const Icon(Icons.email),
                                label: const Text('Send Reset Email'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme
                                      .textTheme.bodyLarge?.color
                                      ?.withOpacity(0.8),
                                  side: BorderSide(color: theme.dividerColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Change Password Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withOpacity(0.9),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: theme.textTheme.bodyLarge?.color),
                                  onPressed: () {
                                    setState(() {
                                      _isChangingPassword = false;
                                      _currentPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Current Password
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: !_showCurrentPassword,
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                labelStyle: TextStyle(
                                    color: theme.textTheme.bodySmall?.color),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showCurrentPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  onPressed: () => setState(() =>
                                      _showCurrentPassword =
                                          !_showCurrentPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            TextField(
                              controller: _newPasswordController,
                              obscureText: !_showNewPassword,
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                labelStyle: TextStyle(
                                    color: theme.textTheme.bodySmall?.color),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  onPressed: () => setState(() =>
                                      _showNewPassword = !_showNewPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: !_showConfirmPassword,
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                labelStyle: TextStyle(
                                    color: theme.textTheme.bodySmall?.color),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  onPressed: () => setState(() =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Update Password'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Security Tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security,
                                color: theme.primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Security Tips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSecurityTip('Use a strong, unique password'),
                        _buildSecurityTip(
                            'Enable two-factor authentication (coming soon)'),
                        _buildSecurityTip('Never share your password'),
                        _buildSecurityTip('Change your password regularly'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
