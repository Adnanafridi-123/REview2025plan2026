import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Category colors for goals
  static const Map<String, int> goalCategoryColors = {
    'Career': 0xFF4ECDC4,
    'Health': 0xFFFF6B6B,
    'Finance': 0xFFFFE66D,
    'Personal': 0xFF9B59B6,
    'Learning': 0xFF3498DB,
    'Education': 0xFF3498DB,
    'Custom': 0xFF667eea,
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    
    // Request permissions on initialization
    await requestPermissions();
    
    // Create notification channels
    await _createNotificationChannels();
  }
  
  Future<void> _createNotificationChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // Habit reminder channel with sound
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Daily reminders for your habits',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4ECDC4),
        ),
      );
      
      // Goal reminder channel with sound
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'goal_reminders',
          'Goal Reminders',
          description: 'Daily reminders for your goals',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF667eea),
        ),
      );
      
      // Deadline reminder channel with sound
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'deadline_reminders',
          'Deadline Reminders',
          description: 'Reminders for upcoming deadlines',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF6B6B),
        ),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to habit screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // Request notification permission (Android 13+)
      final notifGranted = await android.requestNotificationsPermission();
      
      // Request exact alarm permission (Android 12+)
      await android.requestExactAlarmsPermission();
      
      debugPrint('Notification permission: $notifGranted');
      return notifGranted ?? false;
    }
    
    return true;
  }

  // Schedule daily habit reminder
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String category,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final categoryIcon = HabitCategory.categoryIcons[category] ?? '🎯';

    await _notifications.zonedSchedule(
      habitId.hashCode,
      '$categoryIcon Habit Reminder',
      'Time to complete: $habitName',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(HabitCategory.categoryColors[category] ?? 0xFF2196F3),
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
      payload: habitId,
    );
  }

  // Cancel habit reminder
  Future<void> cancelHabitReminder(String habitId) async {
    await _notifications.cancel(habitId.hashCode);
  }
  
  // Schedule daily goal reminder with sound
  Future<void> scheduleGoalReminder({
    required String goalId,
    required String goalName,
    required String category,
    required TimeOfDay time,
    DateTime? deadline,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final categoryEmoji = _getCategoryEmoji(category);

    await _notifications.zonedSchedule(
      goalId.hashCode,
      '$categoryEmoji Goal Reminder',
      'Time to work on: $goalName',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Daily reminders for your goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(goalCategoryColors[category] ?? 0xFF667eea),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(goalCategoryColors[category] ?? 0xFF667eea),
          styleInformation: BigTextStyleInformation(
            'Time to work on: $goalName${deadline != null ? '\n📅 Deadline: ${deadline.day}/${deadline.month}/${deadline.year}' : ''}',
            htmlFormatBigText: false,
            contentTitle: '$categoryEmoji Goal Reminder',
            htmlFormatContentTitle: false,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'goal_$goalId',
    );
  }
  
  // Schedule deadline reminder (one-time)
  Future<void> scheduleDeadlineReminder({
    required String goalId,
    required String goalName,
    required String category,
    required DateTime deadline,
    required TimeOfDay time,
  }) async {
    final scheduledDate = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
      time.hour,
      time.minute,
    );
    
    // Only schedule if deadline is in the future
    if (scheduledDate.isBefore(DateTime.now())) return;

    final categoryEmoji = _getCategoryEmoji(category);

    await _notifications.zonedSchedule(
      'deadline_$goalId'.hashCode,
      '⏰ Deadline Alert!',
      '$categoryEmoji $goalName deadline is today!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_reminders',
          'Deadline Reminders',
          channelDescription: 'Reminders for upcoming deadlines',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF6B6B),
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color(0xFFFF6B6B),
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'deadline_$goalId',
    );
  }
  
  // Cancel goal reminder
  Future<void> cancelGoalReminder(String goalId) async {
    await _notifications.cancel(goalId.hashCode);
    await _notifications.cancel('deadline_$goalId'.hashCode);
  }
  
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Career': return '💼';
      case 'Health': return '💪';
      case 'Finance': return '💰';
      case 'Personal': return '🎯';
      case 'Learning': return '📚';
      case 'Education': return '📚';
      default: return '✨';
    }
  }

  // Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // Show instant notification (for testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Instant notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
  
  // Test notification with sound
  Future<void> testNotificationWithSound() async {
    await _notifications.show(
      999,
      '🔔 Test Notification',
      'This is a test notification with sound!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Daily reminders for your goals',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  // Parse time string (HH:mm) to TimeOfDay
  static TimeOfDay? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  // Format TimeOfDay to string (HH:mm)
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
