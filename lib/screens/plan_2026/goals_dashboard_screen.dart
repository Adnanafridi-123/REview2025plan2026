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

class _GoalsDashboardScreenState extends State<GoalsDashboardScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _selectedStatus = 'Active';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': '✨', 'color': 0xFF667eea},
    {'name': 'Career', 'icon': '💼', 'color': 0xFF4ECDC4},
    {'name': 'Health', 'icon': '💪', 'color': 0xFFFF6B6B},
    {'name': 'Finance', 'icon': '💰', 'color': 0xFFFFE66D},
    {'name': 'Personal', 'icon': '🎯', 'color': 0xFF9B59B6},
    {'name': 'Learning', 'icon': '📚', 'color': 0xFF3498DB},
  ];
  final List<String> _statuses = ['Active', 'Completed', 'All'];
  
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
                    final filteredGoals = _filterGoals(provider.goals);
                    final activeCount = provider.activeGoals.length;
                    final completedCount = provider.goals.where((g) => g.isCompleted).length;
                    final totalProgress = _calculateTotalProgress(provider.goals);
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        // 🔥 Hero Header
                        _buildHeroHeader(activeCount, completedCount),
                        const SizedBox(height: 20),
                        
                        // 📊 Progress Overview Card
                        _buildProgressOverview(totalProgress, activeCount, completedCount, provider.goals.length),
                        const SizedBox(height: 20),
                        
                        // 🏷️ Category Filters
                        _buildProCategoryFilters(),
                        const SizedBox(height: 12),
                        
                        // 📊 Status Filters
                        _buildProStatusFilters(),
                        const SizedBox(height: 24),
                        
                        // Content
                        if (filteredGoals.isEmpty)
                          _buildProEmptyState(context)
                        else
                          _buildProGoalsList(filteredGoals, provider),
                          
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          ),
          backgroundColor: const Color(0xFF667eea),
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
  
  double _calculateTotalProgress(List<Goal> goals) {
    if (goals.isEmpty) return 0;
    double total = 0;
    for (var goal in goals) {
      if (goal.targetValue > 0) {
        total += (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
      }
    }
    return total / goals.length;
  }
  
  Widget _buildHeroHeader(int activeCount, int completedCount) {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '2026 Goals',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildMiniStat('🔥', '$activeCount Active', const Color(0xFF4ECDC4)),
                  const SizedBox(width: 12),
                  _buildMiniStat('✅', '$completedCount Done', const Color(0xFFFFE66D)),
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
  
  Widget _buildProgressOverview(double progress, int active, int completed, int total) {
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
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Progress',
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
                _buildProgressRow('🔥 Active', active, const Color(0xFF4ECDC4)),
                const SizedBox(height: 10),
                _buildProgressRow('✅ Completed', completed, const Color(0xFFFFE66D)),
                const SizedBox(height: 10),
                _buildProgressRow('📊 Total', total, const Color(0xFFFF6B6B)),
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

  Widget _buildProCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          final color = Color(cat['color'] as int);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Text(cat['icon'] as String, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProStatusFilters() {
    final statusData = [
      {'name': 'Active', 'icon': '🔥', 'color': 0xFF4ECDC4},
      {'name': 'Completed', 'icon': '✅', 'color': 0xFFFFE66D},
      {'name': 'All', 'icon': '📊', 'color': 0xFF667eea},
    ];
    
    return Row(
      children: statusData.map((status) {
        final isSelected = _selectedStatus == status['name'];
        final color = Color(status['color'] as int);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedStatus = status['name'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: status['name'] != 'All' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(status['icon'] as String, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    status['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
                  const Color(0xFF667eea).withOpacity(0.3),
                  const Color(0xFF764ba2).withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF667eea).withOpacity(0.5), width: 2),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 50)),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No Goals Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start setting goals to achieve\nyour dreams in 2026!',
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

  Widget _buildProGoalsList(List<Goal> goals, AppProvider provider) {
    return Column(
      children: goals.map((goal) {
        final progress = goal.targetValue > 0 
            ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0)
            : 0.0;
        final categoryData = _categories.firstWhere(
          (c) => c['name'] == goal.category,
          orElse: () => {'name': 'Personal', 'icon': '🎯', 'color': 0xFF9B59B6},
        );
        final categoryColor = Color(categoryData['color'] as int);
        final categoryIcon = categoryData['icon'] as String;
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: categoryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [categoryColor, categoryColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(categoryIcon, style: const TextStyle(fontSize: 24)),
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  goal.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (goal.isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4ECDC4).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('✅', style: TextStyle(fontSize: 10)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Done',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4ECDC4),
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
                    // Progress Circle
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(categoryColor),
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        if (goal.deadline != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                '${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(categoryColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
