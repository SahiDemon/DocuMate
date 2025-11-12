import 'package:flutter/material.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const NotificationSettingsScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  // Default reminder intervals for each category
  final Map<String, List<int>> _reminderIntervals = {
    'Identity': [30, 7, 1],
    'Insurance': [30, 7, 1],
    'Bills': [7, 3, 1],
    'Medical': [14, 7, 1],
    'Legal': [30, 14, 7],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load notification enabled state
      _notificationsEnabled = await widget.storageService.getSetting(
        'notifications_enabled',
        defaultValue: true,
      ) as bool;

      _soundEnabled = await widget.storageService.getSetting(
        'notification_sound',
        defaultValue: true,
      ) as bool;

      _vibrationEnabled = await widget.storageService.getSetting(
        'notification_vibration',
        defaultValue: true,
      ) as bool;

      final hour = await widget.storageService.getSetting(
        'notification_hour',
        defaultValue: 9,
      ) as int;

      final minute = await widget.storageService.getSetting(
        'notification_minute',
        defaultValue: 0,
      ) as int;

      _notificationTime = TimeOfDay(hour: hour, minute: minute);

      // Load reminder intervals for each category
      for (final category in _reminderIntervals.keys) {
        final intervals = await widget.storageService.getSetting(
          'reminder_intervals_$category',
        );
        if (intervals is List) {
          _reminderIntervals[category] = intervals.cast<int>();
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    await widget.storageService.saveSetting('notifications_enabled', value);

    if (!value) {
      // Cancel all notifications when disabled
      await _notificationService.cancelAllNotifications();
    }

    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveSoundEnabled(bool value) async {
    await widget.storageService.saveSetting('notification_sound', value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _saveVibrationEnabled(bool value) async {
    await widget.storageService.saveSetting('notification_vibration', value);
    setState(() => _vibrationEnabled = value);
  }

  Future<void> _saveNotificationTime(TimeOfDay time) async {
    await widget.storageService.saveSetting('notification_hour', time.hour);
    await widget.storageService.saveSetting('notification_minute', time.minute);
    setState(() => _notificationTime = time);
  }

  Future<void> _selectNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (time != null) {
      await _saveNotificationTime(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: DocuMateTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'General',
            [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive reminders for document expiry and due dates',
                _notificationsEnabled,
                _saveNotificationsEnabled,
                icon: Icons.notifications_active,
              ),
              _buildSwitchTile(
                'Sound',
                'Play sound for notifications',
                _soundEnabled,
                _saveSoundEnabled,
                enabled: _notificationsEnabled,
                icon: Icons.volume_up,
              ),
              _buildSwitchTile(
                'Vibration',
                'Vibrate when notification arrives',
                _vibrationEnabled,
                _saveVibrationEnabled,
                enabled: _notificationsEnabled,
                icon: Icons.vibration,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Notification Time',
            [
              _buildTimeTile(
                'Preferred Time',
                'When to receive daily reminders',
                _notificationTime,
                _selectNotificationTime,
                enabled: _notificationsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Reminder Intervals',
            [
              _buildIntervalTile('Identity Documents', 'Identity'),
              _buildIntervalTile('Insurance Policies', 'Insurance'),
              _buildIntervalTile('Bills & Payments', 'Bills'),
              _buildIntervalTile('Medical Records', 'Medical'),
              _buildIntervalTile('Legal Documents', 'Legal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onChanged, {
    bool enabled = true,
    IconData? icon,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: enabled ? Colors.blue : Colors.grey)
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    String subtitle,
    TimeOfDay time,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        Icons.access_time,
        color: enabled ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        time.format(context),
        style: TextStyle(
          color: enabled ? Colors.blue : Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildIntervalTile(String title, String category) {
    final intervals = _reminderIntervals[category] ?? [];
    final intervalsText = intervals.map((d) => '${d}d').join(', ');

    return ListTile(
      leading: Icon(Icons.calendar_today, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Remind $intervalsText before expiry/due date',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      enabled: _notificationsEnabled,
      onTap: () => _editIntervals(category),
    );
  }

  Future<void> _editIntervals(String category) async {
    // TODO: Show dialog to edit intervals
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit intervals for $category (Coming soon)')),
    );
  }
}
