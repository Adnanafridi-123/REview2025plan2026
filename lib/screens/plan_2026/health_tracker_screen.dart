import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../widgets/beautiful_back_button.dart';
import '../../services/alarm_service.dart';

class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({super.key});

  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  final List<HealthGoalItem> _goals = [];
  
  final List<Map<String, dynamic>> _types = [
    {'type': 'weight', 'name': 'Weight', 'icon': Icons.monitor_weight, 'color': 0xFF9C27B0, 'unit': 'kg'},
    {'type': 'water', 'name': 'Water', 'icon': Icons.water_drop, 'color': 0xFF2196F3, 'unit': 'L'},
    {'type': 'sleep', 'name': 'Sleep', 'icon': Icons.bedtime, 'color': 0xFF673AB7, 'unit': 'hrs'},
    {'type': 'steps', 'name': 'Steps', 'icon': Icons.directions_walk, 'color': 0xFF4CAF50, 'unit': 'steps'},
    {'type': 'exercise', 'name': 'Exercise', 'icon': Icons.fitness_center, 'color': 0xFFFF5722, 'unit': 'min'},
    {'type': 'meditation', 'name': 'Meditation', 'icon': Icons.self_improvement, 'color': 0xFF00BCD4, 'unit': 'min'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTodaysSummary(),
              Expanded(child: _buildGoalsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Tracker', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Your wellness journey 💪', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFF5722), size: 16),
              const SizedBox(width: 6),
              Text('${_calculateStreak()} day streak', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  int _calculateStreak() {
    if (_goals.isEmpty) return 0;
    return _goals.map((g) => g.currentStreak).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildTodaysSummary() {
    final completed = _goals.where((g) => g.todayValue >= g.targetValue).length;
    final total = _goals.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('$completed of $total goals completed', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress.clamp(0, 1), backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8),
              ),
            ]),
          ),
          const SizedBox(width: 20),
          CircularPercentIndicator(
            radius: 45,
            lineWidth: 8,
            percent: progress.clamp(0, 1),
            center: Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            progressColor: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    if (_goals.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.favorite, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No health goals yet', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const Text('Start tracking your wellness!', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: _types.take(4).map((t) => _buildQuickAddChip(t)).toList(),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _goals.length,
      itemBuilder: (context, index) => _buildGoalCard(_goals[index], index),
    );
  }

  Widget _buildQuickAddChip(Map<String, dynamic> type) {
    final color = Color(type['color'] as int);
    return GestureDetector(
      onTap: () => _showAddDialogWithType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(type['icon'] as IconData, color: color, size: 18),
          const SizedBox(width: 8),
          Text(type['name'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildGoalCard(HealthGoalItem goal, int index) {
    final typeInfo = _types.firstWhere((t) => t['type'] == goal.type, orElse: () => _types.first);
    final color = Color(typeInfo['color'] as int);
    final progress = goal.targetValue > 0 ? (goal.todayValue / goal.targetValue) : 0.0;
    final isComplete = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isComplete ? Colors.green.withValues(alpha: 0.5) : color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showLogDialog(goal, index),
        onLongPress: () => _showOptions(goal, index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 35,
                lineWidth: 6,
                percent: progress.clamp(0, 1),
                center: Icon(typeInfo['icon'] as IconData, color: isComplete ? Colors.green : color, size: 24),
                progressColor: isComplete ? Colors.green : color,
                backgroundColor: color.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isComplete) const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                    ),
                  ]),
                  Text('${goal.todayValue.toStringAsFixed(goal.type == 'steps' ? 0 : 1)} / ${goal.targetValue.toStringAsFixed(goal.type == 'steps' ? 0 : 1)} ${typeInfo['unit']}',
                    style: TextStyle(color: color, fontSize: 13)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: progress.clamp(0, 1), backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(isComplete ? Colors.green : color), minHeight: 6),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.local_fire_department, size: 14, color: goal.currentStreak > 0 ? const Color(0xFFFF5722) : Colors.white24),
                    const SizedBox(width: 4),
                    Text('${goal.currentStreak} day streak', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                  ]),
                ]),
              ),
              Column(children: [
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: isComplete ? Colors.green : color, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(goal.frequency, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    _showAddDialogWithType(null);
  }

  void _showAddDialogWithType(Map<String, dynamic>? preselectedType) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedType = preselectedType?['type'] as String? ?? 'water';
    bool reminderEnabled = false;
    TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);

    if (preselectedType != null) {
      titleController.text = preselectedType['name'] as String;
      switch (selectedType) {
        case 'water': targetController.text = '3'; reminderEnabled = true; break;
        case 'sleep': targetController.text = '8'; reminderTime = const TimeOfDay(hour: 22, minute: 0); break;
        case 'steps': targetController.text = '10000'; break;
        case 'exercise': targetController.text = '30'; reminderTime = const TimeOfDay(hour: 7, minute: 0); break;
        case 'meditation': targetController.text = '15'; reminderTime = const TimeOfDay(hour: 6, minute: 30); break;
        case 'weight': targetController.text = '70'; break;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add Health Goal', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Goal Title', labelStyle: const TextStyle(color: Colors.white70),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Daily Target',
                  suffixText: _types.firstWhere((t) => t['type'] == selectedType)['unit'] as String,
                  suffixStyle: const TextStyle(color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _types.map((t) {
                  final isSelected = selectedType == t['type'];
                  final color = Color(t['color'] as int);
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedType = t['type'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: isSelected ? color : color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(t['name'] as String, style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 12)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Reminder Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: reminderEnabled ? const Color(0xFF4CAF50).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: reminderEnabled ? const Color(0xFF4CAF50).withValues(alpha: 0.5) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: reminderEnabled ? const Color(0xFF4CAF50) : Colors.white54, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text(
                            reminderEnabled ? 'At ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}' : 'Tap to enable',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (reminderEnabled)
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: reminderTime);
                          if (picked != null) setDialogState(() => reminderTime = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(8)),
                          child: Text('${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    Switch(
                      value: reminderEnabled,
                      onChanged: (v) => setDialogState(() => reminderEnabled = v),
                      activeColor: const Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && targetController.text.isNotEmpty) {
                      setState(() => _goals.add(HealthGoalItem(
                        title: titleController.text,
                        type: selectedType,
                        targetValue: double.tryParse(targetController.text) ?? 0,
                      )));
                      
                      // Schedule reminders based on type
                      if (reminderEnabled) {
                        if (selectedType == 'water') {
                          await AlarmService().scheduleWaterReminders(enabled: true);
                        } else if (selectedType == 'exercise') {
                          await AlarmService().scheduleExerciseReminder(time: reminderTime, exerciseType: titleController.text);
                        } else if (selectedType == 'sleep') {
                          await AlarmService().scheduleSleepReminder(bedtime: reminderTime);
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.alarm, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Reminder set for ${titleController.text}!'),
                            ]),
                            backgroundColor: const Color(0xFF4CAF50),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Add Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (reminderEnabled) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showLogDialog(HealthGoalItem goal, int index) {
    final typeInfo = _types.firstWhere((t) => t['type'] == goal.type, orElse: () => _types.first);
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Current: ${goal.todayValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${typeInfo['unit']}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Add Value',
              suffixText: typeInfo['unit'] as String,
              suffixStyle: const TextStyle(color: Colors.white70),
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text) ?? 0;
                  if (value > 0) {
                    setState(() {
                      goal.todayValue += value;
                      if (goal.todayValue >= goal.targetValue) goal.currentStreak++;
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(typeInfo['color'] as int), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Log', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    goal.todayValue = goal.targetValue;
                    goal.currentStreak++;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Complete', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showOptions(HealthGoalItem goal, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.white70),
            title: const Text('Reset Today', style: TextStyle(color: Colors.white)),
            onTap: () { setState(() => goal.todayValue = 0); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            onTap: () { setState(() => _goals.removeAt(index)); Navigator.pop(context); },
          ),
        ]),
      ),
    );
  }
}

class HealthGoalItem {
  final String title;
  final String type;
  final double targetValue;
  double todayValue;
  int currentStreak;
  final String frequency;

  HealthGoalItem({required this.title, required this.type, required this.targetValue, this.todayValue = 0, this.currentStreak = 0, this.frequency = 'Daily'});
}
