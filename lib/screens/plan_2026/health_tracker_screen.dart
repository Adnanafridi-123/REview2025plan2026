import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/health_record.dart';
import '../../widgets/beautiful_back_button.dart';

class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({super.key});

  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  late Box<HealthRecord> _healthBox;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  HealthRecord? _todayRecord;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    _healthBox = await Hive.openBox<HealthRecord>('health_records');
    _loadTodayRecord();
    setState(() => _isLoading = false);
  }

  void _loadTodayRecord() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _todayRecord = _healthBox.values.cast<HealthRecord?>().firstWhere(
      (r) => r != null && DateFormat('yyyy-MM-dd').format(r.date) == dateKey,
      orElse: () => null,
    );
    
    if (_todayRecord == null) {
      _todayRecord = HealthRecord(
        id: dateKey,
        date: _selectedDate,
      );
      _healthBox.add(_todayRecord!);
    }
  }

  void _updateRecord() {
    _todayRecord?.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildDateSelector(),
                    _buildHealthScore(),
                    Expanded(child: _buildTrackers()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Tracker',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Apni sehat ka khayal rakhein',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🏃', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                            DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                         DateFormat('yyyy-MM-dd').format(DateTime.now());
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _loadTodayRecord();
              });
            },
            child: Container(
              width: 55,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF00C9FF) : Colors.white,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00C9FF) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthScore() {
    final score = _todayRecord?.healthScore ?? 0;
    Color scoreColor;
    String scoreText;
    
    if (score >= 80) {
      scoreColor = const Color(0xFF4CAF50);
      scoreText = 'Excellent! 💪';
    } else if (score >= 60) {
      scoreColor = const Color(0xFF8BC34A);
      scoreText = 'Good! 👍';
    } else if (score >= 40) {
      scoreColor = const Color(0xFFFFC107);
      scoreText = 'Average 🤔';
    } else {
      scoreColor = const Color(0xFFFF5722);
      scoreText = 'Need Improvement 😅';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(scoreText, style: TextStyle(fontSize: 14, color: scoreColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackers() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        // Water Tracker
        _TrackerCard(
          emoji: '💧',
          title: 'Paani',
          subtitle: '${_todayRecord?.waterGlasses ?? 0}/8 glasses',
          value: (_todayRecord?.waterGlasses ?? 0).toDouble(),
          maxValue: 8,
          color: const Color(0xFF2196F3),
          onIncrease: () {
            if ((_todayRecord?.waterGlasses ?? 0) < 12) {
              _todayRecord?.waterGlasses = (_todayRecord?.waterGlasses ?? 0) + 1;
              _updateRecord();
            }
          },
          onDecrease: () {
            if ((_todayRecord?.waterGlasses ?? 0) > 0) {
              _todayRecord?.waterGlasses = (_todayRecord?.waterGlasses ?? 0) - 1;
              _updateRecord();
            }
          },
        ),
        
        // Sleep Tracker
        _TrackerCard(
          emoji: '😴',
          title: 'Neend',
          subtitle: '${_todayRecord?.sleepHours.toStringAsFixed(1) ?? 0} hours',
          value: _todayRecord?.sleepHours ?? 0,
          maxValue: 10,
          color: const Color(0xFF9C27B0),
          onIncrease: () {
            if ((_todayRecord?.sleepHours ?? 0) < 12) {
              _todayRecord?.sleepHours = (_todayRecord?.sleepHours ?? 0) + 0.5;
              _updateRecord();
            }
          },
          onDecrease: () {
            if ((_todayRecord?.sleepHours ?? 0) > 0) {
              _todayRecord?.sleepHours = (_todayRecord?.sleepHours ?? 0) - 0.5;
              _updateRecord();
            }
          },
        ),
        
        // Exercise Tracker
        _TrackerCard(
          emoji: '🏋️',
          title: 'Exercise',
          subtitle: '${_todayRecord?.exerciseMinutes ?? 0} minutes',
          value: (_todayRecord?.exerciseMinutes ?? 0).toDouble(),
          maxValue: 60,
          color: const Color(0xFFFF5722),
          onIncrease: () {
            if ((_todayRecord?.exerciseMinutes ?? 0) < 180) {
              _todayRecord?.exerciseMinutes = (_todayRecord?.exerciseMinutes ?? 0) + 10;
              _updateRecord();
            }
          },
          onDecrease: () {
            if ((_todayRecord?.exerciseMinutes ?? 0) > 0) {
              _todayRecord?.exerciseMinutes = (_todayRecord?.exerciseMinutes ?? 0) - 10;
              _updateRecord();
            }
          },
        ),
        
        // Steps Tracker
        _TrackerCard(
          emoji: '👟',
          title: 'Qadam',
          subtitle: '${_todayRecord?.steps ?? 0} steps',
          value: (_todayRecord?.steps ?? 0).toDouble(),
          maxValue: 10000,
          color: const Color(0xFF4CAF50),
          onIncrease: () {
            _todayRecord?.steps = (_todayRecord?.steps ?? 0) + 500;
            _updateRecord();
          },
          onDecrease: () {
            if ((_todayRecord?.steps ?? 0) > 0) {
              _todayRecord?.steps = (_todayRecord?.steps ?? 0) - 500;
              _updateRecord();
            }
          },
        ),
        
        // Mood Tracker
        _buildMoodTracker(),
        
        // Weight Tracker
        _buildWeightTracker(),
      ],
    );
  }

  Widget _buildMoodTracker() {
    final moods = [
      {'emoji': '😢', 'score': 1, 'label': 'Sad'},
      {'emoji': '😔', 'score': 2, 'label': 'Low'},
      {'emoji': '😐', 'score': 3, 'label': 'Okay'},
      {'emoji': '😊', 'score': 4, 'label': 'Good'},
      {'emoji': '😄', 'score': 5, 'label': 'Great'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎭', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text('Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              final isSelected = _todayRecord?.moodScore == mood['score'];
              return GestureDetector(
                onTap: () {
                  _todayRecord?.moodScore = mood['score'] as int;
                  _updateRecord();
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFE0B2) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: const Color(0xFFFF9800), width: 2) : null,
                      ),
                      child: Text(mood['emoji'] as String, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? const Color(0xFFFF9800) : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTracker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              const Text('Wazan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_todayRecord?.weight != null)
                Text(
                  '${_todayRecord?.weight?.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C9FF)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _todayRecord?.weight ?? 60,
                  min: 30,
                  max: 150,
                  divisions: 240,
                  activeColor: const Color(0xFF00C9FF),
                  onChanged: (value) {
                    _todayRecord?.weight = value;
                    _updateRecord();
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30 kg', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('150 kg', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

// Tracker Card Widget
class _TrackerCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double value;
  final double maxValue;
  final Color color;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _TrackerCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (value / maxValue).clamp(0, 1),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _CounterButton(icon: Icons.add, onTap: onIncrease, color: color),
              const SizedBox(height: 8),
              _CounterButton(icon: Icons.remove, onTap: onDecrease, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CounterButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
