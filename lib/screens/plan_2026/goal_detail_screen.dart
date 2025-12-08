import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/goal.dart';
import 'create_goal_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _milestoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isEditingNotes = false;

  @override
  void dispose() {
    _milestoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: 'Goal Details',
          showBack: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateGoalScreen(),
                ),
              ),
            ),
          ],
        ),
        body: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final goal = provider.goals.firstWhere(
              (g) => g.id == widget.goal.id,
              orElse: () => widget.goal,
            );
            final categoryColor = AppTheme.categoryColors[goal.category] ?? AppTheme.accentBlue;
            final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      goal.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    goal.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (goal.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      goal.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            CircularPercentIndicator(
                              radius: 50,
                              lineWidth: 10,
                              percent: goal.progress / 100,
                              center: Text(
                                '${goal.progress.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              progressColor: goal.isCompleted
                                  ? AppTheme.accentGreen
                                  : categoryColor,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: daysLeft > 0
                                  ? '$daysLeft days left'
                                  : goal.isCompleted
                                      ? 'Completed'
                                      : 'Overdue',
                            ),
                            _InfoChip(
                              icon: Icons.flag,
                              label: goal.priority,
                            ),
                            _InfoChip(
                              icon: Icons.check_circle_outline,
                              label: goal.isCompleted ? 'Done' : 'In Progress',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress update
                  if (!goal.isCompleted) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Update Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: categoryColor,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                        thumbColor: categoryColor,
                        overlayColor: categoryColor.withValues(alpha: 0.3),
                      ),
                      child: Slider(
                        value: goal.currentValue,
                        min: 0,
                        max: goal.targetValue,
                        onChanged: (value) {
                          provider.updateGoalProgress(goal.id, value);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Milestones section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Milestones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppTheme.titleYellow),
                        onPressed: () => _showAddMilestoneDialog(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (goal.milestones.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No milestones yet. Add some to track your progress!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...goal.milestones.map((milestone) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: milestone.isCompleted,
                            onChanged: (_) {
                              provider.toggleMilestone(goal.id, milestone.id);
                            },
                            title: Text(
                              milestone.title,
                              style: TextStyle(
                                color: Colors.white,
                                decoration: milestone.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: milestone.completedAt != null
                                ? Text(
                                    'Completed ${DateFormat('MMM d').format(milestone.completedAt!)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            activeColor: AppTheme.accentGreen,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Notes section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditingNotes ? Icons.check : Icons.edit,
                          color: AppTheme.titleYellow,
                        ),
                        onPressed: () {
                          if (_isEditingNotes) {
                            provider.updateGoal(
                              goal.copyWith(notes: _notesController.text),
                            );
                          } else {
                            _notesController.text = goal.notes;
                          }
                          setState(() => _isEditingNotes = !_isEditingNotes);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isEditingNotes)
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add notes about your goal...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        goal.notes.isEmpty ? 'No notes yet' : goal.notes,
                        style: TextStyle(
                          color: goal.notes.isEmpty
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Milestone',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _milestoneController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Milestone title',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_milestoneController.text.isNotEmpty) {
                provider.addMilestone(
                  widget.goal.id,
                  _milestoneController.text,
                );
                _milestoneController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
