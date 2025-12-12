import 'package:flutter/material.dart';
import '../../services/alarm_service.dart';
import '../../widgets/beautiful_back_button.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final AlarmService _alarmService = AlarmService();
  
  // Settings state
  bool _goalRemindersEnabled = true;
  bool _habitRemindersEnabled = true;
  bool _waterRemindersEnabled = true;
  bool _exerciseRemindersEnabled = true;
  bool _sleepRemindersEnabled = true;
  bool _budgetRemindersEnabled = true;
  bool _motivationEnabled = true;
  
  TimeOfDay _goalReminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _exerciseReminderTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepReminderTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _motivationTime = const TimeOfDay(hour: 8, minute: 0);
  
  int _budgetReviewDay = 7; // Sunday
  int _savingsReminderDay = 1; // 1st of month
  
  int _pendingCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await _alarmService.getPendingCount();
    setState(() => _pendingCount = count);
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              surface: Color(0xFF1a1a2e),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayName(int day) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Water reminders
      await _alarmService.scheduleWaterReminders(enabled: _waterRemindersEnabled);
      
      // Exercise reminder
      if (_exerciseRemindersEnabled) {
        await _alarmService.scheduleExerciseReminder(
          time: _exerciseReminderTime,
          exerciseType: 'workout',
        );
      }
      
      // Sleep reminder
      if (_sleepRemindersEnabled) {
        await _alarmService.scheduleSleepReminder(bedtime: _sleepReminderTime);
      }
      
      // Budget review
      if (_budgetRemindersEnabled) {
        await _alarmService.scheduleWeeklyBudgetReview(
          dayOfWeek: _budgetReviewDay,
          time: const TimeOfDay(hour: 10, minute: 0),
        );
        await _alarmService.scheduleMonthlySavingsReminder(
          dayOfMonth: _savingsReminderDay,
          time: const TimeOfDay(hour: 10, minute: 0),
        );
      }
      
      // Daily motivation
      if (_motivationEnabled) {
        await _alarmService.scheduleDailyMotivation(time: _motivationTime);
      }
      
      await _loadPendingCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('All reminders saved! ✅'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testNotification() async {
    await _alarmService.showInstantNotification(
      title: '🔔 Test Notification',
      body: 'Your reminders are working perfectly! 🎉',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const BeautifulBackButton(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reminder Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Pending count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.alarm, color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$_pendingCount active',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 🎯 Goal Reminders Section
                    _buildSectionHeader('🎯 Goal Reminders'),
                    _buildSettingCard(
                      title: 'Daily Goal Reminders',
                      subtitle: 'Get reminded to work on your goals',
                      value: _goalRemindersEnabled,
                      onChanged: (v) => setState(() => _goalRemindersEnabled = v),
                      trailing: _goalRemindersEnabled 
                          ? _buildTimeButton(_goalReminderTime, (t) => setState(() => _goalReminderTime = t))
                          : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 🔄 Habit Reminders Section
                    _buildSectionHeader('🔄 Habit Reminders'),
                    _buildSettingCard(
                      title: 'Habit Completion Reminders',
                      subtitle: 'Daily reminders for your habits',
                      value: _habitRemindersEnabled,
                      onChanged: (v) => setState(() => _habitRemindersEnabled = v),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 💪 Health Reminders Section
                    _buildSectionHeader('💪 Health Reminders'),
                    _buildSettingCard(
                      title: 'Water Reminders',
                      subtitle: 'Every 2 hours from 8 AM to 10 PM',
                      value: _waterRemindersEnabled,
                      onChanged: (v) => setState(() => _waterRemindersEnabled = v),
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF00BCD4),
                    ),
                    _buildSettingCard(
                      title: 'Exercise Reminders',
                      subtitle: 'Daily workout reminder',
                      value: _exerciseRemindersEnabled,
                      onChanged: (v) => setState(() => _exerciseRemindersEnabled = v),
                      icon: Icons.fitness_center,
                      iconColor: const Color(0xFF4CAF50),
                      trailing: _exerciseRemindersEnabled 
                          ? _buildTimeButton(_exerciseReminderTime, (t) => setState(() => _exerciseReminderTime = t))
                          : null,
                    ),
                    _buildSettingCard(
                      title: 'Sleep Reminders',
                      subtitle: '30 minutes before bedtime',
                      value: _sleepRemindersEnabled,
                      onChanged: (v) => setState(() => _sleepRemindersEnabled = v),
                      icon: Icons.bedtime,
                      iconColor: const Color(0xFF673AB7),
                      trailing: _sleepRemindersEnabled 
                          ? _buildTimeButton(_sleepReminderTime, (t) => setState(() => _sleepReminderTime = t))
                          : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 💰 Finance Reminders Section
                    _buildSectionHeader('💰 Finance Reminders'),
                    _buildSettingCard(
                      title: 'Budget Review',
                      subtitle: 'Weekly on ${_getDayName(_budgetReviewDay)}',
                      value: _budgetRemindersEnabled,
                      onChanged: (v) => setState(() => _budgetRemindersEnabled = v),
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFF56ab2f),
                    ),
                    if (_budgetRemindersEnabled)
                      _buildDaySelector(
                        'Review Day',
                        _budgetReviewDay,
                        [1, 2, 3, 4, 5, 6, 7],
                        (d) => setState(() => _budgetReviewDay = d),
                        isWeekday: true,
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // ✨ Motivation Section
                    _buildSectionHeader('✨ Daily Motivation'),
                    _buildSettingCard(
                      title: 'Motivational Quotes',
                      subtitle: 'Daily inspiration to keep you going',
                      value: _motivationEnabled,
                      onChanged: (v) => setState(() => _motivationEnabled = v),
                      icon: Icons.auto_awesome,
                      iconColor: const Color(0xFFFFD700),
                      trailing: _motivationEnabled 
                          ? _buildTimeButton(_motivationTime, (t) => setState(() => _motivationTime = t))
                          : null,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Test Button
                    OutlinedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Test Notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveAllSettings,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Saving...' : 'Save All Reminders'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cancel All Button
                    TextButton.icon(
                      onPressed: () async {
                        await _alarmService.cancelAllNotifications();
                        await _loadPendingCount();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('All reminders cancelled'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_off, color: Colors.red),
                      label: const Text('Cancel All Reminders', style: TextStyle(color: Colors.red)),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.white).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 8),
                    trailing,
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFFFD700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(TimeOfDay time, Function(TimeOfDay) onSelected) {
    return GestureDetector(
      onTap: () => _selectTime(context, time, onSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 6),
            Text(
              _formatTime(time),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(String label, int selected, List<int> options, Function(int) onSelected, {bool isWeekday = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 56),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        children: options.map((day) {
          final isSelected = day == selected;
          final label = isWeekday ? _getDayName(day) : '$day';
          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
