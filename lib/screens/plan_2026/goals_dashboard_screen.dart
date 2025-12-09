import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/goal.dart';
import '../../widgets/beautiful_back_button.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsDashboardScreen extends StatefulWidget {
  const GoalsDashboardScreen({super.key});

  @override
  State<GoalsDashboardScreen> createState() => _GoalsDashboardScreenState();
}

class _GoalsDashboardScreenState extends State<GoalsDashboardScreen> {
  // Filter state - EXACT from video
  String _selectedCategory = 'All';
  String _selectedStatus = 'Active';
  
  final List<String> _categories = ['All', 'Career', 'Health', 'Finance', 'Personal'];
  final List<String> _statuses = ['Active', 'Completed', 'All'];

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
                    final filteredGoals = _filterGoals(provider.goals);
                    final activeCount = provider.activeGoals.length;
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header - EXACT from video
                        const Text(
                          'Goals Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          '$activeCount active goals',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Category Filter Pills - Row 1 (EXACT from video)
                        _buildCategoryFilters(),
                        const SizedBox(height: 12),
                        
                        // Status Filter Pills - Row 2 (EXACT from video)
                        _buildStatusFilters(),
                        const SizedBox(height: 24),
                        
                        // Content
                        if (filteredGoals.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildGoalsList(filteredGoals, provider),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // FAB - EXACT from video: "+ Add Goal" with purple background
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          ),
          backgroundColor: AppTheme.primaryPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Goal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Goal> _filterGoals(List<Goal> goals) {
    return goals.where((goal) {
      // Category filter
      if (_selectedCategory != 'All' && goal.category != _selectedCategory) {
        return false;
      }
      // Status filter
      if (_selectedStatus == 'Active' && goal.isCompleted) {
        return false;
      }
      if (_selectedStatus == 'Completed' && !goal.isCompleted) {
        return false;
      }
      return true;
    }).toList();
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

  // Category Filter Pills - EXACT from video
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryPurple : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryPurple : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Status Filter Pills - EXACT from video
  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryPurple : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryPurple : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Empty State - EXACT from video: Target illustration, "No goals yet" text
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Target Illustration - EXACT from video
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // EXACT text from video
          const Text(
            'No goals yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start setting goals to achieve your\ndreams in 2026!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Goals List - EXACT from video design
  Widget _buildGoalsList(List<Goal> goals, AppProvider provider) {
    return Column(
      children: goals.map((goal) {
        final progress = goal.targetValue > 0 
            ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0)
            : 0.0;
        final categoryColor = AppTheme.categoryColors[goal.category] ?? AppTheme.primaryPurple;
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category icon with color
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(goal.category),
                        color: categoryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
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
                              if (goal.isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Progress percentage - EXACT from video
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar - EXACT from video
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(categoryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Career':
        return Icons.work_outline;
      case 'Health':
        return Icons.favorite_outline;
      case 'Finance':
        return Icons.attach_money;
      case 'Personal':
        return Icons.person_outline;
      case 'Learning':
        return Icons.school;
      default:
        return Icons.gps_fixed;
    }
  }
}
