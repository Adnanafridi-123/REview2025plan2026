import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedule a daily reminder at specific time
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily goal and habit reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: payload,
    );
  }

  /// Schedule a ONE-TIME reminder at specific date and time
  Future<void> scheduleOneTimeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TimeOfDay time,
    String? payload,
  }) async {
    final scheduledDateTime = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      time.hour,
      time.minute,
    );

    // Don't schedule if time has already passed
    if (scheduledDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Cannot schedule reminder in the past');
      return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'one_time_reminders',
          'One-Time Reminders',
          channelDescription: 'One-time scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00BCD4),
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true, // Show even when screen is off
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents means it fires only once
      payload: payload,
    );
  }

  /// Schedule a weekly reminder (e.g., Sunday at 10 AM)
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday, 7 = Sunday
    required TimeOfDay time,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(weekday, time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reminders',
          'Weekly Reminders',
          channelDescription: 'Weekly review reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFEC407A),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
      payload: payload,
    );
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification (for testing)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Instant notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Get next instance of a specific time today or tomorrow
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next instance of a specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    var scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

/// Reminder IDs for consistent management
class ReminderIds {
  static const int morningReminder = 1001;
  static const int exerciseReminder = 1002;
  static const int studyReminder = 1003;
  static const int nightReview = 1004;
  static const int weeklyCheckIn = 1005;
  static const int customReminderBase = 2000; // Custom reminders start from 2000
}
