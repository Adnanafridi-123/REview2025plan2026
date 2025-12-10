import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated Fire Icon for Streaks
class StreakFireIcon extends StatefulWidget {
  final int streak;
  final double size;
  
  const StreakFireIcon({super.key, required this.streak, this.size = 40});
  
  @override
  State<StreakFireIcon> createState() => _StreakFireIconState();
}

class _StreakFireIconState extends State<StreakFireIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (widget.streak > 0)
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3 + (_controller.value * 0.2)),
                      blurRadius: 15 + (_controller.value * 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            // Fire icon
            Icon(
              Icons.local_fire_department,
              size: widget.size + (_controller.value * 4),
              color: widget.streak > 7 
                  ? Colors.orange 
                  : widget.streak > 3 
                      ? Colors.deepOrange 
                      : widget.streak > 0 
                          ? Colors.orange[700] 
                          : Colors.grey,
            ),
          ],
        );
      },
    );
  }
}

/// XP Progress Bar with Level
class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int xpForNextLevel;
  final int level;
  
  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.level,
  });
  
  @override
  Widget build(BuildContext context) {
    final progress = currentXP / xpForNextLevel;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.2),
            const Color(0xFF6C63FF).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5A52CC)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getLevelTitle(level),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP / $xpForNextLevel XP',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 10,
                width: MediaQuery.of(context).size.width * progress * 0.8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getLevelTitle(int level) {
    if (level >= 20) return '🏆 Legend';
    if (level >= 15) return '🌟 Champion';
    if (level >= 10) return '💎 Expert';
    if (level >= 5) return '🔥 Achiever';
    if (level >= 2) return '⭐ Starter';
    return '🌱 Beginner';
  }
}

/// Achievement Badge Widget
class AchievementBadge extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isEarned;
  final String description;
  
  const AchievementBadge({
    super.key,
    required this.emoji,
    required this.title,
    required this.isEarned,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEarned ? Colors.amber.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? Colors.amber : Colors.grey[300]!,
            width: isEarned ? 2 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 28,
                color: isEarned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isEarned ? const Color(0xFF2D3436) : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendar Heatmap Widget (Like GitHub contributions)
class CalendarHeatmap extends StatelessWidget {
  final Map<DateTime, int> data; // Date -> completion count
  final int weeks;
  
  const CalendarHeatmap({
    super.key,
    required this.data,
    this.weeks = 12,
  });
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeks * 7));
    
    return Container(
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
              const Text(
                'Activity Heatmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Less', Colors.grey[200]!),
                  _buildLegendItem('', const Color(0xFFAED581)),
                  _buildLegendItem('', const Color(0xFF8BC34A)),
                  _buildLegendItem('More', const Color(0xFF4CAF50)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(weeks, (weekIndex) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                      final count = data[DateTime(date.year, date.month, date.day)] ?? 0;
                      return _buildDayCell(count, date.isAfter(now));
                    }),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayCell(int count, bool isFuture) {
    Color color;
    if (isFuture) {
      color = Colors.grey[100]!;
    } else if (count == 0) {
      color = Colors.grey[200]!;
    } else if (count == 1) {
      color = const Color(0xFFAED581);
    } else if (count == 2) {
      color = const Color(0xFF8BC34A);
    } else {
      color = const Color(0xFF4CAF50);
    }
    
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        if (label.isNotEmpty && label != 'More')
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (label == 'More')
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }
}

/// Circular Progress Ring
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final String centerText;
  final String? subtitle;
  
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.color = const Color(0xFF6C63FF),
    required this.centerText,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(Colors.grey[200]),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerText,
                  style: TextStyle(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Motivational Quote Card
class MotivationalQuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  
  const MotivationalQuoteCard({
    super.key,
    required this.quote,
    required this.author,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.15),
            const Color(0xFF764BA2).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            color: Color(0xFF667EEA),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            quote,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2D3436),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— $author',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration Confetti Overlay
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final bool showCelebration;
  
  const CelebrationOverlay({
    super.key,
    required this.child,
    required this.showCelebration,
  });
  
  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    if (widget.showCelebration) {
      _startCelebration();
    }
  }
  
  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCelebration && !oldWidget.showCelebration) {
      _startCelebration();
    }
  }
  
  void _startCelebration() {
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ][random.nextInt(6)],
        speed: 0.5 + random.nextDouble() * 0.5,
        rotation: random.nextDouble() * 360,
      ));
    }
    _controller.forward(from: 0);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showCelebration)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(_particles, _controller.value),
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x, y;
  Color color;
  double speed;
  double rotation;
  
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
    required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  
  _ConfettiPainter(this.particles, this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color.withValues(alpha: 1 - progress);
      final x = particle.x * size.width;
      final y = (particle.y + progress * particle.speed) * size.height;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * 5);
      canvas.drawRect(
        const Rect.fromLTWH(-5, -2, 10, 4),
        paint,
      );
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Daily Tip Card
class DailyTipCard extends StatelessWidget {
  final String tip;
  final String category;
  
  const DailyTipCard({
    super.key,
    required this.tip,
    required this.category,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B09B).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
