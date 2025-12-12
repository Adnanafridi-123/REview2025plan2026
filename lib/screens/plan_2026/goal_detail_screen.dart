import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/goal.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _milestoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _milestoneDescController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditingNotes = false;

  @override
  void dispose() {
    _milestoneController.dispose();
    _notesController.dispose();
    _milestoneDescController.dispose();
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
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareGoalProgress(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showEditGoalDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmation(context),
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
                          'No sub-tasks yet. Add some to track your progress!',
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
                          child: Column(
                            children: [
                              ListTile(
                                leading: GestureDetector(
                                  onTap: () => provider.toggleMilestone(goal.id, milestone.id),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: milestone.isCompleted ? AppTheme.accentGreen : Colors.transparent,
                                      border: Border.all(
                                        color: milestone.isCompleted ? AppTheme.accentGreen : Colors.white54,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: milestone.isCompleted
                                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  milestone.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration: milestone.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (milestone.description != null && milestone.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          milestone.description!,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                        ),
                                      ),
                                    if (milestone.dueDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.schedule, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${DateFormat('MMM d').format(milestone.dueDate!)}',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (milestone.completedAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '✓ Completed ${DateFormat('MMM d').format(milestone.completedAt!)}',
                                          style: TextStyle(color: AppTheme.accentGreen.withValues(alpha: 0.8), fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7)),
                                  color: const Color(0xFF2D3436),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditMilestoneDialog(context, provider, goal, milestone);
                                    } else if (value == 'delete') {
                                      _showDeleteMilestoneDialog(context, provider, goal, milestone);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Photos Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress Photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate, color: AppTheme.titleYellow),
                        onPressed: () => _showAddPhotoDialog(context, provider, goal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (goal.photos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, color: Colors.white.withValues(alpha: 0.3), size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'No photos yet. Add photos to document your progress!',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: goal.photos.length,
                        itemBuilder: (context, index) {
                          final photoPath = goal.photos[index];
                          return GestureDetector(
                            onTap: () => _showPhotoViewer(context, photoPath),
                            onLongPress: () => _showDeletePhotoDialog(context, provider, goal, index),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: File(photoPath).existsSync()
                                    ? Image.file(File(photoPath), fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        child: const Icon(Icons.broken_image, color: Colors.white54),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

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
    DateTime? selectedDueDate;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF2D3436),
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Sub-Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                
                // Title
                TextField(
                  controller: _milestoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintText: 'e.g., Complete chapter 1',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: _milestoneDescController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintText: 'Add details about this task',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Due Date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setModalState(() => selectedDueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.7), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedDueDate != null ? 'Due: ${DateFormat('MMM d, yyyy').format(selectedDueDate!)}' : 'Set Due Date (optional)',
                          style: TextStyle(color: Colors.white.withValues(alpha: selectedDueDate != null ? 1 : 0.5)),
                        ),
                        const Spacer(),
                        if (selectedDueDate != null)
                          GestureDetector(
                            onTap: () => setModalState(() => selectedDueDate = null),
                            child: const Icon(Icons.close, color: Colors.white54, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Add Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_milestoneController.text.isNotEmpty) {
                      provider.addMilestoneWithDetails(
                        widget.goal.id,
                        _milestoneController.text,
                        description: _milestoneDescController.text.isNotEmpty ? _milestoneDescController.text : null,
                        dueDate: selectedDueDate,
                      );
                      _milestoneController.clear();
                      _milestoneDescController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Sub-Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMilestoneDialog(BuildContext context, AppProvider provider, Goal goal, Milestone milestone) {
    final titleController = TextEditingController(text: milestone.title);
    final descController = TextEditingController(text: milestone.description ?? '');
    DateTime? selectedDueDate = milestone.dueDate;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF2D3436),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Text('Edit Sub-Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setModalState(() => selectedDueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.7), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedDueDate != null ? 'Due: ${DateFormat('MMM d, yyyy').format(selectedDueDate!)}' : 'Set Due Date',
                          style: TextStyle(color: Colors.white.withValues(alpha: selectedDueDate != null ? 1 : 0.5)),
                        ),
                        const Spacer(),
                        if (selectedDueDate != null)
                          GestureDetector(onTap: () => setModalState(() => selectedDueDate = null), child: const Icon(Icons.close, color: Colors.white54, size: 20)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final updated = milestone.copyWith(
                        title: titleController.text,
                        description: descController.text.isNotEmpty ? descController.text : null,
                        dueDate: selectedDueDate,
                      );
                      provider.updateMilestone(goal.id, updated);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteMilestoneDialog(BuildContext context, AppProvider provider, Goal goal, Milestone milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Sub-Task?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${milestone.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              provider.deleteMilestone(goal.id, milestone.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context, AppProvider provider, Goal goal) {
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
            const Text('Add Progress Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (image != null) {
                        final photos = List<String>.from(goal.photos)..add(image.path);
                        provider.updateGoal(goal.copyWith(photos: photos));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: AppTheme.primaryPurple),
                          SizedBox(height: 8),
                          Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (image != null) {
                        final photos = List<String>.from(goal.photos)..add(image.path);
                        provider.updateGoal(goal.copyWith(photos: photos));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.accentGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library, size: 40, color: AppTheme.accentGreen),
                          SizedBox(height: 8),
                          Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentGreen)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeletePhotoDialog(BuildContext context, AppProvider provider, Goal goal, int photoIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final photos = List<String>.from(goal.photos)..removeAt(photoIndex);
              provider.updateGoal(goal.copyWith(photos: photos));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: File(photoPath).existsSync()
                  ? Image.file(File(photoPath), fit: BoxFit.contain)
                  : const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareGoalProgress(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final goal = provider.goals.firstWhere((g) => g.id == widget.goal.id, orElse: () => widget.goal);
    final categoryColor = AppTheme.categoryColors[goal.category] ?? AppTheme.accentBlue;
    final completedMilestones = goal.milestones.where((m) => m.isCompleted).length;
    
    // Create share text
    final shareText = '''
🎯 Goal Progress Update!

📌 ${goal.name}
📊 Progress: ${goal.progress.toInt()}%
📁 Category: ${goal.category}
⏰ Deadline: ${DateFormat('MMM d, yyyy').format(goal.deadline)}
✅ Sub-tasks: $completedMilestones/${goal.milestones.length} completed

${goal.isCompleted ? '🏆 GOAL COMPLETED!' : '💪 Keep going!'}

#Plan2026 #GoalTracking #Progress
''';

    // Show share options
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
            const Text('Share Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Share your goal progress with others!', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            // Progress Card Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [categoryColor, categoryColor.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(goal.category, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 35,
                        lineWidth: 6,
                        percent: goal.progress / 100,
                        center: Text('${goal.progress.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('✅ $completedMilestones/${goal.milestones.length} tasks', style: const TextStyle(color: Colors.white)),
                      Text('📅 ${DateFormat('MMM d').format(goal.deadline)}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Share buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Share.share(shareText);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4405F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Instagram', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Share.share(shareText);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share),
                label: const Text('More Options', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  Share.share(shareText);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final goal = provider.goals.firstWhere(
      (g) => g.id == widget.goal.id,
      orElse: () => widget.goal,
    );
    
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(text: goal.targetValue.toInt().toString());
    String selectedCategory = goal.category;
    String selectedPriority = goal.priority;
    DateTime deadline = goal.deadline;
    
    final categories = ['Career', 'Health', 'Finance', 'Personal', 'Custom'];
    final priorities = ['High', 'Medium', 'Low'];
    
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
                  'Edit Goal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Goal Name
                const Text('Goal Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Goal name',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category
                const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    final color = AppTheme.categoryColors[cat] ?? AppTheme.primaryPurple;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Priority
                const Text('Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                Row(
                  children: priorities.map((p) {
                    final isSelected = selectedPriority == p;
                    Color pColor = p == 'High' ? Colors.red : p == 'Medium' ? Colors.orange : Colors.green;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedPriority = p),
                        child: Container(
                          margin: EdgeInsets.only(right: p != 'Low' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? pColor : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Target Value
                const Text('Target Value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '100',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Deadline
                const Text('Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setModalState(() => deadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.primaryPurple, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(deadline),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Save Button
                GestureDetector(
                  onTap: () {
                    if (nameController.text.isNotEmpty) {
                      final updated = goal.copyWith(
                        name: nameController.text,
                        category: selectedCategory,
                        priority: selectedPriority,
                        targetValue: double.tryParse(targetController.text) ?? goal.targetValue,
                        deadline: deadline,
                      );
                      provider.updateGoal(updated);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Goal updated!'),
                          backgroundColor: AppTheme.primaryPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF9C6DFF), Color(0xFF7C4DFF)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone. Are you sure you want to delete this goal?'),
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
              context.read<AppProvider>().deleteGoal(widget.goal.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to goals list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Goal deleted'),
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
