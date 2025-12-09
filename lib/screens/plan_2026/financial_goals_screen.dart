import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/financial_goal.dart';
import '../../widgets/beautiful_back_button.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  late Box<FinancialGoal> _goalsBox;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Savings', 'icon': '💰', 'color': Color(0xFF4CAF50)},
    {'name': 'Emergency', 'icon': '🆘', 'color': Color(0xFFFF5722)},
    {'name': 'Investment', 'icon': '📈', 'color': Color(0xFF2196F3)},
    {'name': 'Debt', 'icon': '💳', 'color': Color(0xFFE91E63)},
    {'name': 'Travel', 'icon': '✈️', 'color': Color(0xFF9C27B0)},
    {'name': 'Education', 'icon': '📚', 'color': Color(0xFFFFC107)},
  ];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(FinancialGoalAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SavingsEntryAdapter());
    }
    _goalsBox = await Hive.openBox<FinancialGoal>('financial_goals');
    setState(() => _isLoading = false);
  }

  double get _totalSaved => _goalsBox.values.fold(0.0, (sum, g) => sum + g.currentAmount);
  double get _totalTarget => _goalsBox.values.fold(0.0, (sum, g) => sum + g.targetAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildSummaryCard(),
                    Expanded(child: _buildGoalsList()),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Color(0xFF11998e)),
        label: const Text('Add Goal', style: TextStyle(color: Color(0xFF11998e), fontWeight: FontWeight.bold)),
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
                  'Financial Goals',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Apne paise ka hisaab rakhein',
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
            child: const Text('💰', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final progress = _totalTarget > 0 ? (_totalSaved / _totalTarget * 100) : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Saved', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${NumberFormat('#,##0').format(_totalSaved)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF11998e)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${NumberFormat('#,##0').format(_totalTarget)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF11998e)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(1)}% complete',
            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    final goals = _goalsBox.values.toList();
    
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Koi financial goal nahi hai',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Apna pehla savings goal add karein',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) => _buildGoalCard(goals[index]),
    );
  }

  Widget _buildGoalCard(FinancialGoal goal) {
    final catData = _categories.firstWhere(
      (c) => c['name'] == goal.category,
      orElse: () => _categories[0],
    );
    final progress = goal.progressPercent;

    return GestureDetector(
      onTap: () => _showGoalDetails(goal),
      onLongPress: () => _showDeleteDialog(goal),
      child: Container(
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (catData['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(goal.icon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (catData['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              goal.category,
                              style: TextStyle(fontSize: 10, color: catData['color'] as Color),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${goal.daysRemaining} din baki',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: progress >= 100 ? Colors.green : catData['color'] as Color,
                      ),
                    ),
                    if (progress >= 100)
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 100 ? Colors.green : catData['color'] as Color,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${NumberFormat('#,##0').format(goal.currentAmount)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF11998e)),
                ),
                Text(
                  'of PKR ${NumberFormat('#,##0').format(goal.targetAmount)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedCategory = 'Savings';
    String selectedIcon = '💰';
    DateTime targetDate = DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                    const Text('Add Financial Goal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        hintText: 'e.g., Emergency Fund, Vacation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target Amount
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Amount (PKR)',
                        hintText: 'e.g., 100000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = selectedCategory == cat['name'];
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            selectedCategory = cat['name'];
                            selectedIcon = cat['icon'];
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? cat['color'] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat['icon']),
                                const SizedBox(width: 4),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target Date
                    const Text('Target Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setModalState(() => targetDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(DateFormat('d MMMM yyyy').format(targetDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Add Button
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty || targetController.text.isEmpty) return;
                        
                        final goal = FinancialGoal(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          targetAmount: double.tryParse(targetController.text) ?? 0,
                          startDate: DateTime.now(),
                          targetDate: targetDate,
                          category: selectedCategory,
                          icon: selectedIcon,
                        );
                        
                        _goalsBox.add(goal);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11998e),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Goal', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  void _showGoalDetails(FinancialGoal goal) {
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(goal.category, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saved', style: TextStyle(fontSize: 12)),
                    Text(
                      'PKR ${NumberFormat('#,##0').format(goal.currentAmount)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF11998e)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Remaining', style: TextStyle(fontSize: 12)),
                    Text(
                      'PKR ${NumberFormat('#,##0').format(goal.remainingAmount)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Add Money
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Add Money (PKR)',
                hintText: 'Enter amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        goal.currentAmount += amount;
                        goal.entries.add(SavingsEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amount,
                          date: DateTime.now(),
                          isDeposit: true,
                        ));
                        goal.save();
                        Navigator.pop(context);
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PKR ${NumberFormat('#,##0').format(amount)} added!'),
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0 && goal.currentAmount >= amount) {
                        goal.currentAmount -= amount;
                        goal.entries.add(SavingsEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amount,
                          date: DateTime.now(),
                          isDeposit: false,
                        ));
                        goal.save();
                        Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Kya aap "${goal.title}" ko delete karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              goal.delete();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
