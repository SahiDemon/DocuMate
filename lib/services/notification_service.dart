import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';

/// Notification service for scheduling document reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StorageService? _storageService;

  /// Initialize notification service
  Future<void> initialize({StorageService? storageService}) async {
    if (_initialized) return;
    
    // Set storage service if provided
    _storageService ??= storageService;

    // Initialize timezones
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('✓ NotificationService initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Extract document ID from payload
    final documentId = response.payload;
    if (documentId != null) {
      // TODO: Navigate to document details screen
      print('📱 Notification tapped for document: $documentId');
    }
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }

  /// Schedule reminders for a document
  Future<List<int>> scheduleDocumentReminders({
    required DocumentModel document,
    List<int>? customIntervals,
  }) async {
    if (!_initialized) await initialize();

    // Determine which date to use (expiry or due date)
    final targetDate = document.expiryDate ?? document.dueDate;
    if (targetDate == null) {
      print('⚠️ No expiry/due date found for document: ${document.name}');
      return [];
    }

    // Get reminder intervals from settings or use custom/default
    final intervals =
        customIntervals ?? await _getReminderIntervals(document.category);

    // Get notification time from settings (default 9 AM)
    final notificationTime = await _getNotificationTime();

    final scheduledIds = <int>[];

    for (final daysBefore in intervals) {
      final reminderDate = targetDate.subtract(Duration(days: daysBefore));

      // Combine date with notification time
      final scheduledDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        notificationTime.hour,
        notificationTime.minute,
      );

      // Only schedule if in future
      if (scheduledDateTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(document.id, daysBefore);

        await _scheduleNotification(
          id: notificationId,
          title: _getNotificationTitle(document, daysBefore),
          body: _getNotificationBody(document, daysBefore, targetDate),
          scheduledDate: scheduledDateTime,
          payload: document.id,
        );

        scheduledIds.add(notificationId);
        print(
            '🔔 Scheduled notification $notificationId for ${document.name} on $scheduledDateTime');
      }
    }

    return scheduledIds;
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'documate_reminders',
      'Document Reminders',
      channelDescription: 'Reminders for document expiry and due dates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel reminders for a document
  Future<void> cancelDocumentReminders(DocumentModel document) async {
    // Get notification IDs from metadata
    final notificationIds =
        document.metadata?['notificationIds'] as List<dynamic>?;

    if (notificationIds != null) {
      for (final id in notificationIds) {
        await _notifications.cancel(id as int);
        print('🔕 Cancelled notification $id for ${document.name}');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🔕 Cancelled all notifications');
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'documate_reminders',
      'Document Reminders',
      channelDescription: 'Reminders for document expiry and due dates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Generate unique notification ID
  int _generateNotificationId(String documentId, int daysBefore) {
    // Combine document ID hash with days before to create unique ID
    final hash = documentId.hashCode.abs() % 100000;
    return (hash * 100) + daysBefore;
  }

  /// Get notification title based on document and days before
  String _getNotificationTitle(DocumentModel document, int daysBefore) {
    if (daysBefore == 0) {
      return document.expiryDate != null
          ? '⏰ Document Expires Today!'
          : '💳 Payment Due Today!';
    } else if (daysBefore == 1) {
      return document.expiryDate != null
          ? '⏰ Document Expires Tomorrow'
          : '💳 Payment Due Tomorrow';
    } else {
      return document.expiryDate != null
          ? '⏰ Document Expiring Soon'
          : '💳 Payment Due Soon';
    }
  }

  /// Get notification body
  String _getNotificationBody(
      DocumentModel document, int daysBefore, DateTime targetDate) {
    final dateStr = _formatDate(targetDate);

    if (daysBefore == 0) {
      return document.expiryDate != null
          ? '${document.name} expires today ($dateStr)'
          : '${document.name} payment is due today ($dateStr)';
    } else if (daysBefore == 1) {
      return document.expiryDate != null
          ? '${document.name} expires tomorrow ($dateStr)'
          : '${document.name} payment is due tomorrow ($dateStr)';
    } else {
      return document.expiryDate != null
          ? '${document.name} expires in $daysBefore days ($dateStr)'
          : '${document.name} payment is due in $daysBefore days ($dateStr)';
    }
  }

  /// Format date for notification
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get reminder intervals from settings
  Future<List<int>> _getReminderIntervals(String category) async {
    // Try to load from settings if storage service is available
    if (_storageService != null) {
      final settingsKey = 'reminder_intervals_$category';
      final intervals = await _storageService!.getSetting(settingsKey);

      if (intervals is List) {
        return intervals.cast<int>();
      }
    }

    // Return category defaults
    switch (category) {
      case 'Identity':
      case 'Insurance':
        return [30, 7, 1];
      case 'Bills':
        return [7, 3, 1];
      case 'Medical':
        return [14, 7, 1];
      case 'Legal':
        return [30, 14, 7];
      default:
        return [7, 3, 1];
    }
  }

  /// Get notification time from settings
  Future<TimeOfDay> _getNotificationTime() async {
    // Use default time if storage service not available
    if (_storageService == null) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final hour = await _storageService!.getSetting(
      'notification_hour',
      defaultValue: 9,
    ) as int;

    final minute = await _storageService!.getSetting(
      'notification_minute',
      defaultValue: 0,
    ) as int;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
