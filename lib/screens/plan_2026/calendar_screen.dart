import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/habit.dart';
import 'goal_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime(2026, 1, 1);
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar - EXACT from video
              _buildAppBar(context),
              
              // Content
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header - EXACT from video
                        const Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          'View your schedule',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Calendar Card - EXACT from video
                        _buildCalendarCard(),
                        const SizedBox(height: 20),
                        
                        // Selected Day Details - EXACT from video
                        if (_selectedDay != null) _buildDayDetails(provider),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const BeautifulBackButton(),
        ],
      ),
    );
  }

  // Calendar Card - EXACT from video (White background with month navigation)
  Widget _buildCalendarCard() {
    final monthName = DateFormat('MMMM yyyy').format(_focusedDay);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header - EXACT from video
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_left, color: Colors.grey[600]),
                  ),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          
          // Weekday Headers - EXACT from video (Mon-Sun)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          
          // Calendar Grid - EXACT from video
          _buildCalendarGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final provider = context.read<AppProvider>();
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    // Calculate the starting weekday (Monday = 1, Sunday = 7)
    int startWeekday = firstDayOfMonth.weekday;
    
    // Calculate total cells needed
    int totalDays = lastDayOfMonth.day;
    int leadingEmptyCells = startWeekday - 1;
    int totalCells = leadingEmptyCells + totalDays;
    int rows = (totalCells / 7).ceil();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              int cellIndex = rowIndex * 7 + colIndex;
              int dayNumber = cellIndex - leadingEmptyCells + 1;
              
              if (cellIndex < leadingEmptyCells || dayNumber > totalDays) {
                return const SizedBox(width: 40, height: 48);
              }
              
              final date = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              
              // Check if any goal has deadline on this date
              final goalsOnDay = provider.goals.where((g) =>
                  g.deadline.year == date.year &&
                  g.deadline.month == date.month &&
                  g.deadline.day == date.day).toList();
              final hasGoalDeadline = goalsOnDay.isNotEmpty;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                  });
                },
                child: SizedBox(
                  width: 40,
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryOrange
                              : isToday
                                  ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: hasGoalDeadline && !isSelected
                              ? Border.all(color: AppTheme.primaryPurple, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday || hasGoalDeadline ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppTheme.primaryOrange
                                      : hasGoalDeadline
                                          ? AppTheme.primaryPurple
                                          : const Color(0xFF2D3436),
                            ),
                          ),
                        ),
                      ),
                      // Goal indicator dot
                      if (hasGoalDeadline)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // Day Details with Goals and Habits
  Widget _buildDayDetails(AppProvider provider) {
    final dayNumber = _selectedDay!.day;
    final weekday = DateFormat('EEEE').format(_selectedDay!);
    final monthYear = DateFormat('MMMM yyyy').format(_selectedDay!);
    
    // Get habits for this day
    final habitsForDay = provider.habits;
    
    // Get goals with deadline on this day
    final goalsOnDay = provider.goals.where((g) =>
        g.deadline.year == _selectedDay!.year &&
        g.deadline.month == _selectedDay!.month &&
        g.deadline.day == _selectedDay!.day).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Row(
            children: [
              Text(
                '$dayNumber',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekday,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  Text(
                    monthYear,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Goal Deadlines Section (NEW)
          if (goalsOnDay.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primaryPurple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Goal Deadlines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${goalsOnDay.length} goal${goalsOnDay.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...goalsOnDay.map((goal) {
              final categoryColor = AppTheme.categoryColors[goal.category] ?? AppTheme.primaryPurple;
              final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
              
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.15),
                        categoryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      // Progress circle
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: goal.progress / 100,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(categoryColor),
                            ),
                            Center(
                              child: Text(
                                '${goal.progress.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3436),
                                decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    goal.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  daysLeft < 0 ? Icons.warning : Icons.schedule,
                                  size: 14,
                                  color: daysLeft < 0 ? Colors.red : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  daysLeft < 0 
                                      ? 'Overdue' 
                                      : daysLeft == 0 
                                          ? 'Due today!' 
                                          : '$daysLeft days left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                                    fontWeight: daysLeft <= 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        goal.isCompleted ? Icons.check_circle : Icons.chevron_right,
                        color: goal.isCompleted ? AppTheme.primaryGreen : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Daily Habits Section
          Row(
            children: [
              Icon(Icons.repeat, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Daily Habits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (habitsForDay.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'No habits scheduled',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...habitsForDay.map((habit) {
              final isCompleted = habit.completionDates.any((d) =>
                  d.year == _selectedDay!.year &&
                  d.month == _selectedDay!.month &&
                  d.day == _selectedDay!.day);
              final categoryColor = Color(HabitCategory.categoryColors[habit.category] ?? 0xFF4CAF50);
              final categoryIcon = HabitCategory.categoryIcons[habit.category] ?? '🎯';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? categoryColor.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? categoryColor.withValues(alpha: 0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? categoryColor : categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Center(child: Text(categoryIcon, style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3436),
                              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
