import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  // Keys for SharedPreferences
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _authTypeKey =
      'auth_type'; // 'google', 'github', 'anonymous'

  /// Sign in with email and password
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting email sign-in for: $email');
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
                'Sign-in timed out. Please check your internet connection.'),
          );

      print('✓ Email sign-in successful');
      await _saveUserSession('email');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Email sign-in error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception(
              'No account found with this email. Please register first.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      print('❌ Email sign-in unexpected error: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Register with email and password
  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 Attempting registration for: $email');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
                'Registration timed out. Please check your internet connection.'),
          );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      print('✓ Registration successful');
      await _saveUserSession('email');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Registration error: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
              'This email is already registered. Please login instead.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'operation-not-allowed':
          throw Exception('Email/password registration is not enabled.');
        default:
          throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      print('❌ Registration unexpected error: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  /// Sign in with Google using existing GoogleSignIn instance
  /// Pass the GoogleSignInAccount from CloudSyncService to avoid double login
  Future<User?> signInWithGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      print('🔵 Getting Google auth credentials...');
      // Obtain auth details from the already signed-in account
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔵 Creating Firebase credential...');
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔵 Signing in to Firebase with credential...');
      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print('✓ Firebase sign-in successful: ${userCredential.user?.email}');

      // Save session
      await _saveUserSession('google');

      return userCredential.user;
    } catch (e) {
      print('❌ Firebase Google auth error: $e');
      rethrow;
    }
  }

  /// Sign in with Google and create/login Firebase user
  Future<User?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In...');

      // First check if already authenticated with Firebase via Google
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('✓ Already signed in to Firebase: ${currentUser.email}');
        // Already signed in, just save session and return
        await _saveUserSession('google');
        return currentUser;
      }

      print('🔵 No existing Firebase session, signing in with Google...');

      // Sign out first to clear any stale sessions
      await _googleSignIn.signOut();
      print('🔵 Cleared old Google session');

      // Show the sign-in UI with timeout
      print('🔵 Showing Google Sign-In dialog...');
      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('⏱️ Google Sign-In timed out after 20 seconds');
          throw Exception('Sign-in timed out. Please try again.');
        },
      );

      if (googleUser == null) {
        print('⚠️ User cancelled Google Sign-In');
        return null; // User cancelled
      }

      print('✓ Google Sign-In successful: ${googleUser.email}');
      print('🔵 Authenticating with Firebase...');

      final result = await signInWithGoogleAccount(googleUser);
      print('✓ Firebase authentication complete: ${result?.email}');

      return result;
    } catch (e) {
      print('❌ Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign in with GitHub OAuth
  Future<User?> signInWithGitHub() async {
    try {
      // Create GitHub provider
      final GithubAuthProvider githubProvider = GithubAuthProvider();

      // Sign in with GitHub
      final UserCredential userCredential =
          await _auth.signInWithProvider(githubProvider);

      // Save session
      await _saveUserSession('github');

      return userCredential.user;
    } catch (e) {
      throw Exception('GitHub sign-in failed: $e');
    }
  }

  /// Sign in anonymously (for local-only users)
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      await _saveUserSession('anonymous');
      return userCredential.user;
    } catch (e) {
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveUserSession(String authType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_authTypeKey, authType);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get authentication type
  Future<String?> getAuthType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTypeKey);
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_authTypeKey);
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        await logout();
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}
