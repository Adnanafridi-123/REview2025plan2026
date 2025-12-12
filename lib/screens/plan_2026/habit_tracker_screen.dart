import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/habit.dart';
import '../../services/alarm_service.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProAppBar(context),
              
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final habits = provider.habits;
                    final completedToday = habits.where((h) => h.isCompletedToday()).length;
                    final total = habits.length;
                    final percentage = total > 0 ? (completedToday / total * 100).toInt() : 0;
                    final currentStreak = _calculateBestStreak(habits);
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        // 🔥 Hero Header
                        _buildHeroHeader(total, completedToday),
                        const SizedBox(height: 20),
                        
                        // 📊 Progress Dashboard
                        _buildProgressDashboard(completedToday, total, percentage, currentStreak),
                        const SizedBox(height: 20),
                        
                        // 📅 Week Progress
                        _buildWeekProgress(habits),
                        const SizedBox(height: 24),
                        
                        // 🎯 Habits List or Empty State
                        if (habits.isEmpty)
                          _buildProEmptyState(context)
                        else
                          _buildProHabitsList(habits, provider),
                          
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddHabitDialog(context),
          backgroundColor: const Color(0xFF4ECDC4),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Habit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  int _calculateBestStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildProAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeroHeader(int total, int completed) {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Text('🔄', style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habit Tracker',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildMiniStat('🎯', '$total Habits', const Color(0xFF4ECDC4)),
                  const SizedBox(width: 12),
                  _buildMiniStat('✅', '$completed Done', const Color(0xFFFFE66D)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMiniStat(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDashboard(int completed, int total, int percentage, int bestStreak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Progress Ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildProgressRow('✅ Completed', completed, const Color(0xFF4ECDC4)),
                const SizedBox(height: 10),
                _buildProgressRow('⏳ Remaining', total - completed, const Color(0xFFFFE66D)),
                const SizedBox(height: 10),
                _buildProgressRow('🔥 Best Streak', bestStreak, const Color(0xFFFF6B6B)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeekProgress(List<Habit> habits) {
    final now = DateTime.now();
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final dayOffset = index - (now.weekday - 1);
              final date = now.add(Duration(days: dayOffset));
              final isToday = dayOffset == 0;
              final isPast = dayOffset < 0;
              
              // Count completed habits for this day
              int completedCount = 0;
              for (var habit in habits) {
                if (habit.completionDates.any((d) => 
                    d.year == date.year && d.month == date.month && d.day == date.day)) {
                  completedCount++;
                }
              }
              final hasActivity = completedCount > 0;
              
              return Column(
                children: [
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: isToday 
                          ? const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)])
                          : hasActivity 
                              ? LinearGradient(colors: [const Color(0xFF4ECDC4).withOpacity(0.3), const Color(0xFF44A08D).withOpacity(0.3)])
                              : null,
                      color: isToday || hasActivity ? null : Colors.white.withOpacity(isPast ? 0.05 : 0.1),
                      shape: BoxShape.circle,
                      border: isToday 
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: hasActivity && !isToday
                          ? Text(
                              completedCount.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4ECDC4),
                              ),
                            )
                          : Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? Colors.white : Colors.white.withOpacity(0.6),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4ECDC4).withOpacity(0.3),
                  const Color(0xFF44A08D).withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.5), width: 2),
            ),
            child: const Center(
              child: Text('🔄', style: TextStyle(fontSize: 50)),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No Habits Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start building positive habits\nfor a better 2026!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Pro Habits List with Category
  Widget _buildProHabitsList(List<Habit> habits, AppProvider provider) {
    return Column(
      children: habits.map((habit) {
        final isCompleted = habit.isCompletedToday();
        final categoryColor = Color(HabitCategory.categoryColors[habit.category] ?? 0xFF2196F3);
        final categoryIcon = HabitCategory.categoryIcons[habit.category] ?? '🎯';
        
        return GestureDetector(
          onTap: () => provider.toggleHabitCompletion(habit.id),
          onLongPress: () => _showHabitOptionsDialog(context, habit, provider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isCompleted 
                  ? LinearGradient(
                      colors: [categoryColor.withOpacity(0.2), categoryColor.withOpacity(0.1)],
                    )
                  : LinearGradient(
                      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCompleted ? categoryColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                width: isCompleted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Category Icon + Checkbox
                GestureDetector(
                  onTap: () => provider.toggleHabitCompletion(habit.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? LinearGradient(colors: [categoryColor, categoryColor.withOpacity(0.8)])
                          : null,
                      color: isCompleted ? null : categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isCompleted ? [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: isCompleted 
                        ? const Icon(Icons.check, color: Colors.white, size: 26)
                        : Center(child: Text(categoryIcon, style: const TextStyle(fontSize: 24))),
                  ),
                ),
                const SizedBox(width: 14),
                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? categoryColor : Colors.white,
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                          ),
                          // Reminder Time Badge with AM/PM
                          if (habit.reminderTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.3)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.alarm, size: 12, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    habit.reminderTime!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              habit.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Streak Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: habit.currentStreak > 0 
                                  ? const Color(0xFFFF6B6B).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🔥',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: habit.currentStreak > 0 ? null : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${habit.currentStreak}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: habit.currentStreak > 0 
                                        ? const Color(0xFFFF6B6B) 
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Frequency Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📅', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(
                                  habit.frequency,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Options & Status
                Column(
                  children: [
                    // Options button
                    GestureDetector(
                      onTap: () => _showHabitOptionsDialog(context, habit, provider),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [categoryColor, categoryColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Habit Options Dialog (Edit/Delete)
  void _showHabitOptionsDialog(BuildContext context, Habit habit, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              habit.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 24),
            // Edit Button
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: AppTheme.primaryGreen),
              ),
              title: const Text('Edit Habit', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Change name or frequency'),
              onTap: () {
                Navigator.pop(context);
                _showEditHabitDialog(context, habit, provider);
              },
            ),
            const SizedBox(height: 8),
            // Delete Button
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Delete Habit', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Remove this habit permanently'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteHabitDialog(context, habit, provider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Edit Habit Dialog with Category and Reminder
  void _showEditHabitDialog(BuildContext context, Habit habit, AppProvider provider) {
    final nameController = TextEditingController(text: habit.name);
    String frequency = habit.frequency;
    String category = habit.category;
    TimeOfDay? reminderTime = AlarmService.parseTimeString(habit.reminderTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Habit',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                ),
                const SizedBox(height: 24),

                // Habit name input
                const Text('Habit Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Morning Meditation',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category selector
                const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitCategory.categories.map((cat) {
                    final isSelected = category == cat;
                    final catColor = Color(HabitCategory.categoryColors[cat] ?? 0xFF2196F3);
                    final catIcon = HabitCategory.categoryIcons[cat] ?? '🎯';
                    return GestureDetector(
                      onTap: () => setModalState(() => category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? catColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? catColor : Colors.transparent, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(catIcon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Frequency selector
                const Text('Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 12),
                Row(
                  children: ['Daily', 'Weekly'].map((f) {
                    final isSelected = frequency == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => frequency = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: f == 'Daily' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 🕐 Custom Time Picker with AM/PM for Edit
                const Text('🔔 Daily Reminder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 12),
                
                // Enable/Disable Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: reminderTime != null ? Colors.amber.withOpacity(0.1) : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: reminderTime != null ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reminderTime != null ? Icons.alarm_on : Icons.alarm_off,
                        color: reminderTime != null ? Colors.amber : Colors.grey[400],
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reminderTime != null ? 'Reminder Enabled' : 'Enable Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: reminderTime != null ? Colors.amber[800] : Colors.grey[600],
                          ),
                        ),
                      ),
                      Switch(
                        value: reminderTime != null,
                        onChanged: (value) {
                          setModalState(() {
                            reminderTime = value ? const TimeOfDay(hour: 9, minute: 0) : null;
                          });
                        },
                        activeColor: Colors.amber,
                      ),
                    ],
                  ),
                ),
                
                // 🎯 Custom Time Picker (shown when enabled)
                if (reminderTime != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.amber[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Set Time',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Time Selector Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Selector
                            _buildEditTimeBox(
                              value: reminderTime!.hourOfPeriod == 0 ? 12 : reminderTime!.hourOfPeriod,
                              label: 'Hour',
                              onTap: () => _showEditHourPicker(context, reminderTime!, (newTime) {
                                setModalState(() => reminderTime = newTime);
                              }),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                            ),
                            
                            // Minute Selector
                            _buildEditTimeBox(
                              value: reminderTime!.minute,
                              label: 'Min',
                              isMinute: true,
                              onTap: () => _showEditMinutePicker(context, reminderTime!, (newTime) {
                                setModalState(() => reminderTime = newTime);
                              }),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // AM/PM Toggle
                            Column(
                              children: [
                                // AM Button
                                GestureDetector(
                                  onTap: () {
                                    if (reminderTime!.hour >= 12) {
                                      setModalState(() {
                                        reminderTime = TimeOfDay(
                                          hour: reminderTime!.hour - 12,
                                          minute: reminderTime!.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: reminderTime!.hour < 12
                                          ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                                          : null,
                                      color: reminderTime!.hour < 12 ? null : Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'AM',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: reminderTime!.hour < 12 ? Colors.white : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // PM Button
                                GestureDetector(
                                  onTap: () {
                                    if (reminderTime!.hour < 12) {
                                      setModalState(() {
                                        reminderTime = TimeOfDay(
                                          hour: reminderTime!.hour + 12,
                                          minute: reminderTime!.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: reminderTime!.hour >= 12
                                          ? const LinearGradient(colors: [Color(0xFF764ba2), Color(0xFF667eea)])
                                          : null,
                                      color: reminderTime!.hour >= 12 ? null : Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'PM',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: reminderTime!.hour >= 12 ? Colors.white : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        // Time display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🔔 ${_formatTimeAMPM(reminderTime!)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Save button
                GestureDetector(
                  onTap: () async {
                    if (nameController.text.isNotEmpty) {
                      final reminderStr = reminderTime != null ? AlarmService.formatTimeOfDay(reminderTime!) : null;
                      
                      // Cancel old reminder
                      await AlarmService().cancelHabitReminder(habit.id);
                      
                      final updated = habit.copyWith(
                        name: nameController.text,
                        frequency: frequency,
                        category: category,
                        reminderTime: reminderStr,
                      );
                      provider.updateHabit(updated);
                      
                      // Schedule new reminder if set
                      if (reminderTime != null) {
                        await AlarmService().scheduleHabitReminder(
                          habitId: updated.id,
                          habitName: updated.name,
                          category: category,
                          time: reminderTime!,
                        );
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Habit updated!'),
                          backgroundColor: Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50),
                          Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Delete Habit Confirmation Dialog
  void _showDeleteHabitDialog(BuildContext context, Habit habit, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Habit?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${habit.name}"? Your streak will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.deleteHabit(habit.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Habit deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Add Habit Dialog with Category and Reminder - Pro Version
  void _showAddHabitDialog(BuildContext ctx) {
    final nameController = TextEditingController();
    String frequency = 'Daily';
    String category = 'Personal';
    TimeOfDay? reminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header with Icon
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🔄', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Habit',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Build a better you ✨',
                          style: TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Habit name input
                const Text('🎯 Habit Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Morning Meditation',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(Icons.edit, color: const Color(0xFF4ECDC4).withOpacity(0.7), size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category selector
                const Text('📂 Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitCategory.categories.map((cat) {
                    final isSelected = category == cat;
                    final catColor = Color(HabitCategory.categoryColors[cat] ?? 0xFF2196F3);
                    final catIcon = HabitCategory.categoryIcons[cat] ?? '🎯';
                    return GestureDetector(
                      onTap: () => setModalState(() => category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? LinearGradient(colors: [catColor, catColor.withOpacity(0.8)]) : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: catColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(catIcon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Frequency selector
                const Text('📅 Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  children: ['Daily', 'Weekly'].map((f) {
                    final isSelected = frequency == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => frequency = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: f == 'Daily' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isSelected ? const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]) : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(f == 'Daily' ? '🌅' : '📆', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 🕐 Custom Time Picker with AM/PM
                const Text('🔔 Daily Reminder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                
                // Enable/Disable Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reminderTime != null ? Icons.alarm_on : Icons.alarm_off,
                        color: reminderTime != null ? Colors.amber : Colors.white.withOpacity(0.5),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reminderTime != null ? 'Reminder Enabled' : 'Enable Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: reminderTime != null ? Colors.amber : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Switch(
                        value: reminderTime != null,
                        onChanged: (value) {
                          setModalState(() {
                            reminderTime = value ? const TimeOfDay(hour: 9, minute: 0) : null;
                          });
                        },
                        activeColor: Colors.amber,
                      ),
                    ],
                  ),
                ),
                
                // 🎯 Custom Time Picker (shown when enabled)
                if (reminderTime != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Set Time',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Time Selector Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Selector
                            _buildHabitTimeBox(
                              value: reminderTime!.hourOfPeriod == 0 ? 12 : reminderTime!.hourOfPeriod,
                              label: 'Hour',
                              onTap: () => _showHabitHourPicker(context, reminderTime!, (newTime) {
                                setModalState(() => reminderTime = newTime);
                              }),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            
                            // Minute Selector
                            _buildHabitTimeBox(
                              value: reminderTime!.minute,
                              label: 'Min',
                              isMinute: true,
                              onTap: () => _showHabitMinutePicker(context, reminderTime!, (newTime) {
                                setModalState(() => reminderTime = newTime);
                              }),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // AM/PM Toggle
                            Column(
                              children: [
                                // AM Button
                                GestureDetector(
                                  onTap: () {
                                    if (reminderTime!.hour >= 12) {
                                      setModalState(() {
                                        reminderTime = TimeOfDay(
                                          hour: reminderTime!.hour - 12,
                                          minute: reminderTime!.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: reminderTime!.hour < 12
                                          ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                                          : null,
                                      color: reminderTime!.hour < 12 ? null : Colors.white.withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      border: Border.all(
                                        color: reminderTime!.hour < 12 ? Colors.transparent : Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'AM',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: reminderTime!.hour < 12 ? const Color(0xFF1a1a2e) : Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // PM Button
                                GestureDetector(
                                  onTap: () {
                                    if (reminderTime!.hour < 12) {
                                      setModalState(() {
                                        reminderTime = TimeOfDay(
                                          hour: reminderTime!.hour + 12,
                                          minute: reminderTime!.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: reminderTime!.hour >= 12
                                          ? const LinearGradient(colors: [Color(0xFF764ba2), Color(0xFF667eea)])
                                          : null,
                                      color: reminderTime!.hour >= 12 ? null : Colors.white.withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                      border: Border.all(
                                        color: reminderTime!.hour >= 12 ? Colors.transparent : Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'PM',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: reminderTime!.hour >= 12 ? Colors.white : Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🔊', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll get a notification with sound at ${_formatTimeAMPM(reminderTime!)}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Create button
                GestureDetector(
                  onTap: () async {
                    if (nameController.text.isNotEmpty) {
                      final reminderStr = reminderTime != null 
                          ? AlarmService.formatTimeOfDay(reminderTime!)
                          : null;
                      
                      context.read<AppProvider>().addHabit(
                        name: nameController.text,
                        frequency: frequency,
                        category: category,
                        reminderTime: reminderStr,
                      );
                      
                      // Schedule notification if reminder is set
                      if (reminderTime != null) {
                        await AlarmService().requestPermissions();
                        await AlarmService().scheduleHabitReminder(
                          habitId: nameController.text.hashCode.toString(),
                          habitName: nameController.text,
                          category: category,
                          time: reminderTime!,
                        );
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(reminderTime != null 
                                    ? 'Habit created! Reminder at ${_formatTimeAMPM(reminderTime!)}' 
                                    : 'Habit created successfully!'),
                              ),
                            ],
                          ),
                          backgroundColor: Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50),
                          Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Color(HabitCategory.categoryColors[category] ?? 0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text('Create Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (reminderTime != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm, color: Colors.white, size: 12),
                                SizedBox(width: 3),
                                Text('With Alarm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatTimeAMPM(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  
  // 🎯 Habit Time Box Widget
  Widget _buildHabitTimeBox({
    required int value,
    required String label,
    required VoidCallback onTap,
    bool isMinute = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMinute ? value.toString().padLeft(2, '0') : value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
  
  // 🕐 Habit Hour Picker
  void _showHabitHourPicker(BuildContext ctx, TimeOfDay currentTime, Function(TimeOfDay) onSelect) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 340,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏰ Select Hour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final hour = index + 1;
                  final currentHour = currentTime.hourOfPeriod == 0 ? 12 : currentTime.hourOfPeriod;
                  final isSelected = hour == currentHour;
                  return GestureDetector(
                    onTap: () {
                      final isAM = currentTime.hour < 12;
                      int newHour;
                      if (hour == 12) {
                        newHour = isAM ? 0 : 12;
                      } else {
                        newHour = isAM ? hour : hour + 12;
                      }
                      onSelect(TimeOfDay(hour: newHour, minute: currentTime.minute));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hour.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // ⏱️ Habit Minute Picker
  void _showHabitMinutePicker(BuildContext ctx, TimeOfDay currentTime, Function(TimeOfDay) onSelect) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 380,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏱️ Select Minutes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.3,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final minute = index * 5;
                  final isSelected = minute == currentTime.minute;
                  return GestureDetector(
                    onTap: () {
                      onSelect(TimeOfDay(hour: currentTime.hour, minute: minute));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // 🎯 Edit Habit Time Box (Light Theme)
  Widget _buildEditTimeBox({
    required int value,
    required String label,
    required VoidCallback onTap,
    bool isMinute = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              isMinute ? value.toString().padLeft(2, '0') : value.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 14),
          ],
        ),
      ),
    );
  }
  
  // 🕐 Edit Hour Picker (Light Theme)
  void _showEditHourPicker(BuildContext ctx, TimeOfDay currentTime, Function(TimeOfDay) onSelect) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 340,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏰ Select Hour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final hour = index + 1;
                  final currentHour = currentTime.hourOfPeriod == 0 ? 12 : currentTime.hourOfPeriod;
                  final isSelected = hour == currentHour;
                  return GestureDetector(
                    onTap: () {
                      final isAM = currentTime.hour < 12;
                      int newHour;
                      if (hour == 12) {
                        newHour = isAM ? 0 : 12;
                      } else {
                        newHour = isAM ? hour : hour + 12;
                      }
                      onSelect(TimeOfDay(hour: newHour, minute: currentTime.minute));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                            : null,
                        color: isSelected ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          hour.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // ⏱️ Edit Minute Picker (Light Theme)
  void _showEditMinutePicker(BuildContext ctx, TimeOfDay currentTime, Function(TimeOfDay) onSelect) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏱️ Select Minutes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.3,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final minute = index * 5;
                  final isSelected = minute == currentTime.minute;
                  return GestureDetector(
                    onTap: () {
                      onSelect(TimeOfDay(hour: currentTime.hour, minute: minute));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)])
                            : null,
                        color: isSelected ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
