import 'package:flutter/material.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/main.dart' as main_app;

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  StorageService get _storageService => main_app.storageService;

  String _selectedTheme = 'dark';
  String _selectedAccentColor = 'blue';
  bool _compactView = false;
  bool _showThumbnails = true;

  final Map<String, Color> _accentColors = {
    'blue': const Color(0xFF5E81F3),
    'purple': const Color(0xFF8B5CF6),
    'green': const Color(0xFF10B981),
    'orange': const Color(0xFFF97316),
    'pink': const Color(0xFFEC4899),
    'teal': const Color(0xFF14B8A6),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load saved preferences - you can expand this to save/load from storage
    setState(() {
      // For now, using defaults
      _selectedTheme = 'dark';
      _selectedAccentColor = 'blue';
      _compactView = false;
      _showThumbnails = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appearance',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selection
            Container(
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
                      const Icon(Icons.palette,
                          color: Color(0xFF5E81F3), size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildThemeOption(
                    'Dark',
                    'dark',
                    Icons.dark_mode,
                    'Easy on the eyes in low light',
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.5,
                    child: _buildThemeOption(
                      'Light',
                      'light',
                      Icons.light_mode,
                      'Bright and clear (Coming Soon)',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.5,
                    child: _buildThemeOption(
                      'Auto',
                      'auto',
                      Icons.brightness_auto,
                      'Follows system settings (Coming Soon)',
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Accent Color
            Container(
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
                      const Icon(Icons.color_lens,
                          color: Color(0xFF5E81F3), size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Accent Color',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _accentColors.entries.map((entry) {
                      return _buildColorOption(entry.key, entry.value);
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Note: Accent color customization will be fully implemented in the next update',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Display Options
            Container(
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
                      const Icon(Icons.display_settings,
                          color: Color(0xFF5E81F3), size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Display Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Compact View
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Compact View',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Show more items on screen',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: 0.5,
                        child: Switch(
                          value: _compactView,
                          onChanged: null, // Disabled for now
                          activeColor: const Color(0xFF5E81F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Show Thumbnails
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Show Thumbnails',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Display document preview images',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: 0.5,
                        child: Switch(
                          value: _showThumbnails,
                          onChanged: null, // Disabled for now
                          activeColor: const Color(0xFF5E81F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Display customization features coming soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview
            Container(
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
                      const Icon(Icons.preview,
                          color: Color(0xFF5E81F3), size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accentColors[_selectedAccentColor]!
                            .withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _accentColors[_selectedAccentColor],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Sample Document',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is how your accent color will look throughout the app',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildThemeOption(
      String title, String value, IconData icon, String description,
      {bool enabled = true}) {
    final isSelected = _selectedTheme == value;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() => _selectedTheme = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Theme changed to $title'),
                  backgroundColor: const Color(0xFF5E81F3),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5E81F3).withOpacity(0.2)
              : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5E81F3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF5E81F3)
                  : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFF5E81F3) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF5E81F3)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String name, Color color) {
    final isSelected = _selectedAccentColor == name;

    return InkWell(
      onTap: () {
        setState(() => _selectedAccentColor = name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accent color: ${name.toUpperCase()}'),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
