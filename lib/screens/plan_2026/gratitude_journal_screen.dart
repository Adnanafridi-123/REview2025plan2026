import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/gratitude_entry.dart';
import '../../widgets/beautiful_back_button.dart';

class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  late Box<GratitudeEntry> _gratitudeBox;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  final List<String> _moods = ['😢', '😔', '😐', '😊', '😄', '🥰', '🙏', '✨'];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(GratitudeEntryAdapter());
    }
    _gratitudeBox = await Hive.openBox<GratitudeEntry>('gratitude_entries');
    setState(() => _isLoading = false);
  }

  GratitudeEntry? _getTodayEntry() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _gratitudeBox.values.cast<GratitudeEntry?>().firstWhere(
      (e) => e != null && DateFormat('yyyy-MM-dd').format(e.date) == dateKey,
      orElse: () => null,
    );
  }

  int get _totalEntries => _gratitudeBox.length;
  int get _currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      final hasEntry = _gratitudeBox.values.any(
        (e) => DateFormat('yyyy-MM-dd').format(e.date) == dateKey,
      );
      
      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildStats(),
                    _buildDateSelector(),
                    Expanded(child: _buildContent()),
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
                  'Gratitude Journal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Rozana 3 cheezein jo shukar guzar hain',
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
            child: const Text('🙏', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(count: _totalEntries, label: 'Total Entries', icon: '📝'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(count: _currentStreak, label: 'Day Streak', icon: '🔥'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(count: _totalEntries * 3, label: 'Blessings', icon: '✨'),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Last 14 days
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 13 - index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                            DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                         DateFormat('yyyy-MM-dd').format(DateTime.now());
          final hasEntry = _gratitudeBox.values.any(
            (e) => DateFormat('yyyy-MM-dd').format(e.date) == DateFormat('yyyy-MM-dd').format(date),
          );
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).substring(0, 2),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFF7043) : Colors.white,
                    ),
                  ),
                  if (hasEntry)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF7043) : Colors.white.withValues(alpha: 0.5),
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

  Widget _buildContent() {
    final entry = _getTodayEntry();
    
    if (entry != null) {
      return _buildEntryView(entry);
    } else {
      return _buildAddEntryForm();
    }
  }

  Widget _buildEntryView(GratitudeEntry entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date & Mood Header
          Container(
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
                Text(entry.mood, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(entry.date),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy').format(entry.date),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showEditDialog(entry),
                  icon: const Icon(Icons.edit, color: Color(0xFFFF7043)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Gratitude Items
          _GratitudeCard(number: 1, text: entry.item1, color: const Color(0xFFFF7043)),
          _GratitudeCard(number: 2, text: entry.item2, color: const Color(0xFFFFA726)),
          _GratitudeCard(number: 3, text: entry.item3, color: const Color(0xFF4CAF50)),
          
          // Note
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Text('Note', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(entry.note!, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddEntryForm() {
    final item1Controller = TextEditingController();
    final item2Controller = TextEditingController();
    final item3Controller = TextEditingController();
    final noteController = TextEditingController();
    String selectedMood = '😊';

    return StatefulBuilder(
      builder: (context, setFormState) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Aaj ka mood:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _moods.map((mood) {
                      final isSelected = selectedMood == mood;
                      return GestureDetector(
                        onTap: () => setFormState(() => selectedMood = mood),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFE0B2) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? Border.all(color: const Color(0xFFFF9800), width: 2) : null,
                          ),
                          child: Text(mood, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Gratitude Items
            const Text(
              '🙏 Aaj mein in cheezon ka shukar guzar hoon:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            
            _GratitudeInputField(
              controller: item1Controller,
              number: 1,
              hintText: 'Pehli cheez...',
              color: const Color(0xFFFF7043),
            ),
            _GratitudeInputField(
              controller: item2Controller,
              number: 2,
              hintText: 'Doosri cheez...',
              color: const Color(0xFFFFA726),
            ),
            _GratitudeInputField(
              controller: item3Controller,
              number: 3,
              hintText: 'Teesri cheez...',
              color: const Color(0xFF4CAF50),
            ),
            
            // Optional Note
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Koi aur soch... (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.note, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Save Button
            ElevatedButton(
              onPressed: () {
                if (item1Controller.text.isEmpty ||
                    item2Controller.text.isEmpty ||
                    item3Controller.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all 3 gratitude items')),
                  );
                  return;
                }
                
                final entry = GratitudeEntry(
                  id: DateFormat('yyyy-MM-dd').format(_selectedDate),
                  date: _selectedDate,
                  item1: item1Controller.text,
                  item2: item2Controller.text,
                  item3: item3Controller.text,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                  mood: selectedMood,
                );
                
                _gratitudeBox.add(entry);
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Text('✨ '),
                        Text('Gratitude saved! Shukriya!'),
                      ],
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF7043),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🙏 ', style: TextStyle(fontSize: 18)),
                  Text('Save Gratitude', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(GratitudeEntry entry) {
    final item1Controller = TextEditingController(text: entry.item1);
    final item2Controller = TextEditingController(text: entry.item2);
    final item3Controller = TextEditingController(text: entry.item3);
    final noteController = TextEditingController(text: entry.note ?? '');
    String selectedMood = entry.mood;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Edit Gratitude', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Mood
                    const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _moods.map((mood) {
                        final isSelected = selectedMood == mood;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedMood = mood),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFE0B2) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(mood, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: item1Controller,
                      decoration: InputDecoration(
                        labelText: '1st Gratitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: item2Controller,
                      decoration: InputDecoration(
                        labelText: '2nd Gratitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: item3Controller,
                      decoration: InputDecoration(
                        labelText: '3rd Gratitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: () {
                        entry.item1 = item1Controller.text;
                        entry.item2 = item2Controller.text;
                        entry.item3 = item3Controller.text;
                        entry.note = noteController.text.isNotEmpty ? noteController.text : null;
                        entry.mood = selectedMood;
                        entry.save();
                        
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final String icon;

  const _StatItem({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _GratitudeCard extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _GratitudeCard({required this.number, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GratitudeInputField extends StatelessWidget {
  final TextEditingController controller;
  final int number;
  final String hintText;
  final Color color;

  const _GratitudeInputField({
    required this.controller,
    required this.number,
    required this.hintText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$number', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
