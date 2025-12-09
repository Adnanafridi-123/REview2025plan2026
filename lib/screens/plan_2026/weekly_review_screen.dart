import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key});

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
                    final reviews = provider.weeklyReviews;
                    final activeGoals = provider.activeGoals.length;
                    final completedGoals = provider.completedGoals.length;
                    
                    // Calculate days left in week
                    final now = DateTime.now();
                    final weekday = now.weekday;
                    final daysLeftInWeek = 7 - weekday;
                    
                    // Week ending date (Sunday)
                    final weekEnding = now.add(Duration(days: daysLeftInWeek));
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header - EXACT from video
                        const Text(
                          'Weekly Review',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          'Reflect on your progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Week Stats Card - EXACT from video (Pink/Red gradient)
                        _buildWeekStatsCard(weekEnding, activeGoals, completedGoals, daysLeftInWeek),
                        const SizedBox(height: 24),
                        
                        // Reviews List or Empty State
                        if (reviews.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildReviewsList(reviews),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // FAB - EXACT from video: "+ New Review" with pink gradient
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNewReviewDialog(context),
          backgroundColor: AppTheme.primaryPink,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Review',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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

  // Week Stats Card - EXACT from video (Pink/Red gradient)
  Widget _buildWeekStatsCard(DateTime weekEnding, int activeGoals, int completedGoals, int daysLeft) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(weekEnding);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC407A).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week Ending',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Row - EXACT from video
          Row(
            children: [
              _buildStatItem(Icons.flag, '$activeGoals', 'Active Goals'),
              const SizedBox(width: 20),
              _buildStatItem(Icons.check_circle, '$completedGoals', 'Completed'),
              const SizedBox(width: 20),
              _buildStatItem(Icons.access_time, '$daysLeft', 'Days Left'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Empty State - EXACT from video
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Paper/Pencil icon - EXACT from video
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.rate_review,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // EXACT text from video
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your weekly reflection journey\nto track your growth!',
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

  // Reviews List
  Widget _buildReviewsList(List reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Past Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.map((review) {
          final formattedDate = DateFormat('MMM d, yyyy').format(review.weekEnding);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week of $formattedDate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.wentWell.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildReviewSection('What went well', review.wentWell, Colors.green),
                ],
                if (review.challenges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReviewSection('Challenges', review.challenges, Colors.orange),
                ],
                if (review.nextWeekFocus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReviewSection('Next week focus', review.nextWeekFocus, Colors.blue),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewSection(String title, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New Review Dialog
  void _showNewReviewDialog(BuildContext context) {
    final wentWellController = TextEditingController();
    final challengesController = TextEditingController();
    final nextWeekController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              // Handle bar
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
              
              // Title
              const Text(
                'Weekly Review',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              Text(
                'Reflect on your week',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),

              // What went well
              _buildInputField(
                controller: wentWellController,
                label: 'What went well?',
                hint: 'Describe your wins this week...',
                icon: Icons.thumb_up,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Challenges
              _buildInputField(
                controller: challengesController,
                label: 'Challenges faced',
                hint: 'What obstacles did you encounter?',
                icon: Icons.warning_amber,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 16),

              // Next week focus
              _buildInputField(
                controller: nextWeekController,
                label: 'Next week focus',
                hint: 'What will you prioritize?',
                icon: Icons.flag,
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 24),

              // Save button
              GestureDetector(
                onTap: () {
                  if (wentWellController.text.isNotEmpty ||
                      challengesController.text.isNotEmpty ||
                      nextWeekController.text.isNotEmpty) {
                    // Calculate week ending (next Sunday)
                    final now = DateTime.now();
                    final daysUntilSunday = 7 - now.weekday;
                    final weekEnding = now.add(Duration(days: daysUntilSunday));
                    
                    context.read<AppProvider>().addWeeklyReview(
                      weekEnding: weekEnding,
                      wentWell: wentWellController.text,
                      challenges: challengesController.text,
                      nextWeekFocus: nextWeekController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Review saved!'),
                        backgroundColor: AppTheme.primaryPink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
