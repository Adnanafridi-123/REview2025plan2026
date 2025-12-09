import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '100');
  
  String _selectedCategory = 'Career';
  String _selectedPriority = 'Medium';
  DateTime _deadline = DateTime(2026, 12, 31);
  
  final List<String> _categories = ['Career', 'Health', 'Finance', 'Personal', 'Custom'];
  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
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
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    // Header - EXACT from video
                    const Text(
                      'Create New Goal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      'Define your target for 2026',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form Card - EXACT from video (White background)
                    Container(
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
                          // Goal Name - EXACT from video
                          _buildLabel('Goal Name'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'e.g., Learn Flutter Development',
                          ),
                          const SizedBox(height: 20),
                          
                          // Category - EXACT from video (Grid of selectable pills)
                          _buildLabel('Category'),
                          const SizedBox(height: 12),
                          _buildCategorySelector(),
                          const SizedBox(height: 20),
                          
                          // Priority - EXACT from video (Segmented control)
                          _buildLabel('Priority'),
                          const SizedBox(height: 12),
                          _buildPrioritySelector(),
                          const SizedBox(height: 20),
                          
                          // Target Value - EXACT from video
                          _buildLabel('Target Value'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _targetController,
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          // Deadline - EXACT from video
                          _buildLabel('Deadline'),
                          const SizedBox(height: 8),
                          _buildDeadlinePicker(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Create Button - EXACT from video (Purple gradient)
                    GestureDetector(
                      onTap: _createGoal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C6DFF), Color(0xFF7C4DFF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Create Goal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF636E72),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // Category Selector - EXACT from video (Grid of pills)
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        final color = AppTheme.categoryColors[category] ?? AppTheme.primaryPurple;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Priority Selector - EXACT from video (Segmented control: High, Medium, Low)
  Widget _buildPrioritySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _priorities.map((priority) {
          final isSelected = _selectedPriority == priority;
          Color priorityColor;
          
          switch (priority) {
            case 'High':
              priorityColor = Colors.red;
              break;
            case 'Medium':
              priorityColor = Colors.orange;
              break;
            case 'Low':
              priorityColor = Colors.green;
              break;
            default:
              priorityColor = Colors.grey;
          }
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPriority = priority),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? priorityColor : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Deadline Picker - EXACT from video
  Widget _buildDeadlinePicker() {
    final formattedDate = DateFormat('MMM d, yyyy').format(_deadline);
    
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _deadline,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryPurple,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _deadline = picked);
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
              formattedDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3436),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  void _createGoal() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    final targetValue = double.tryParse(_targetController.text) ?? 100;
    
    context.read<AppProvider>().addGoal(
      name: _nameController.text,
      category: _selectedCategory,
      description: _descriptionController.text,
      targetValue: targetValue,
      deadline: _deadline,
      priority: _selectedPriority,
    );
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Goal created successfully!'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
