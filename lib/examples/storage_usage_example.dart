import 'package:flutter/material.dart';
import 'package:documate/main.dart' show storageService, cloudSyncService;

/// Example of how to use the DocuMate storage system
///
/// This file demonstrates common operations:
/// 1. Saving documents with encryption
/// 2. Loading documents
/// 3. Managing cloud backup
/// 4. Accessing storage settings

class StorageUsageExample extends StatefulWidget {
  const StorageUsageExample({super.key});

  @override
  State<StorageUsageExample> createState() => _StorageUsageExampleState();
}

class _StorageUsageExampleState extends State<StorageUsageExample> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  // ==================== LOAD DOCUMENTS ====================
  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      // Get all documents from encrypted storage
      final allDocs = await storageService.getAllDocuments();

      setState(() {
        _documents =
            allDocs.entries.map((e) => {'id': e.key, ...e.value}).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== SAVE DOCUMENT ====================
  Future<void> _saveDocument() async {
    final documentData = {
      'title': 'Driver License',
      'type': 'id_card',
      'expiryDate':
          DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'imageUrl': '/path/to/image.jpg',
      'metadata': {
        'issuer': 'DMV',
        'documentNumber': 'DL-123456',
      },
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // Save to encrypted local storage
      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      await storageService.saveDocument(documentId, documentData);

      // Optionally trigger cloud backup if enabled
      final backupEnabled = await cloudSyncService.isBackupEnabled();
      if (backupEnabled) {
        // Upload in background (fire and forget)
        cloudSyncService.uploadBackup().catchError((e) {
          print('Background backup failed: $e');
          return false;
        });
      }

      // Reload documents
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Document saved and encrypted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving document: $e');
    }
  }

  // ==================== DELETE DOCUMENT ====================
  Future<void> _deleteDocument(String documentId) async {
    try {
      await storageService.deleteDocument(documentId);
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  // ==================== TRIGGER MANUAL BACKUP ====================
  Future<void> _manualBackup() async {
    final backupEnabled = await cloudSyncService.isBackupEnabled();

    if (!backupEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud backup is not enabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await cloudSyncService.uploadBackup();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✓ Backup uploaded to Google Drive'
                : 'Backup failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Backup error: $e');
    }
  }

  // ==================== SAVE SETTING ====================
  Future<void> _saveSetting() async {
    try {
      await storageService.saveSetting('app_theme', 'dark');
      await storageService.saveSetting('notifications_enabled', true);

      print('Settings saved');
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // ==================== GET SETTING ====================
  Future<void> _getSetting() async {
    try {
      final theme =
          await storageService.getSetting('app_theme', defaultValue: 'light');
      final notificationsEnabled = await storageService.getSetting(
        'notifications_enabled',
        defaultValue: false,
      );

      print('Theme: $theme, Notifications: $notificationsEnabled');
    } catch (e) {
      print('Error getting settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Storage Usage Example',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to storage settings
              Navigator.of(context).pushNamed('/storage-settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5E81F3),
              ),
            )
          : Column(
              children: [
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveDocument,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E81F3),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _manualBackup,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Backup Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E63DD),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveSetting,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Setting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _getSetting,
                        icon: const Icon(Icons.info),
                        label: const Text('Get Setting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Documents List
                Expanded(
                  child: _documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No documents yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Add Document" to create one',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.description,
                                  color: Color(0xFF5E81F3),
                                ),
                                title: Text(
                                  doc['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Type: ${doc['type'] ?? 'Unknown'}\n'
                                  'Created: ${doc['createdAt'] != null ? DateTime.parse(doc['createdAt']).toString().substring(0, 16) : 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteDocument(doc['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Storage Info Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.folder,
                        label: 'Documents',
                        value: '${_documents.length}',
                      ),
                      _buildStatItem(
                        icon: Icons.lock,
                        label: 'Encryption',
                        value: 'AES-256',
                      ),
                      _buildStatItem(
                        icon: Icons.cloud,
                        label: 'Backup',
                        value: 'Enabled', // You can make this dynamic
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF5E81F3), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
