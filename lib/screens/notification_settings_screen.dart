import 'package:flutter/material.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/screens/notifications_center_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
  List<int> _defaultReminderIntervals = [30, 7, 1];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadSettings();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    setState(() => _hasPermission = status.isGranted);
    
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission granted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Notification Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Please enable notifications in system settings to receive document reminders.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81F3),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
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

      // Load default reminder intervals (single list for all documents)
      final intervals = await widget.storageService.getSetting(
        'default_reminder_intervals',
      );
      if (intervals is List) {
        _defaultReminderIntervals = intervals.cast<int>();
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    if (value && !_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) {
        return; // Don't enable if permission not granted
      }
    }

    await widget.storageService.saveSetting('notifications_enabled', value);

    if (!value) {
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

  Future<void> _saveReminderIntervals(List<int> intervals) async {
    await widget.storageService.saveSetting('default_reminder_intervals', intervals);
    setState(() => _defaultReminderIntervals = intervals);
  }

  Future<void> _selectNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5E81F3),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      await _saveNotificationTime(time);
    }
  }

  Future<void> _editReminderIntervals() async {
    final intervals = List<int>.from(_defaultReminderIntervals);
    
    await showDialog(
      context: context,
      builder: (context) => _ReminderIntervalsDialog(
        intervals: intervals,
        onSave: (newIntervals) async {
          await _saveReminderIntervals(newIntervals);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Color(0xFF5E81F3)),
            tooltip: 'View Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotificationsCenterScreen(
                    storageService: widget.storageService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permission status banner
          if (!_hasPermission)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text(
                        'Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notification permission is required to receive document reminders.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Grant Permission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),

          // Enable Notifications Card
          _buildCard(
            icon: Icons.notifications_active,
            iconColor: const Color(0xFF5E81F3),
            title: 'Enable Notifications',
            subtitle: 'Receive reminders for document expiry and due dates',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotificationsEnabled,
              activeColor: const Color(0xFF5E81F3),
            ),
          ),

          const SizedBox(height: 12),

          // Sound Card
          _buildCard(
            icon: Icons.volume_up,
            iconColor: const Color(0xFF10B981),
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: _notificationsEnabled ? _saveSoundEnabled : null,
              activeColor: const Color(0xFF10B981),
            ),
            enabled: _notificationsEnabled,
          ),

          const SizedBox(height: 12),

          // Vibration Card
          _buildCard(
            icon: Icons.vibration,
            iconColor: const Color(0xFFF97316),
            title: 'Vibration',
            subtitle: 'Vibrate when notification arrives',
            trailing: Switch(
              value: _vibrationEnabled,
              onChanged: _notificationsEnabled ? _saveVibrationEnabled : null,
              activeColor: const Color(0xFFF97316),
            ),
            enabled: _notificationsEnabled,
          ),

          const SizedBox(height: 24),

          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'SCHEDULE',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Notification Time Card
          _buildCard(
            icon: Icons.access_time,
            iconColor: const Color(0xFFFBBF24),
            title: 'Notification Time',
            subtitle: 'When to receive daily reminders',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _notificationTime.format(context),
                  style: TextStyle(
                    color: _notificationsEnabled ? const Color(0xFF5E81F3) : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: _notificationsEnabled ? Colors.white.withOpacity(0.5) : Colors.grey,
                ),
              ],
            ),
            onTap: _notificationsEnabled ? _selectNotificationTime : null,
            enabled: _notificationsEnabled,
          ),

          const SizedBox(height: 12),

          // Reminder Intervals Card
          _buildCard(
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFEC4899),
            title: 'Default Reminder Intervals',
            subtitle: 'When to remind before expiry: ${_defaultReminderIntervals.map((d) => '${d}d').join(', ')}',
            trailing: Icon(
              Icons.edit,
              color: _notificationsEnabled ? const Color(0xFF5E81F3) : Colors.grey,
            ),
            onTap: _notificationsEnabled ? _editReminderIntervals : null,
            enabled: _notificationsEnabled,
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5E81F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5E81F3).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF5E81F3),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'These intervals apply to all documents by default. You can customize reminders for individual documents when adding or editing them.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: enabled ? iconColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ReminderIntervalsDialog extends StatefulWidget {
  final List<int> intervals;
  final Function(List<int>) onSave;

  const _ReminderIntervalsDialog({
    required this.intervals,
    required this.onSave,
  });

  @override
  State<_ReminderIntervalsDialog> createState() => _ReminderIntervalsDialogState();
}

class _ReminderIntervalsDialogState extends State<_ReminderIntervalsDialog> {
  late List<int> _intervals;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _intervals = List<int>.from(widget.intervals);
    _intervals.sort((a, b) => b.compareTo(a)); // Sort descending
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addInterval() {
    final value = int.tryParse(_controller.text);
    if (value != null && value > 0 && value <= 365) {
      if (!_intervals.contains(value)) {
        setState(() {
          _intervals.add(value);
          _intervals.sort((a, b) => b.compareTo(a));
          _controller.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This interval already exists'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number between 1 and 365'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeInterval(int value) {
    setState(() {
      _intervals.remove(value);
    });
  }

  void _save() {
    if (_intervals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reminder interval'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    widget.onSave(_intervals);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder Intervals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set how many days before expiry/due date to receive reminders',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Add Interval Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Days before',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixText: 'days',
                      suffixStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addInterval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Intervals
            if (_intervals.isNotEmpty) ...[
              Text(
                'Current Intervals',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _intervals.map((interval) {
                  return Chip(
                    label: Text(
                      '$interval days',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF1E1E1E),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                    onDeleted: () => _removeInterval(interval),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
