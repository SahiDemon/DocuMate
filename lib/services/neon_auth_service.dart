import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NeonAuthService {
  // Your Neon database connection string
  static const String connectionString =
      'postgresql://neondb_owner:npg_G4x5UWmNhwlt@ep-blue-paper-a1sgmw33-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require';

  // Using Neon's HTTP API endpoint
  static const String neonApiUrl =
      'https://ep-blue-paper-a1sgmw33-pooler.ap-southeast-1.aws.neon.tech/sql';

  // Keys for SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Execute SQL query via Neon's HTTP endpoint
  Future<Map<String, dynamic>> _executeSql(String sql) async {
    try {
      final response = await http.post(
        Uri.parse(neonApiUrl),
        headers: {
          'Content-Type': 'application/sql',
          'Neon-Connection-String': connectionString,
        },
        body: sql,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Database query failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Database connection failed: $e');
    }
  }

  /// Initialize database tables
  Future<void> initializeDatabase() async {
    // Skip initialization - Neon HTTP API has issues with CREATE TABLE
    // Table will be created manually in Neon console if needed
    print(
        'Skipping database initialization - use Neon console to create tables');
    return;
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      final passwordHash = _hashPassword(password);

      // Build a simple, single-line INSERT query
      final insertUser =
          "INSERT INTO users (email, name, password_hash) VALUES ('${email.replaceAll("'", "''")}', '${name.replaceAll("'", "''")}', '$passwordHash') RETURNING id, email, name";

      final result = await _executeSql(insertUser);

      if (result['rows'] != null && result['rows'].isNotEmpty) {
        final user = result['rows'][0];
        await _saveUserSession(
          userId: user['id'].toString(),
          email: user['email'],
          name: user['name'],
        );
        return true;
      }
      return false;
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('Email already exists');
      }
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final passwordHash = _hashPassword(password);

      // Build a simple, single-line SELECT query
      final query =
          "SELECT id, email, name FROM users WHERE email = '${email.replaceAll("'", "''")}' AND password_hash = '$passwordHash'";

      final result = await _executeSql(query);

      if (result['rows'] != null && result['rows'].isNotEmpty) {
        final user = result['rows'][0];
        await _saveUserSession(
          userId: user['id'].toString(),
          email: user['email'],
          name: user['name'],
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveUserSession({
    required String userId,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get current user data
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) return null;

    return {
      'userId': prefs.getString(_userIdKey) ?? '',
      'email': prefs.getString(_userEmailKey) ?? '',
      'name': prefs.getString(_userNameKey) ?? '',
    };
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    try {
      // Check if user exists
      final query =
          "SELECT id FROM users WHERE email = '${email.replaceAll("'", "''")}'";
      final result = await _executeSql(query);

      if (result['rows'] != null && result['rows'].isNotEmpty) {
        // TODO: Implement actual email sending
        // For now, just return success
        return true;
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user password
  Future<bool> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final passwordHash = _hashPassword(newPassword);

      final query =
          "UPDATE users SET password_hash = '$passwordHash', updated_at = CURRENT_TIMESTAMP WHERE email = '${email.replaceAll("'", "''")}' RETURNING id";

      final result = await _executeSql(query);
      return result['rows'] != null && result['rows'].isNotEmpty;
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }
}
