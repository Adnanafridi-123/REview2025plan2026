import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/goal.dart';
import '../../widgets/beautiful_back_button.dart';
import '../../widgets/gamification_widgets.dart';
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
  late AnimationController _celebrationController;
  final bool _showCelebration = false;
  
  final List<String> _categories = ['All', 'Career', 'Health', 'Finance', 'Personal', 'Learning'];
  final List<String> _statuses = ['Active', 'Completed', 'All'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      showCelebration: _showCelebration,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      final filteredGoals = _filterGoals(provider.goals);
                      final activeCount = provider.activeGoals.length;
                      final completedCount = provider.completedGoals.length;
                      final totalProgress = _calculateTotalProgress(provider.goals);
                      
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(AppTheme.screenPadding),
                        children: [
                          // Header with animated stats
                          _buildAnimatedHeader(activeCount, completedCount, totalProgress),
                          const SizedBox(height: 20),
                          
                          // Progress Overview Card
                          _buildProgressOverviewCard(provider),
                          const SizedBox(height: 20),
                          
                          // Smart Insights Card
                          _buildSmartInsightsCard(provider),
                          const SizedBox(height: 20),
                          
                          // Category Filter Pills
                          _buildCategoryFilters(),
                          const SizedBox(height: 12),
                          
                          // Status Filter Pills
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
          floatingActionButton: _buildFAB(),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(int activeCount, int completedCount, double totalProgress) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Goals Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(width: 10),
                Transform.scale(
                  scale: 1 + (_pulseController.value * 0.1),
                  child: const Text('🎯', style: TextStyle(fontSize: 26)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMiniStatBadge('$activeCount active', const Color(0xFF6C63FF)),
                const SizedBox(width: 10),
                _buildMiniStatBadge('$completedCount done', const Color(0xFF00C853)),
                const SizedBox(width: 10),
                _buildMiniStatBadge('${(totalProgress * 100).toInt()}% progress', Colors.orange),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard(AppProvider provider) {
    final goals = provider.goals;
    final categoryProgress = <String, double>{};
    
    for (var goal in goals) {
      final progress = goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0.0;
      if (categoryProgress.containsKey(goal.category)) {
        categoryProgress[goal.category] = (categoryProgress[goal.category]! + progress) / 2;
      } else {
        categoryProgress[goal.category] = progress;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      'Category-wise breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF636E72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (categoryProgress.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Add goals to see progress',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceEvenly,
              children: categoryProgress.entries.map((entry) {
                final color = AppTheme.categoryColors[entry.key] ?? AppTheme.primaryPurple;
                return ProgressRing(
                  progress: entry.value.clamp(0.0, 1.0),
                  size: 70,
                  color: color,
                  centerText: '${(entry.value * 100).toInt()}%',
                  subtitle: entry.key,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSmartInsightsCard(AppProvider provider) {
    final insights = _generateSmartInsights(provider);
    if (insights.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.15),
            const Color(0xFF764BA2).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb, color: Color(0xFF667EEA), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Smart Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight['emoji']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight['text']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Map<String, String>> _generateSmartInsights(AppProvider provider) {
    final insights = <Map<String, String>>[];
    final goals = provider.goals;
    final activeGoals = provider.activeGoals;
    final completedGoals = provider.completedGoals;
    
    if (goals.isEmpty) {
      insights.add({
        'emoji': '💡',
        'text': 'Start your 2026 journey by adding your first goal! Break big dreams into achievable milestones.',
      });
      return insights;
    }
    
    // Check for goals close to deadline
    final now = DateTime.now();
    final urgentGoals = activeGoals.where((g) {
      final daysLeft = g.deadline.difference(now).inDays;
      return daysLeft <= 7 && daysLeft >= 0;
    }).toList();
    
    if (urgentGoals.isNotEmpty) {
      insights.add({
        'emoji': '⏰',
        'text': '${urgentGoals.length} goal(s) due this week! Focus on "${urgentGoals.first.name}" to stay on track.',
      });
    }
    
    // Check success rate
    if (completedGoals.length >= 3) {
      final successRate = completedGoals.length / goals.length;
      if (successRate >= 0.7) {
        insights.add({
          'emoji': '🔥',
          'text': 'Amazing! You\'ve completed ${(successRate * 100).toInt()}% of your goals. Keep up the momentum!',
        });
      }
    }
    
    // Find best performing category
    final categorySuccess = <String, int>{};
    for (var goal in completedGoals) {
      categorySuccess[goal.category] = (categorySuccess[goal.category] ?? 0) + 1;
    }
    if (categorySuccess.isNotEmpty) {
      final bestCategory = categorySuccess.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add({
        'emoji': '🏆',
        'text': 'You\'re excelling in ${bestCategory.key}! Consider setting more challenging goals here.',
      });
    }
    
    // Check for slow progress goals
    final slowGoals = activeGoals.where((g) {
      final daysSinceCreated = now.difference(g.createdAt).inDays;
      final progress = g.targetValue > 0 ? g.currentValue / g.targetValue : 0;
      return daysSinceCreated > 14 && progress < 0.2;
    }).toList();
    
    if (slowGoals.isNotEmpty) {
      insights.add({
        'emoji': '💪',
        'text': '"${slowGoals.first.name}" needs attention. Break it into smaller milestones for better progress.',
      });
    }
    
    return insights.take(3).toList();
  }

  double _calculateTotalProgress(List<Goal> goals) {
    if (goals.isEmpty) return 0.0;
    double total = 0;
    for (var goal in goals) {
      total += goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0;
    }
    return (total / goals.length).clamp(0.0, 1.0);
  }

  List<Goal> _filterGoals(List<Goal> goals) {
    return goals.where((goal) {
      if (_selectedCategory != 'All' && goal.category != _selectedCategory) {
        return false;
      }
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

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          final color = category == 'All' 
              ? AppTheme.primaryPurple 
              : (AppTheme.categoryColors[category] ?? AppTheme.primaryPurple);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category != 'All') ...[
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52CC)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create First Goal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals, AppProvider provider) {
    return Column(
      children: goals.map((goal) {
        final progress = goal.targetValue > 0 
            ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0)
            : 0.0;
        final categoryColor = AppTheme.categoryColors[goal.category] ?? AppTheme.primaryPurple;
        final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
        final isUrgent = daysLeft <= 7 && daysLeft >= 0 && !goal.isCompleted;
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isUrgent ? Border.all(color: Colors.orange, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: goal.isCompleted 
                      ? Colors.green.withValues(alpha: 0.2)
                      : isUrgent 
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
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
                    // Animated category icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getCategoryIcon(goal.category),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3436),
                              decoration: goal.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildTag(goal.category, categoryColor),
                              _buildTag(goal.priority, _getPriorityColor(goal.priority)),
                              if (goal.isCompleted)
                                _buildTag('Completed', Colors.green),
                              if (isUrgent)
                                _buildTag('$daysLeft days left!', Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Progress ring
                    SizedBox(
                      width: 55,
                      height: 55,
                      child: Stack(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 5,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(
                                  goal.isCompleted ? Colors.green : categoryColor,
                                ),
                              );
                            },
                          ),
                          Center(
                            child: goal.isCompleted
                                ? const Icon(Icons.check, color: Colors.green, size: 24)
                                : Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: categoryColor,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar with animation
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: goal.isCompleted
                                      ? [Colors.green, Colors.green.shade300]
                                      : [categoryColor, categoryColor.withValues(alpha: 0.7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (goal.isCompleted ? Colors.green : categoryColor)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.currentValue == 1 ? 'unit' : 'units'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (goal.milestones.isNotEmpty) ...[
                          Icon(Icons.flag, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length} milestones',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                      ],
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Goal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
