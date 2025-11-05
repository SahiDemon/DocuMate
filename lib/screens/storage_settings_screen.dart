import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:intl/intl.dart';

/// StorageSettingsScreen allows users to:
/// - Toggle Google Drive backup on/off
/// - View backup status and sync information
/// - Manually trigger backup/restore
/// - View storage statistics
class StorageSettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final CloudSyncService cloudSyncService;

  const StorageSettingsScreen({
    super.key,
    required this.storageService,
    required this.cloudSyncService,
  });

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  bool _backupEnabled = false;
  bool _isLoading = false;
  String? _userEmail;
  Map<String, dynamic>? _backupInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await widget.cloudSyncService.isBackupEnabled();
    final signedIn = await widget.cloudSyncService.isSignedIn();

    setState(() {
      _backupEnabled = enabled;
      if (signedIn) {
        _userEmail = widget.cloudSyncService.getCurrentUserEmail();
      }
    });

    if (_backupEnabled && signedIn) {
      _loadBackupInfo();
    }
  }

  Future<void> _loadBackupInfo() async {
    final info = await widget.cloudSyncService.getBackupInfo();
    setState(() {
      _backupInfo = info;
    });
  }

  Future<void> _toggleBackup(bool value) async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (value) {
        // Enable backup - sign in to Google
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

        await widget.cloudSyncService.setBackupEnabled(true);

        // Upload initial backup
        final uploaded = await widget.cloudSyncService.uploadBackup();

        if (uploaded) {
          setState(() {
            _backupEnabled = true;
            _userEmail = widget.cloudSyncService.getCurrentUserEmail();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Backup enabled and uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }

          _loadBackupInfo();
        }
      } else {
        // Disable backup
        await widget.cloudSyncService.setBackupEnabled(false);
        await widget.cloudSyncService.signOut();

        setState(() {
          _backupEnabled = false;
          _userEmail = null;
          _backupInfo = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup disabled'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _manualBackup() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final success = await widget.cloudSyncService.uploadBackup();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Backup uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _manualRestore() async {
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Restore from Backup?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will download your backup from Google Drive and merge it with local data. Your existing data will not be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81F3),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final success =
          await widget.cloudSyncService.downloadBackup(overwrite: false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup found in Drive'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
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
    final documentCount = widget.storageService.getDocumentCount();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Storage & Backup',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5E81F3),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Local Storage Info
                  _buildSection(
                    title: 'Local Storage',
                    icon: Icons.smartphone,
                    children: [
                      _buildInfoRow('Documents stored', '$documentCount'),
                      _buildInfoRow('Storage type', 'Encrypted (AES-256)'),
                      _buildInfoRow('Encryption key', 'Stored in OS keychain'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Drive Backup
                  _buildSection(
                    title: 'Google Drive Backup',
                    icon: Icons.cloud_upload,
                    children: [
                      SwitchListTile(
                        value: _backupEnabled,
                        onChanged: _toggleBackup,
                        title: const Text(
                          'Enable Backup',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _backupEnabled
                              ? 'Automatically backs up to Google Drive'
                              : 'Store data locally only',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        activeThumbColor: const Color(0xFF5E81F3),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_backupEnabled) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        if (_userEmail != null)
                          _buildInfoRow('Google Account', _userEmail!),
                        if (_backupInfo != null) ...[
                          _buildInfoRow(
                            'Last backup',
                            _backupInfo!['lastModified'] != null
                                ? DateFormat('MMM d, y h:mm a').format(
                                    DateTime.parse(
                                        _backupInfo!['lastModified']),
                                  )
                                : 'Never',
                          ),
                          _buildInfoRow(
                            'Backup size',
                            _formatBytes(_backupInfo!['size']),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _manualBackup,
                                icon: const Icon(Icons.cloud_upload, size: 18),
                                label: const Text('Backup Now'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF5E81F3),
                                  side: const BorderSide(
                                    color: Color(0xFF5E81F3),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _manualRestore,
                                icon:
                                    const Icon(Icons.cloud_download, size: 18),
                                label: const Text('Restore'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.white.withOpacity(0.8),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Privacy Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.security,
                              color: Color(0xFF5E81F3),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Zero-Knowledge Encryption',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All your data is encrypted on your device before being stored or uploaded. The encryption key never leaves your device, ensuring complete privacy. Even Google cannot read your backup files.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF5E81F3),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return 'Unknown';

    final int size = int.tryParse(bytes.toString()) ?? 0;

    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
