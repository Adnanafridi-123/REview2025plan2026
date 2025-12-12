import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Comprehensive Alarm Service for Plan 2026
/// Uses android_alarm_manager_plus for exact alarms that work even when app is closed
/// Combined with flutter_local_notifications for rich notifications
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Port for background communication
  static const String _isolateName = 'alarm_isolate';

  // Notification Channels
  static const String _goalChannel = 'goal_alarms';
  static const String _habitChannel = 'habit_alarms';
  static const String _healthChannel = 'health_alarms';
  static const String _financeChannel = 'finance_alarms';
  static const String _deadlineChannel = 'deadline_alarms';
  static const String _motivationChannel = 'motivation_alarms';

  /// Initialize the alarm service with android_alarm_manager_plus
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    // Initialize Android Alarm Manager for exact alarms
    await AndroidAlarmManager.initialize();

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

    await _createNotificationChannels();
    await requestPermissions();
    
    // Register port for isolate communication
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
    port.listen((_) async => await _showScheduledNotification(_));
    
    _isInitialized = true;
    debugPrint('✅ AlarmService initialized with AndroidAlarmManager');
  }
  
  /// Background callback for alarm manager - MUST be top-level or static
  @pragma('vm:entry-point')
  static Future<void> alarmCallback(int id) async {
    debugPrint('🔔 Alarm fired! ID: $id');
    
    // Send message to main isolate to show notification
    final send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(id);
  }
  
  /// Show notification when alarm fires
  Future<void> _showScheduledNotification(dynamic alarmId) async {
    debugPrint('📣 Showing notification for alarm: $alarmId');
    // This will be handled by the specific notification methods
  }

  Future<void> _createNotificationChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // Goal Reminders - High Priority
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _goalChannel,
          'Goal Reminders',
          description: 'Daily reminders for your 2026 goals',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF667eea),
        ),
      );

      // Habit Reminders - High Priority
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _habitChannel,
          'Habit Reminders',
          description: 'Daily habit completion reminders',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4ECDC4),
        ),
      );

      // Health Reminders - High Priority
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _healthChannel,
          'Health Reminders',
          description: 'Health tracking reminders (water, exercise, sleep)',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF11998e),
        ),
      );

      // Finance Reminders - Default Priority
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _financeChannel,
          'Finance Reminders',
          description: 'Budget and savings reminders',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF56ab2f),
        ),
      );

      // Deadline Alerts - MAX Priority
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _deadlineChannel,
          'Deadline Alerts',
          description: 'Urgent deadline reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF6B6B),
        ),
      );

      // Motivation Notifications
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _motivationChannel,
          'Daily Motivation',
          description: 'Daily motivational quotes and tips',
          importance: Importance.defaultImportance,
          playSound: true,
          enableLights: true,
          ledColor: Color(0xFFFFD700),
        ),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Navigation handling can be added here
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notifGranted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return notifGranted ?? false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOAL ALARMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule daily goal reminder
  Future<void> scheduleGoalReminder({
    required String goalId,
    required String goalName,
    required String category,
    required TimeOfDay time,
    DateTime? deadline,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final emoji = _getCategoryEmoji(category);

    await _notifications.zonedSchedule(
      goalId.hashCode,
      '$emoji Goal: $goalName',
      deadline != null 
          ? '📅 Deadline: ${_formatDate(deadline)} - Keep pushing!' 
          : 'Time to work on your goal! 💪',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _goalChannel,
          'Goal Reminders',
          channelDescription: 'Daily reminders for your goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF667eea),
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            deadline != null 
                ? '📅 Deadline: ${_formatDate(deadline)}\n\nKeep pushing toward your goal!' 
                : 'Time to work on your goal! Stay focused and make progress today! 💪',
            contentTitle: '$emoji Goal: $goalName',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'goal_$goalId',
    );

    debugPrint('✅ Goal reminder scheduled: $goalName at ${time.hour}:${time.minute}');
  }

  /// Schedule deadline alert (one-time, day before and on the day)
  Future<void> scheduleDeadlineAlert({
    required String goalId,
    required String goalName,
    required DateTime deadline,
  }) async {
    // Alert on deadline day at 9 AM
    final deadlineAlert = DateTime(deadline.year, deadline.month, deadline.day, 9, 0);
    
    if (deadlineAlert.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        'deadline_$goalId'.hashCode,
        '⚠️ DEADLINE TODAY!',
        '🎯 "$goalName" deadline is TODAY! Complete it now!',
        tz.TZDateTime.from(deadlineAlert, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineChannel,
            'Deadline Alerts',
            channelDescription: 'Urgent deadline reminders',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF6B6B),
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'deadline_$goalId',
      );
    }

    // Alert day before at 8 PM
    final dayBefore = deadline.subtract(const Duration(days: 1));
    final reminderAlert = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 20, 0);
    
    if (reminderAlert.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        'deadline_reminder_$goalId'.hashCode,
        '⏰ Deadline Tomorrow!',
        '🎯 "$goalName" deadline is TOMORROW! Finish up today!',
        tz.TZDateTime.from(reminderAlert, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineChannel,
            'Deadline Alerts',
            channelDescription: 'Urgent deadline reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF9800),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'deadline_reminder_$goalId',
      );
    }

    debugPrint('✅ Deadline alerts scheduled for: $goalName');
  }

  /// Cancel goal reminders
  Future<void> cancelGoalReminder(String goalId) async {
    await _notifications.cancel(goalId.hashCode);
    await _notifications.cancel('deadline_$goalId'.hashCode);
    await _notifications.cancel('deadline_reminder_$goalId'.hashCode);
    debugPrint('❌ Goal reminder cancelled: $goalId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HABIT ALARMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule daily habit reminder
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String category,
    required TimeOfDay time,
    int currentStreak = 0,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final emoji = _getHabitEmoji(category);
    final streakText = currentStreak > 0 ? '🔥 $currentStreak day streak!' : 'Start your streak today!';

    await _notifications.zonedSchedule(
      habitId.hashCode,
      '$emoji Habit Time: $habitName',
      streakText,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannel,
          'Habit Reminders',
          channelDescription: 'Daily habit completion reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4ECDC4),
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            '$streakText\n\nDon\'t break the chain! Complete your habit now.',
            contentTitle: '$emoji Habit Time: $habitName',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit_$habitId',
    );

    debugPrint('✅ Habit reminder scheduled: $habitName at ${time.hour}:${time.minute}');
  }

  /// Cancel habit reminder
  Future<void> cancelHabitReminder(String habitId) async {
    await _notifications.cancel(habitId.hashCode);
    debugPrint('❌ Habit reminder cancelled: $habitId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH ALARMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule water reminder (multiple times per day)
  Future<void> scheduleWaterReminders({required bool enabled}) async {
    // Cancel existing water reminders first
    for (int i = 0; i < 8; i++) {
      await _notifications.cancel('water_$i'.hashCode);
    }

    if (!enabled) return;

    // Schedule reminders every 2 hours from 8 AM to 10 PM
    final times = [8, 10, 12, 14, 16, 18, 20, 22];
    
    for (int i = 0; i < times.length; i++) {
      final hour = times[i];
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        'water_$i'.hashCode,
        '💧 Hydration Reminder',
        'Time to drink water! Stay hydrated for better health.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _healthChannel,
            'Health Reminders',
            channelDescription: 'Health tracking reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF00BCD4),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'water_reminder',
      );
    }

    debugPrint('✅ Water reminders scheduled (8 times/day)');
  }

  /// Schedule exercise reminder
  Future<void> scheduleExerciseReminder({
    required TimeOfDay time,
    required String exerciseType,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      'exercise_daily'.hashCode,
      '🏃 Exercise Time!',
      'Time for your $exerciseType session. Let\'s get moving!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _healthChannel,
          'Health Reminders',
          channelDescription: 'Exercise reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'exercise_reminder',
    );

    debugPrint('✅ Exercise reminder scheduled at ${time.hour}:${time.minute}');
  }

  /// Schedule sleep reminder
  Future<void> scheduleSleepReminder({required TimeOfDay bedtime}) async {
    final now = DateTime.now();
    // Remind 30 minutes before bedtime
    var scheduledDate = DateTime(
      now.year, now.month, now.day, 
      bedtime.hour, bedtime.minute,
    ).subtract(const Duration(minutes: 30));

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      'sleep_reminder'.hashCode,
      '😴 Bedtime Soon',
      'Start winding down. Bedtime in 30 minutes for better sleep!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _healthChannel,
          'Health Reminders',
          channelDescription: 'Sleep reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF673AB7),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'sleep_reminder',
    );

    debugPrint('✅ Sleep reminder scheduled 30 min before ${bedtime.hour}:${bedtime.minute}');
  }

  /// Cancel health reminders
  Future<void> cancelHealthReminders() async {
    for (int i = 0; i < 8; i++) {
      await _notifications.cancel('water_$i'.hashCode);
    }
    await _notifications.cancel('exercise_daily'.hashCode);
    await _notifications.cancel('sleep_reminder'.hashCode);
    debugPrint('❌ All health reminders cancelled');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FINANCE ALARMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule weekly budget review reminder
  Future<void> scheduleWeeklyBudgetReview({required int dayOfWeek, required TimeOfDay time}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Find next occurrence of the specified day
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      'budget_weekly'.hashCode,
      '💰 Weekly Budget Review',
      'Time to review your spending and savings progress!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _financeChannel,
          'Finance Reminders',
          channelDescription: 'Budget reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF56ab2f),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'budget_review',
    );

    debugPrint('✅ Weekly budget review scheduled');
  }

  /// Schedule monthly savings reminder
  Future<void> scheduleMonthlySavingsReminder({required int dayOfMonth, required TimeOfDay time}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, dayOfMonth, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = DateTime(now.year, now.month + 1, dayOfMonth, time.hour, time.minute);
    }

    await _notifications.zonedSchedule(
      'savings_monthly'.hashCode,
      '🏦 Monthly Savings Check',
      'Don\'t forget to save this month! Check your financial goals.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _financeChannel,
          'Finance Reminders',
          channelDescription: 'Savings reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFA726),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: 'savings_reminder',
    );

    debugPrint('✅ Monthly savings reminder scheduled on day $dayOfMonth');
  }

  /// Schedule financial goal deadline
  Future<void> scheduleFinancialGoalDeadline({
    required String goalId,
    required String goalName,
    required DateTime deadline,
    required double targetAmount,
    required double currentAmount,
  }) async {
    final progress = (currentAmount / targetAmount * 100).clamp(0, 100);
    final remaining = targetAmount - currentAmount;

    final deadlineAlert = DateTime(deadline.year, deadline.month, deadline.day, 10, 0);

    if (deadlineAlert.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        'finance_deadline_$goalId'.hashCode,
        '💰 Financial Goal Deadline!',
        '$goalName: ${progress.toStringAsFixed(0)}% complete. \$${remaining.toStringAsFixed(0)} remaining.',
        tz.TZDateTime.from(deadlineAlert, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _deadlineChannel,
            'Deadline Alerts',
            channelDescription: 'Financial deadline alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF56ab2f),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'finance_deadline_$goalId',
      );
    }

    debugPrint('✅ Financial goal deadline scheduled: $goalName');
  }

  /// Cancel finance reminders
  Future<void> cancelFinanceReminders() async {
    await _notifications.cancel('budget_weekly'.hashCode);
    await _notifications.cancel('savings_monthly'.hashCode);
    debugPrint('❌ Finance reminders cancelled');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOTIVATION ALARMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule daily motivation quote
  Future<void> scheduleDailyMotivation({required TimeOfDay time}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final quotes = [
      '"The only way to do great work is to love what you do." - Steve Jobs',
      '"Success is not final, failure is not fatal." - Winston Churchill',
      '"Believe you can and you\'re halfway there." - Theodore Roosevelt',
      '"The future belongs to those who believe in their dreams." - Eleanor Roosevelt',
      '"Your limitation—it\'s only your imagination."',
      '"Push yourself, because no one else is going to do it for you."',
      '"Great things never come from comfort zones."',
      '"Dream it. Wish it. Do it."',
      '"Success doesn\'t just find you. You have to go out and get it."',
      '"The harder you work, the luckier you get."',
    ];

    final randomQuote = quotes[DateTime.now().day % quotes.length];

    await _notifications.zonedSchedule(
      'daily_motivation'.hashCode,
      '✨ Daily Motivation',
      randomQuote,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _motivationChannel,
          'Daily Motivation',
          channelDescription: 'Daily motivational quotes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFD700),
          playSound: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'motivation',
    );

    debugPrint('✅ Daily motivation scheduled at ${time.hour}:${time.minute}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show instant notification
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
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
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('❌ All notifications cancelled');
  }

  /// Get pending notifications count
  Future<int> getPendingCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'career': return '💼';
      case 'health': return '💪';
      case 'finance': return '💰';
      case 'personal': return '🎯';
      case 'learning': return '📚';
      case 'education': return '🎓';
      case 'fitness': return '🏃';
      case 'relationships': return '❤️';
      default: return '✨';
    }
  }

  String _getHabitEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'health': return '💪';
      case 'productivity': return '⚡';
      case 'mindfulness': return '🧘';
      case 'learning': return '📚';
      case 'fitness': return '🏃';
      case 'nutrition': return '🥗';
      case 'sleep': return '😴';
      case 'social': return '👥';
      default: return '✅';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Parse time string to TimeOfDay
  static TimeOfDay? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  /// Format TimeOfDay to string
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANDROID ALARM MANAGER - EXACT ALARMS (Works when app is closed)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule exact one-time alarm using AndroidAlarmManager
  Future<bool> scheduleExactAlarm({
    required int alarmId,
    required DateTime scheduledTime,
    bool allowWhileIdle = true,
    bool wakeup = true,
    bool rescheduleOnReboot = true,
  }) async {
    try {
      final result = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: wakeup,
        allowWhileIdle: allowWhileIdle,
        rescheduleOnReboot: rescheduleOnReboot,
      );
      debugPrint('⏰ Exact alarm scheduled: ID=$alarmId at $scheduledTime - Result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error scheduling exact alarm: $e');
      return false;
    }
  }

  /// Schedule repeating alarm using AndroidAlarmManager (Daily/Weekly)
  Future<bool> scheduleRepeatingAlarm({
    required int alarmId,
    required DateTime startTime,
    required Duration interval,
    bool allowWhileIdle = true,
    bool wakeup = true,
    bool rescheduleOnReboot = true,
  }) async {
    try {
      final result = await AndroidAlarmManager.periodic(
        interval,
        alarmId,
        alarmCallback,
        startAt: startTime,
        exact: true,
        wakeup: wakeup,
        allowWhileIdle: allowWhileIdle,
        rescheduleOnReboot: rescheduleOnReboot,
      );
      debugPrint('🔄 Repeating alarm scheduled: ID=$alarmId, interval=${interval.inHours}h - Result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error scheduling repeating alarm: $e');
      return false;
    }
  }

  /// Cancel exact alarm by ID
  Future<bool> cancelExactAlarm(int alarmId) async {
    try {
      final result = await AndroidAlarmManager.cancel(alarmId);
      debugPrint('❌ Alarm cancelled: ID=$alarmId - Result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error cancelling alarm: $e');
      return false;
    }
  }

  /// Schedule daily exact alarm at specific time
  Future<bool> scheduleDailyExactAlarm({
    required int alarmId,
    required TimeOfDay time,
    bool rescheduleOnReboot = true,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduleRepeatingAlarm(
      alarmId: alarmId,
      startTime: scheduledTime,
      interval: const Duration(days: 1),
      rescheduleOnReboot: rescheduleOnReboot,
    );
  }

  /// Schedule multiple water reminders throughout the day (exact alarms)
  Future<void> scheduleExactWaterReminders() async {
    final waterTimes = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 10, minute: 30),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 15, minute: 30),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ];

    for (int i = 0; i < waterTimes.length; i++) {
      await scheduleDailyExactAlarm(
        alarmId: 5000 + i, // Water alarm IDs: 5000-5005
        time: waterTimes[i],
      );
    }
    debugPrint('💧 Exact water reminders scheduled');
  }

  /// Cancel all water reminders
  Future<void> cancelExactWaterReminders() async {
    for (int i = 0; i < 6; i++) {
      await cancelExactAlarm(5000 + i);
    }
    debugPrint('❌ All water reminders cancelled');
  }
}
