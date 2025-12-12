import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/alarm_service.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '100');
  
  String _selectedCategory = 'Career';
  String _selectedPriority = 'Medium';
  DateTime _deadline = DateTime(2026, 12, 31);
  
  // 🔔 Reminder Settings
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Career', 'icon': '💼', 'color': 0xFF4ECDC4},
    {'name': 'Health', 'icon': '💪', 'color': 0xFFFF6B6B},
    {'name': 'Finance', 'icon': '💰', 'color': 0xFFFFE66D},
    {'name': 'Personal', 'icon': '🎯', 'color': 0xFF9B59B6},
    {'name': 'Learning', 'icon': '📚', 'color': 0xFF3498DB},
  ];
  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
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
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 🔥 Hero Header
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    
                    // 📝 Goal Name
                    _buildProSection('🎯 Goal Name', _buildProTextField(
                      controller: _nameController,
                      hint: 'e.g., Learn Flutter Development',
                      icon: Icons.edit,
                    )),
                    const SizedBox(height: 20),
                    
                    // 📂 Category
                    _buildProSection('📂 Category', _buildProCategorySelector()),
                    const SizedBox(height: 20),
                    
                    // ⚡ Priority
                    _buildProSection('⚡ Priority', _buildProPrioritySelector()),
                    const SizedBox(height: 20),
                    
                    // 🎯 Target Value
                    _buildProSection('🎯 Target Value', _buildProTextField(
                      controller: _targetController,
                      hint: '100',
                      icon: Icons.flag,
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(height: 20),
                    
                    // 📅 Deadline with Date
                    _buildProSection('📅 Deadline', _buildProDeadlinePicker()),
                    const SizedBox(height: 20),
                    
                    // 🔔 Reminder Settings
                    _buildProSection('🔔 Daily Reminder', _buildReminderSettings()),
                    const SizedBox(height: 32),
                    
                    // ✅ Create Button
                    _buildCreateButton(),
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
  
  Widget _buildHeroHeader() {
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Goal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Define your target for 2026 ✨',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
  
  Widget _buildProTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(icon, color: const Color(0xFF667eea), size: 20),
        ),
      ),
    );
  }

  Widget _buildProCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat['name'];
        final color = Color(cat['color'] as int);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat['icon'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProPrioritySelector() {
    final priorityData = [
      {'name': 'High', 'icon': '🔴', 'color': 0xFFFF6B6B},
      {'name': 'Medium', 'icon': '🟡', 'color': 0xFFFFE66D},
      {'name': 'Low', 'icon': '🟢', 'color': 0xFF4ECDC4},
    ];
    
    return Row(
      children: priorityData.map((p) {
        final isSelected = _selectedPriority == p['name'];
        final color = Color(p['color'] as int);
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p['name'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: p['name'] != 'Low' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                  Text(p['icon'] as String, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    p['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
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

  Widget _buildProDeadlinePicker() {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(_deadline);
    final daysLeft = _deadline.difference(DateTime.now()).inDays;
    
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
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF667eea),
                  surface: Color(0xFF1a1a2e),
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
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFee5a52)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: daysLeft > 30 
                              ? const Color(0xFF4ECDC4).withOpacity(0.2)
                              : const Color(0xFFFF6B6B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⏳ $daysLeft days left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: daysLeft > 30 ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReminderSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _reminderEnabled 
                ? const Color(0xFF667eea).withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            _reminderEnabled 
                ? const Color(0xFF764ba2).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _reminderEnabled 
              ? const Color(0xFF667eea).withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Enable/Disable Toggle
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _reminderEnabled 
                      ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                      : null,
                  color: _reminderEnabled ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: _reminderEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Reminder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _reminderEnabled ? 'Notification with sound' : 'Tap to enable',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
                activeColor: const Color(0xFF667eea),
              ),
            ],
          ),
          
          // 🕐 Custom Time Picker with AM/PM (shown when enabled)
          if (_reminderEnabled) ...[
            const SizedBox(height: 16),
            
            // ⏰ Beautiful Time Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFE66D).withOpacity(0.2),
                    const Color(0xFFf0c020).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE66D).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm, color: Color(0xFFFFE66D), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Set Reminder Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFE66D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 🎯 Time Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour Selector
                      _buildTimeScrollSelector(
                        value: _reminderTime.hourOfPeriod == 0 ? 12 : _reminderTime.hourOfPeriod,
                        label: 'Hour',
                        onTap: () => _showHourPicker(),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Minute Selector
                      _buildTimeScrollSelector(
                        value: _reminderTime.minute,
                        label: 'Min',
                        isMinute: true,
                        onTap: () => _showMinutePicker(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // AM/PM Toggle
                      _buildAMPMSelector(),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notification with sound at ${_formatTimeWithAMPM(_reminderTime)} daily',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTimeWithAMPM(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  
  // 🎯 Time Scroll Selector Widget
  Widget _buildTimeScrollSelector({
    required int value,
    required String label,
    required VoidCallback onTap,
    bool isMinute = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isMinute ? value.toString().padLeft(2, '0') : value.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  // 🌅 AM/PM Selector Widget
  Widget _buildAMPMSelector() {
    final isAM = _reminderTime.hour < 12;
    return Column(
      children: [
        // AM Button
        GestureDetector(
          onTap: () {
            if (!isAM) {
              setState(() {
                _reminderTime = TimeOfDay(
                  hour: _reminderTime.hour - 12,
                  minute: _reminderTime.minute,
                );
              });
            }
          },
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isAM 
                  ? const LinearGradient(colors: [Color(0xFFFFE66D), Color(0xFFf0c020)])
                  : null,
              color: isAM ? null : Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(
                color: isAM ? Colors.transparent : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                'AM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isAM ? const Color(0xFF1a1a2e) : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        // PM Button
        GestureDetector(
          onTap: () {
            if (isAM) {
              setState(() {
                _reminderTime = TimeOfDay(
                  hour: _reminderTime.hour + 12,
                  minute: _reminderTime.minute,
                );
              });
            }
          },
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: !isAM 
                  ? const LinearGradient(colors: [Color(0xFF764ba2), Color(0xFF667eea)])
                  : null,
              color: !isAM ? null : Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(
                color: !isAM ? Colors.transparent : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                'PM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: !isAM ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // 🕐 Hour Picker Dialog
  void _showHourPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏰ Select Hour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final hour = index + 1;
                  final currentHour = _reminderTime.hourOfPeriod == 0 ? 12 : _reminderTime.hourOfPeriod;
                  final isSelected = hour == currentHour;
                  return GestureDetector(
                    onTap: () {
                      final isAM = _reminderTime.hour < 12;
                      int newHour;
                      if (hour == 12) {
                        newHour = isAM ? 0 : 12;
                      } else {
                        newHour = isAM ? hour : hour + 12;
                      }
                      setState(() {
                        _reminderTime = TimeOfDay(hour: newHour, minute: _reminderTime.minute);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFFFFE66D), Color(0xFFf0c020)])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hour.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // ⏱️ Minute Picker Dialog
  void _showMinutePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⏱️ Select Minutes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final minute = index * 5;
                  final isSelected = minute == _reminderTime.minute;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _reminderTime = TimeOfDay(hour: _reminderTime.hour, minute: minute);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _createGoal,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Create Goal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'With Reminder',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _createGoal() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text('Please enter a goal name'),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    final targetValue = double.tryParse(_targetController.text) ?? 100;
    final reminderTimeStr = _reminderEnabled 
        ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
        : null;
    
    // Add goal
    context.read<AppProvider>().addGoal(
      name: _nameController.text,
      category: _selectedCategory,
      description: _descriptionController.text,
      targetValue: targetValue,
      deadline: _deadline,
      priority: _selectedPriority,
      reminderTime: reminderTimeStr,
      reminderEnabled: _reminderEnabled,
    );
    
    // Schedule alarm if reminder is enabled
    if (_reminderEnabled) {
      final goalId = DateTime.now().millisecondsSinceEpoch.toString();
      await AlarmService().scheduleGoalReminder(
        goalId: goalId,
        goalName: _nameController.text,
        category: _selectedCategory,
        time: _reminderTime,
        deadline: _deadline,
      );
      
      // Also schedule deadline alert
      await AlarmService().scheduleDeadlineAlert(
        goalId: goalId,
        goalName: _nameController.text,
        deadline: _deadline,
      );
    }
    
    if (!mounted) return;
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _reminderEnabled 
                    ? 'Goal created with reminder at ${_formatTimeWithAMPM(_reminderTime)}!'
                    : 'Goal created successfully!',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
