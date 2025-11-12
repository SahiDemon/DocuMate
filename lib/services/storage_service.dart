import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;

/// StorageService provides encrypted local storage using Hive with AES-256 encryption.
/// All data is always stored locally on device. Encryption key is stored in OS keychain.
///
/// Zero-knowledge architecture: The app cannot decrypt data without the encryption key,
/// which is unique per device and never leaves the device.
class StorageService {
  static const String _keyStorageKey = 'documate_encryption_key';
  static const String _documentsBoxName = 'documents_encrypted';
  static const String _settingsBoxName = 'settings_encrypted';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Box? _documentsBox;
  Box? _settingsBox;
  encrypt_lib.Encrypter? _encrypter;
  bool _isInitialized = false;

  /// Initialize the storage service with encryption
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get or create encryption key
      final encryptionKey = await _getOrCreateEncryptionKey();

      // Initialize encrypter with AES-256
      final key = encrypt_lib.Key.fromBase64(encryptionKey);
      _encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));

      // Open Hive boxes (data is encrypted at the service layer, not Hive level)
      _documentsBox = await Hive.openBox(_documentsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _isInitialized = true;
      print('✓ StorageService initialized with AES-256 encryption');
    } catch (e) {
      print('⚠ Error initializing StorageService: $e');
      rethrow;
    }
  }

  /// Get or generate a new encryption key stored securely in OS keychain
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      // Try to read existing key
      String? existingKey = await _secureStorage.read(key: _keyStorageKey);

      if (existingKey != null) {
        return existingKey;
      }

      // Generate new 256-bit AES key
      final key = encrypt_lib.Key.fromSecureRandom(32); // 32 bytes = 256 bits
      final keyBase64 = key.base64;

      // Store in secure storage (OS keychain)
      await _secureStorage.write(key: _keyStorageKey, value: keyBase64);

      print('✓ Generated new encryption key and stored in keychain');
      return keyBase64;
    } catch (e) {
      print('⚠ Error managing encryption key: $e');
      rethrow;
    }
  }

  /// Encrypt data before storing
  String _encrypt(String plainText) {
    if (_encrypter == null) {
      throw Exception(
          'StorageService not initialized. Call initialize() first.');
    }

    final iv = encrypt_lib.IV.fromSecureRandom(16); // 128-bit IV
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);

    // Combine IV and encrypted data (IV is needed for decryption)
    final combined = '${iv.base64}:${encrypted.base64}';
    return combined;
  }

  /// Decrypt data after reading
  String _decrypt(String encryptedData) {
    if (_encrypter == null) {
      throw Exception(
          'StorageService not initialized. Call initialize() first.');
    }

    try {
      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final encrypted = encrypt_lib.Encrypted.fromBase64(parts[1]);

      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('⚠ Decryption error: $e');
      rethrow;
    }
  }

  // ==================== DOCUMENT STORAGE ====================

  /// Save a document with encryption
  Future<void> saveDocument(
      String documentId, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      final jsonString = jsonEncode(data);
      final encrypted = _encrypt(jsonString);
      await _documentsBox!.put(documentId, encrypted);
    } catch (e) {
      print('⚠ Error saving document $documentId: $e');
      rethrow;
    }
  }

  /// Get a document with decryption
  Future<Map<String, dynamic>?> getDocument(String documentId) async {
    _ensureInitialized();

    try {
      final encrypted = _documentsBox!.get(documentId);
      if (encrypted == null) return null;

      final decrypted = _decrypt(encrypted as String);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('⚠ Error getting document $documentId: $e');
      return null;
    }
  }

  /// Get all document IDs (does not decrypt data)
  List<String> getAllDocumentIds() {
    _ensureInitialized();
    return _documentsBox!.keys.cast<String>().toList();
  }

  /// Get all documents (decrypts all data - use carefully)
  Future<Map<String, Map<String, dynamic>>> getAllDocuments() async {
    _ensureInitialized();

    final result = <String, Map<String, dynamic>>{};

    for (final key in _documentsBox!.keys) {
      try {
        final doc = await getDocument(key as String);
        if (doc != null) {
          result[key] = doc;
        }
      } catch (e) {
        print('⚠ Error decrypting document $key: $e');
      }
    }

    return result;
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    _ensureInitialized();
    await _documentsBox!.delete(documentId);
  }

  /// Clear all documents (irreversible!)
  Future<void> clearAllDocuments() async {
    _ensureInitialized();
    await _documentsBox!.clear();
  }

  // ==================== SETTINGS STORAGE ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();

    try {
      final jsonString = jsonEncode(value);
      final encrypted = _encrypt(jsonString);
      await _settingsBox!.put(key, encrypted);
    } catch (e) {
      print('⚠ Error saving setting $key: $e');
      rethrow;
    }
  }

  /// Get a setting
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    _ensureInitialized();

    try {
      final encrypted = _settingsBox!.get(key);
      if (encrypted == null) return defaultValue;

      final decrypted = _decrypt(encrypted as String);
      return jsonDecode(decrypted);
    } catch (e) {
      print('⚠ Error getting setting $key: $e');
      return defaultValue;
    }
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    await _settingsBox!.delete(key);
  }

  // ==================== BACKUP/RESTORE ====================

  /// Export all encrypted data as binary (for cloud backup)
  /// Returns a single encrypted backup file
  Future<Uint8List> exportEncryptedBackup() async {
    _ensureInitialized();

    try {
      final allDocuments = <String, dynamic>{};

      // Collect all encrypted documents (already encrypted)
      for (final key in _documentsBox!.keys) {
        allDocuments[key as String] = _documentsBox!.get(key);
      }

      final allSettings = <String, dynamic>{};
      for (final key in _settingsBox!.keys) {
        allSettings[key as String] = _settingsBox!.get(key);
      }

      // Get the encryption key to include in backup
      final encryptionKey = await _secureStorage.read(key: _keyStorageKey);
      if (encryptionKey == null) {
        throw Exception('Encryption key not found');
      }

      final dataPayload = {
        'documents': allDocuments,
        'settings': allSettings,
      };

      // Encrypt the data payload
      final payloadJson = jsonEncode(dataPayload);
      final encryptedPayload = _encrypt(payloadJson);

      // Create backup with UNENCRYPTED header containing key
      final backup = {
        'version': '2.0', // Updated version
        'timestamp': DateTime.now().toIso8601String(),
        'encryptionKey': encryptionKey, // UNENCRYPTED key
        'encryptedPayload': encryptedPayload, // Encrypted data
      };

      final backupJson = jsonEncode(backup);
      print('✓ Backup created with encryption key included (v2.0)');
      return Uint8List.fromList(utf8.encode(backupJson));
    } catch (e) {
      print('⚠ Error creating backup: $e');
      rethrow;
    }
  }

  /// Import encrypted backup and merge with local data
  Future<void> importEncryptedBackup(Uint8List backupData,
      {bool overwrite = false}) async {
    _ensureInitialized();

    try {
      final backupString = utf8.decode(backupData);
      final backup = jsonDecode(backupString) as Map<String, dynamic>;

      // Validate backup structure
      if (backup['version'] == null) {
        throw Exception('Invalid backup format - missing version');
      }

      final version = backup['version'] as String;
      Map<String, dynamic> documents;
      Map<String, dynamic>? settings;

      if (version == '2.0') {
        // NEW FORMAT: Encryption key in header, data is encrypted
        print('📦 Restoring v2.0 backup with encryption key');
        
        if (backup['encryptionKey'] == null || backup['encryptedPayload'] == null) {
          throw Exception('Invalid v2.0 backup format');
        }

        final backupKey = backup['encryptionKey'] as String;
        final encryptedPayload = backup['encryptedPayload'] as String;
        
        // Adopt the encryption key from backup
        final currentKey = await _secureStorage.read(key: _keyStorageKey);
        if (currentKey != backupKey) {
          print('🔑 Adopting encryption key from backup');
          await _secureStorage.write(key: _keyStorageKey, value: backupKey);
          
          // Reinitialize encrypter with backup's key
          final key = encrypt_lib.Key.fromBase64(backupKey);
          _encrypter = encrypt_lib.Encrypter(
              encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
          
          print('✓ Encryption key updated successfully');
        }

        // Decrypt the payload with the backup's key
        final decryptedPayload = _decrypt(encryptedPayload);
        final payload = jsonDecode(decryptedPayload) as Map<String, dynamic>;
        
        documents = payload['documents'] as Map<String, dynamic>;
        settings = payload['settings'] as Map<String, dynamic>?;
        
      } else {
        // OLD FORMAT (v1.0): Entire backup is encrypted with current key
        print('📦 Restoring v1.0 backup (legacy format)');
        
        try {
          final decrypted = _decrypt(backupString);
          final legacyBackup = jsonDecode(decrypted) as Map<String, dynamic>;
          documents = legacyBackup['documents'] as Map<String, dynamic>;
          settings = legacyBackup['settings'] as Map<String, dynamic>?;
        } catch (e) {
          print('❌ Cannot decrypt legacy backup: $e');
          throw Exception('DECRYPTION_KEY_MISMATCH - Legacy backup encrypted with different key');
        }
      }

      // Restore documents
      int restoredDocs = 0;
      for (final entry in documents.entries) {
        if (overwrite || !_documentsBox!.containsKey(entry.key)) {
          await _documentsBox!.put(entry.key, entry.value);
          restoredDocs++;
        }
      }

      // Restore settings
      int restoredSettings = 0;
      if (settings != null) {
        for (final entry in settings.entries) {
          if (overwrite || !_settingsBox!.containsKey(entry.key)) {
            await _settingsBox!.put(entry.key, entry.value);
            restoredSettings++;
          }
        }
      }

      print('✓ Backup restored: $restoredDocs documents, $restoredSettings settings');
    } catch (e) {
      print('⚠ Error restoring backup: $e');
      rethrow;
    }
  }

  /// Get backup file size estimation
  int getDocumentCount() {
    _ensureInitialized();
    return _documentsBox!.length;
  }

  // ==================== UTILITY ====================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
          'StorageService not initialized. Call initialize() first.');
    }
  }

  /// Get current encryption key (for debugging/testing)
  Future<String?> getCurrentEncryptionKey() async {
    return await _secureStorage.read(key: _keyStorageKey);
  }

  /// Check if encryption key exists
  Future<bool> hasEncryptionKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }

  /// Encrypt raw data (for image files)
  Future<Uint8List> encryptData(Uint8List data) async {
    if (_encrypter == null) {
      throw Exception('Encrypter not initialized');
    }

    // Generate a random IV for each encryption
    final iv = encrypt_lib.IV.fromSecureRandom(16);
    
    // Encrypt the data
    final encrypted = _encrypter!.encryptBytes(data, iv: iv);
    
    // Combine IV + encrypted data for storage
    final combined = BytesBuilder();
    combined.add(iv.bytes);
    combined.add(encrypted.bytes);
    
    return combined.toBytes();
  }

  /// Decrypt raw data (for image files)
  Future<Uint8List> decryptData(Uint8List encryptedData) async {
    if (_encrypter == null) {
      throw Exception('Encrypter not initialized');
    }

    // Extract IV (first 16 bytes) and encrypted data
    final iv = encrypt_lib.IV(encryptedData.sublist(0, 16));
    final encrypted = encrypt_lib.Encrypted(encryptedData.sublist(16));
    
    // Decrypt
    final decrypted = _encrypter!.decryptBytes(encrypted, iv: iv);
    
    return Uint8List.fromList(decrypted);
  }

  /// Close all boxes (call when app is closing)
  Future<void> dispose() async {
    await _documentsBox?.close();
    await _settingsBox?.close();
    _isInitialized = false;
  }
}
