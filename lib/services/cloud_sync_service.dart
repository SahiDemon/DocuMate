import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'package:documate/config/auth_config.dart';

/// CloudSyncService handles Google Drive backup/restore operations.
/// - Runs in background without blocking UI
/// - Uploads/downloads single encrypted backup file to Drive AppData
/// - Automatically syncs on app startup if backup is enabled
/// - User data remains encrypted, Google cannot read the contents
class CloudSyncService {
  static const String _backupFileName = 'documate_backup.bin';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // AppData folder - hidden from user
    ],
    // Helps reliably fetch idToken on Android when also signing into Firebase
    serverClientId: kGoogleServerClientId.isEmpty ? null : kGoogleServerClientId,
  );

  final StorageService _storageService;
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  bool _isSyncing = false;

  CloudSyncService(this._storageService);

  // ==================== GOOGLE SIGN-IN ====================

  /// Check if user is already signed in
  Future<bool> isSignedIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      if (account != null) {
        await _initializeDriveApi();
      }
      return account != null;
    } catch (e) {
      print('⚠ Error checking sign-in status: $e');
      return false;
    }
  }

  /// Sign in with Google (shows UI)
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;

      if (account != null) {
        await _initializeDriveApi();
        print('✓ Signed in as: ${account.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('⚠ Google Sign-In error: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      print('✓ Signed out from Google');
    } catch (e) {
      print('⚠ Sign-out error: $e');
    }
  }

  /// Get current signed-in Google account
  GoogleSignInAccount? getCurrentAccount() {
    return _currentUser;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _currentUser?.email;
  }

  /// Initialize Drive API client
  Future<void> _initializeDriveApi() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception('Failed to get authenticated HTTP client');
      }

      _driveApi = drive.DriveApi(httpClient);
      print('✓ Drive API initialized');
    } catch (e) {
      print('⚠ Error initializing Drive API: $e');
      rethrow;
    }
  }

  // ==================== CLOUD SYNC OPERATIONS ====================

  /// Upload encrypted backup to Google Drive AppData
  /// This runs in background and never blocks UI
  Future<bool> uploadBackup() async {
    if (_isSyncing) {
      print('⚠ Sync already in progress');
      return false;
    }

    if (_driveApi == null) {
      print('⚠ Drive API not initialized. Sign in first.');
      return false;
    }

    _isSyncing = true;

    try {
      print('📤 Starting backup upload...');

      // Export encrypted backup from local storage
      final backupData = await _storageService.exportEncryptedBackup();

      // Check if backup file already exists in Drive AppData
      final existingFileId = await _findBackupFile();

      final driveFile = drive.File()
        ..name = _backupFileName
        ..modifiedTime = DateTime.now().toUtc();

      final media = drive.Media(
        Stream.value(backupData),
        backupData.length,
      );

      if (existingFileId != null) {
        // Update existing file
        await _driveApi!.files.update(
          driveFile,
          existingFileId,
          uploadMedia: media,
        );
        print('✓ Backup updated successfully (${backupData.length} bytes)');
      } else {
        // Create new file in AppData
        driveFile.parents = ['appDataFolder'];
        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        print('✓ Backup created successfully (${backupData.length} bytes)');
      }

      _isSyncing = false;
      return true;
    } catch (e) {
      print('⚠ Backup upload failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// Download backup from Google Drive and merge with local data
  /// This runs in background and never blocks UI
  Future<bool> downloadBackup({bool overwrite = false}) async {
    if (_isSyncing) {
      print('⚠ Sync already in progress');
      return false;
    }

    if (_driveApi == null) {
      print('⚠ Drive API not initialized. Sign in first.');
      return false;
    }

    _isSyncing = true;

    try {
      print('📥 Starting backup download...');

      // Find backup file in Drive AppData
      final fileId = await _findBackupFile();

      if (fileId == null) {
        print('ℹ No backup found in Drive');
        _isSyncing = false;
        return false;
      }

      // Download file content
      final drive.Media? media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media?;

      if (media == null) {
        throw Exception('Failed to download backup file');
      }

      // Read stream data
      final List<int> dataBytes = [];
      await for (final chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      final backupData = Uint8List.fromList(dataBytes);

      // Import into local storage
      await _storageService.importEncryptedBackup(backupData,
          overwrite: overwrite);

      print('✓ Backup downloaded and merged (${backupData.length} bytes)');
      _isSyncing = false;
      return true;
    } catch (e) {
      print('⚠ Backup download failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// Find backup file in Drive AppData folder
  Future<String?> _findBackupFile() async {
    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      return null;
    } catch (e) {
      print('⚠ Error finding backup file: $e');
      return null;
    }
  }

  /// Get backup metadata from Drive
  Future<Map<String, dynamic>?> getBackupInfo() async {
    if (_driveApi == null) return null;

    try {
      final fileId = await _findBackupFile();
      if (fileId == null) return null;

      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'id, name, size, modifiedTime',
      ) as drive.File;

      return {
        'exists': true,
        'size': file.size,
        'lastModified': file.modifiedTime?.toIso8601String(),
        'name': file.name,
      };
    } catch (e) {
      print('⚠ Error getting backup info: $e');
      return null;
    }
  }

  /// Delete backup from Drive
  Future<bool> deleteBackup() async {
    if (_driveApi == null) return false;

    try {
      final fileId = await _findBackupFile();
      if (fileId == null) {
        print('ℹ No backup to delete');
        return true;
      }

      await _driveApi!.files.delete(fileId);
      print('✓ Backup deleted from Drive');
      return true;
    } catch (e) {
      print('⚠ Error deleting backup: $e');
      return false;
    }
  }

  // ==================== AUTO-SYNC ====================

  /// Perform automatic sync on app startup
  /// Downloads backup if available and newer than local data
  Future<void> autoSyncOnStartup() async {
    if (_driveApi == null) {
      print('ℹ Auto-sync skipped: Not signed in to Google');
      return;
    }

    try {
      print('🔄 Running auto-sync...');

      final backupInfo = await getBackupInfo();

      if (backupInfo != null && backupInfo['exists'] == true) {
        // Download and merge (not overwrite) with local data
        await downloadBackup(overwrite: false);
      } else {
        print('ℹ No cloud backup found');
      }
    } catch (e) {
      print('⚠ Auto-sync error: $e');
    }
  }

  // ==================== UTILITY ====================

  bool get isSyncing => _isSyncing;

  /// Check if backup is enabled
  Future<bool> isBackupEnabled() async {
    final enabled =
        await _storageService.getSetting('backup_enabled', defaultValue: false);
    return enabled as bool;
  }

  /// Enable/disable backup
  Future<void> setBackupEnabled(bool enabled) async {
    await _storageService.saveSetting('backup_enabled', enabled);

    if (!enabled) {
      await signOut();
    }
  }
}
