import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
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
  static const String _imagesFolderName = 'DocuMate_Images';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // AppData folder for backup file
      drive.DriveApi.driveFileScope, // File access for document images
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

      // NEW: Sync all document images after metadata backup
      await _syncAllDocumentImages();

      _isSyncing = false;
      return true;
    } catch (e) {
      print('⚠ Backup upload failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// Sync all document images to Google Drive
  Future<void> _syncAllDocumentImages() async {
    try {
      print('🖼️  Starting image sync...');
      
      // Get all documents
      final allDocs = await _storageService.getAllDocuments();
      print('📦 Found ${allDocs.length} documents to check for images');
      
      int totalImages = 0;
      int syncedImages = 0;
      int skippedImages = 0;

      for (final entry in allDocs.entries) {
        final docId = entry.key;
        final docData = entry.value;
        final docName = docData['name'] ?? 'Unknown';

        print('📄 Processing document: $docName (ID: $docId)');

        // Count images in this document
        final imagePaths = docData['imagePaths'] as List?;
        if (imagePaths != null && imagePaths.isNotEmpty) {
          totalImages += imagePaths.length;
          print('   Found ${imagePaths.length} images');
        }

        // Sync images for this document
        final updatedFileIds = await syncDocumentImages(docData);
        
        if (updatedFileIds.isNotEmpty) {
          print('   ✓ Synced ${updatedFileIds.length} images to Drive');
          
          // Update document with Drive file IDs
          docData['driveFileIds'] = updatedFileIds;
          await _storageService.saveDocument(docId, docData);
          
          syncedImages += updatedFileIds.length;
        } else {
          print('   ⏭️ No new images to sync');
          skippedImages += (imagePaths?.length ?? 0);
        }
      }

      print('✓ Image sync complete:');
      print('  - Total documents: ${allDocs.length}');
      print('  - Total images: $totalImages');
      print('  - Newly synced: $syncedImages');
      print('  - Already synced: $skippedImages');
    } catch (e, stackTrace) {
      print('❌ Image sync error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download backup from Google Drive and merge with local data
  /// This runs in background and never blocks UI
  Future<bool> downloadBackup({
    bool overwrite = false,
    Function(String)? onStatusUpdate,
    Function(int, int)? onImageProgress,
  }) async {
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
      onStatusUpdate?.call('Downloading backup...');
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

      onStatusUpdate?.call('Restoring documents...');

      // Import into local storage
      await _storageService.importEncryptedBackup(backupData,
          overwrite: overwrite);

      print('✓ Backup downloaded and merged (${backupData.length} bytes)');

      onStatusUpdate?.call('Downloading images...');

      // NEW: Download all document images after metadata restore
      await _downloadAllDocumentImages(onImageProgress: onImageProgress);

      _isSyncing = false;
      return true;
    } catch (e) {
      print('⚠ Backup download failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// Download all document images from Google Drive
  Future<void> _downloadAllDocumentImages({Function(int, int)? onImageProgress}) async {
    try {
      print('🖼️  Starting image download...');
      
      // Get all documents
      final allDocs = await _storageService.getAllDocuments();
      print('📦 Found ${allDocs.length} documents to check for images');
      
      // First, count total images
      int totalImages = 0;
      for (final entry in allDocs.entries) {
        final docData = entry.value;
        final driveFileIds = docData['driveFileIds'] as Map<String, dynamic>?;
        if (driveFileIds != null) {
          totalImages += driveFileIds.length;
        }
      }

      if (totalImages == 0) {
        print('ℹ️ No images to download (no driveFileIds found in documents)');
        return;
      }

      print('📥 Found $totalImages images to download');
      int downloadedImages = 0;
      int skippedImages = 0;
      int failedImages = 0;

      for (final entry in allDocs.entries) {
        final docData = entry.value;
        final docName = docData['name'] ?? 'Unknown';
        final driveFileIds = docData['driveFileIds'] as Map<String, dynamic>?;

        if (driveFileIds == null || driveFileIds.isEmpty) {
          continue;
        }

        print('📄 Processing document: $docName');
        print('   Images in Drive: ${driveFileIds.length}');

        // Download each image
        for (final mapEntry in driveFileIds.entries) {
          final localPath = mapEntry.key;
          final driveFileId = mapEntry.value;

          print('   📥 Checking: ${path.basename(localPath)}');

          // Check if file already exists locally
          final file = File(localPath);
          if (await file.exists()) {
            print('      ⏭️ Already exists locally');
            skippedImages++;
            downloadedImages++;
            onImageProgress?.call(downloadedImages, totalImages);
            continue;
          }

          // Download from Drive
          print('      🔽 Downloading from Drive (ID: ${driveFileId.substring(0, 10)}...)');
          final success = await downloadImage(driveFileId, localPath);
          if (success) {
            print('      ✅ Downloaded successfully');
            downloadedImages++;
            onImageProgress?.call(downloadedImages, totalImages);
          } else {
            print('      ❌ Download failed');
            failedImages++;
          }
        }
      }

      print('✓ Image download complete:');
      print('  - Total images: $totalImages');
      print('  - Downloaded: ${downloadedImages - skippedImages}');
      print('  - Already existed: $skippedImages');
      print('  - Failed: $failedImages');
    } catch (e, stackTrace) {
      print('❌ Image download error: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw to let caller handle it
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

  // ==================== IMAGE SYNC ====================

  /// Find or create DocuMate_Images folder in Google Drive
  Future<String?> _findOrCreateImagesFolder() async {
    if (_driveApi == null) return null;

    try {
      // Search for existing folder
      final query = "name='$_imagesFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        print('✓ Found existing images folder: ${fileList.files!.first.id}');
        return fileList.files!.first.id;
      }

      // Create new folder
      final folderMetadata = drive.File()
        ..name = _imagesFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final folder = await _driveApi!.files.create(folderMetadata);
      print('✓ Created images folder: ${folder.id}');
      return folder.id;
    } catch (e) {
      print('⚠ Error finding/creating images folder: $e');
      return null;
    }
  }

  /// Upload a single image file to Google Drive (encrypted)
  Future<String?> uploadImage(String localFilePath, {Function(double)? onProgress}) async {
    if (_driveApi == null) {
      print('⚠ Drive API not initialized');
      return null;
    }

    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('⚠ Image file not found: $localFilePath');
        return null;
      }

      // Get or create images folder
      final folderId = await _findOrCreateImagesFolder();
      if (folderId == null) {
        print('⚠ Failed to get images folder');
        return null;
      }

      final fileName = path.basename(localFilePath);
      final fileBytes = await file.readAsBytes();

      // 🔐 ENCRYPT THE IMAGE BEFORE UPLOADING
      final encryptedBytes = await _storageService.encryptData(fileBytes);

      final driveFile = drive.File()
        ..name = '$fileName.enc' // Add .enc extension to indicate encryption
        ..parents = [folderId];

      final media = drive.Media(
        Stream.value(encryptedBytes),
        encryptedBytes.length,
      );

      print('📤 Uploading encrypted image: $fileName (${fileBytes.length} -> ${encryptedBytes.length} bytes)');
      
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      print('✓ Encrypted image uploaded: ${uploadedFile.id}');
      return uploadedFile.id;
    } catch (e) {
      print('⚠ Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images with progress tracking
  Future<Map<String, String>> uploadImages(
    List<String> imagePaths, {
    Function(int current, int total)? onProgress,
  }) async {
    final fileIdMap = <String, String>{}; // localPath -> driveFileId

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      
      onProgress?.call(i + 1, imagePaths.length);

      final fileId = await uploadImage(imagePath);
      if (fileId != null) {
        fileIdMap[imagePath] = fileId;
      }
    }

    return fileIdMap;
  }

  /// Download a single image from Google Drive (decrypt)
  Future<bool> downloadImage(String driveFileId, String localFilePath, {Function(double)? onProgress}) async {
    if (_driveApi == null) {
      print('⚠ Drive API not initialized');
      return false;
    }

    try {
      print('📥 Downloading encrypted image: $driveFileId');

      final media = await _driveApi!.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Collect all encrypted bytes
      final List<int> encryptedBytes = [];
      await media.stream.forEach((chunk) {
        encryptedBytes.addAll(chunk);
      });

      print('🔓 Decrypting image...');

      // 🔐 DECRYPT THE IMAGE AFTER DOWNLOADING
      final decryptedBytes = await _storageService.decryptData(Uint8List.fromList(encryptedBytes));

      final file = File(localFilePath);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write decrypted bytes to file
      await file.writeAsBytes(decryptedBytes);

      print('✓ Image downloaded and decrypted: $localFilePath');
      return true;
    } catch (e) {
      print('⚠ Error downloading image: $e');
      return false;
    }
  }

  /// Download multiple images with progress tracking
  Future<int> downloadImages(
    Map<String, String> fileIdMap, // localPath -> driveFileId
    {Function(int current, int total)? onProgress}
  ) async {
    int successCount = 0;
    final entries = fileIdMap.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      onProgress?.call(i + 1, entries.length);

      final success = await downloadImage(entry.value, entry.key);
      if (success) {
        successCount++;
      }
    }

    return successCount;
  }

  /// Sync document images (upload missing ones to Drive)
  Future<Map<String, String>> syncDocumentImages(Map<String, dynamic> documentData) async {
    final imagePaths = <String>[];
    
    // Collect all image paths from document
    if (documentData['imagePath'] != null) {
      imagePaths.add(documentData['imagePath'] as String);
    }
    if (documentData['imagePaths'] != null) {
      final paths = documentData['imagePaths'] as List;
      imagePaths.addAll(paths.cast<String>());
    }

    // Check which images need uploading
    final driveFileIds = documentData['driveFileIds'] as Map<String, dynamic>? ?? {};
    final imagesToUpload = <String>[];

    for (final imagePath in imagePaths) {
      if (!driveFileIds.containsKey(imagePath)) {
        imagesToUpload.add(imagePath);
      }
    }

    if (imagesToUpload.isEmpty) {
      print('✓ All images already synced');
      return driveFileIds.cast<String, String>();
    }

    // Upload new images
    print('📤 Uploading ${imagesToUpload.length} new images...');
    final newFileIds = await uploadImages(imagesToUpload);
    
    // Merge with existing file IDs
    final updatedFileIds = <String, String>{...driveFileIds.cast<String, String>(), ...newFileIds};
    
    return updatedFileIds;
  }
}

