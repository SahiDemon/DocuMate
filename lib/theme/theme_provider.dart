import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider manages the app's theme state including:
/// - Theme mode (light, dark, auto)
/// - Accent color
/// - Display preferences (compact view, show thumbnails)
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _compactViewKey = 'compact_view';
  static const String _showThumbnailsKey = 'show_thumbnails';

  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFF5E81F3); // Default blue
  bool _compactView = false;
  bool _showThumbnails = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get compactView => _compactView;
  bool get showThumbnails => _showThumbnails;

  // Predefined accent colors for the grid
  final List<Color> presetColors = [
    const Color(0xFF5E81F3), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF10B981), // Green
    const Color(0xFFF97316), // Orange
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
  ];

  /// Load saved preferences from storage
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeString = prefs.getString(_themeModeKey) ?? 'dark';
    _themeMode = _parseThemeMode(themeModeString);

    // Load accent color
    final accentColorValue = prefs.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    } else {
      // Fallback for old string-based keys or fresh install
      final oldColorName =
          prefs.getString('accent_color_name'); // Check old key if exists
      if (oldColorName != null) {
        // Map old names to new colors if needed, or just default
        _accentColor = const Color(0xFF5E81F3);
      }
    }

    // Load display preferences
    _compactView = prefs.getBool(_compactViewKey) ?? false;
    _showThumbnails = prefs.getBool(_showThumbnailsKey) ?? true;

    notifyListeners();
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  /// Set accent color and persist to storage
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }

  /// Set compact view and persist to storage
  Future<void> setCompactView(bool value) async {
    _compactView = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactViewKey, value);
  }

  /// Set show thumbnails and persist to storage
  Future<void> setShowThumbnails(bool value) async {
    _showThumbnails = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showThumbnailsKey, value);
  }

  // Helper methods
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
