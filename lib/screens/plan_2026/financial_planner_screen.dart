import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../widgets/beautiful_back_button.dart';
import '../../services/alarm_service.dart';

class FinancialPlannerScreen extends StatefulWidget {
  const FinancialPlannerScreen({super.key});

  @override
  State<FinancialPlannerScreen> createState() => _FinancialPlannerScreenState();
}

class _FinancialPlannerScreenState extends State<FinancialPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FinancialGoalItem> _goals = [];
  String _selectedCurrency = 'PKR';
  
  final Map<String, String> _currencySymbols = {
    'PKR': 'Rs',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': '﷼',
    'INR': '₹',
  };

  final List<Map<String, dynamic>> _goalTypes = [
    {'type': 'savings', 'name': 'Savings Goal', 'icon': Icons.savings, 'color': 0xFF4CAF50},
    {'type': 'investment', 'name': 'Investment', 'icon': Icons.trending_up, 'color': 0xFF2196F3},
    {'type': 'debt_payoff', 'name': 'Debt Payoff', 'icon': Icons.credit_card_off, 'color': 0xFFFF5722},
    {'type': 'emergency_fund', 'name': 'Emergency Fund', 'icon': Icons.shield, 'color': 0xFF9C27B0},
    {'type': 'purchase', 'name': 'Major Purchase', 'icon': Icons.shopping_bag, 'color': 0xFFFF9800},
    {'type': 'income', 'name': 'Income Goal', 'icon': Icons.attach_money, 'color': 0xFF00BCD4},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalTarget => _goals.fold(0, (sum, g) => sum + g.targetAmount);
  double get _totalSaved => _goals.fold(0, (sum, g) => sum + g.currentAmount);
  double get _overallProgress => _totalTarget > 0 ? (_totalSaved / _totalTarget * 100) : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSummaryCard(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGoalsTab(),
                    _buildAnalyticsTab(),
                    _buildTipsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Planner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Plan your financial success for 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          _buildCurrencySelector(),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          dropdownColor: const Color(0xFF16213e),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _currencySymbols.keys.map((currency) {
            return DropdownMenuItem(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCurrency = value!);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final symbol = _currencySymbols[_selectedCurrency] ?? 'Rs';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Saved',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$symbol ${_formatNumber(_totalSaved)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'of $symbol ${_formatNumber(_totalTarget)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_goals.length} goals',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 8,
            percent: (_overallProgress / 100).clamp(0, 1),
            center: Text(
              '${_overallProgress.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Goals'),
          Tab(text: 'Analytics'),
          Tab(text: 'Tips'),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    if (_goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(_goals[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 50,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Financial Goals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your financial future\nfor 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add First Goal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(FinancialGoalItem goal, int index) {
    final symbol = _currencySymbols[_selectedCurrency] ?? 'Rs';
    final typeInfo = _goalTypes.firstWhere(
      (t) => t['type'] == goal.type,
      orElse: () => _goalTypes.first,
    );
    final color = Color(typeInfo['color'] as int);
    final progress = goal.targetAmount > 0 
        ? (goal.currentAmount / goal.targetAmount * 100) 
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showGoalDetails(goal, index),
          onLongPress: () => _showGoalOptions(goal, index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        typeInfo['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            typeInfo['name'] as String,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                            ),
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
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${goal.daysRemaining} days left',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0, 1),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$symbol ${_formatNumber(goal.currentAmount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'of $symbol ${_formatNumber(goal.targetAmount)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Save $symbol ${_formatNumber(goal.monthlySavingsNeeded)}/month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_goals.isEmpty) {
      return Center(
        child: Text(
          'Add goals to see analytics',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
          const SizedBox(height: 32),
          const Text(
            'Monthly Savings Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._goals.map((goal) => _buildMonthlySavingsItem(goal)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final Map<String, double> typeAmounts = {};
    for (var goal in _goals) {
      typeAmounts[goal.type] = (typeAmounts[goal.type] ?? 0) + goal.targetAmount;
    }

    return typeAmounts.entries.map((entry) {
      final typeInfo = _goalTypes.firstWhere(
        (t) => t['type'] == entry.key,
        orElse: () => _goalTypes.first,
      );
      final percentage = _totalTarget > 0 ? (entry.value / _totalTarget * 100) : 0;
      
      return PieChartSectionData(
        color: Color(typeInfo['color'] as int),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final Map<String, double> typeAmounts = {};
    for (var goal in _goals) {
      typeAmounts[goal.type] = (typeAmounts[goal.type] ?? 0) + goal.targetAmount;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: typeAmounts.entries.map((entry) {
        final typeInfo = _goalTypes.firstWhere(
          (t) => t['type'] == entry.key,
          orElse: () => _goalTypes.first,
        );
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(typeInfo['color'] as int),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              typeInfo['name'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthlySavingsItem(FinancialGoalItem goal) {
    final symbol = _currencySymbols[_selectedCurrency] ?? 'Rs';
    final typeInfo = _goalTypes.firstWhere(
      (t) => t['type'] == goal.type,
      orElse: () => _goalTypes.first,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            typeInfo['icon'] as IconData,
            color: Color(typeInfo['color'] as int),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              goal.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            '$symbol ${_formatNumber(goal.monthlySavingsNeeded)}/mo',
            style: TextStyle(
              color: Color(typeInfo['color'] as int),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final tips = [
      {
        'icon': Icons.savings,
        'title': 'Pay Yourself First',
        'description': 'Automatically transfer savings before spending on anything else.',
        'color': 0xFF4CAF50,
      },
      {
        'icon': Icons.trending_down,
        'title': 'Track Every Expense',
        'description': 'Know where your money goes to find areas to cut back.',
        'color': 0xFFFF5722,
      },
      {
        'icon': Icons.account_balance,
        'title': 'Emergency Fund First',
        'description': 'Build 3-6 months of expenses before investing.',
        'color': 0xFF9C27B0,
      },
      {
        'icon': Icons.calculate,
        'title': '50/30/20 Rule',
        'description': '50% needs, 30% wants, 20% savings & investments.',
        'color': 0xFF2196F3,
      },
      {
        'icon': Icons.repeat,
        'title': 'Automate Savings',
        'description': 'Set up automatic transfers to savings accounts.',
        'color': 0xFF00BCD4,
      },
      {
        'icon': Icons.credit_card_off,
        'title': 'Avoid High-Interest Debt',
        'description': 'Pay off credit cards in full each month.',
        'color': 0xFFFF9800,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(tip['color'] as int).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(tip['color'] as int).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(tip['color'] as int).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tip['icon'] as IconData,
                  color: Color(tip['color'] as int),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['description'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddGoalDialog,
      backgroundColor: const Color(0xFF4CAF50),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Add Goal',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedType = 'savings';
    DateTime selectedDeadline = DateTime(2026, 12, 31);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add Financial Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintText: 'e.g., Emergency Fund, New Car',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.label_outline, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintText: 'e.g., 100000',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: Colors.white.withValues(alpha: 0.7)),
                    suffixText: _selectedCurrency,
                    suffixStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Goal Type',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goalTypes.map((type) {
                    final isSelected = selectedType == type['type'];
                    final color = Color(type['color'] as int);
                    
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type['type'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type['name'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDeadline = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Text(
                          'Deadline: ${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                        final target = double.tryParse(targetController.text) ?? 0;
                        setState(() {
                          _goals.add(FinancialGoalItem(
                            name: nameController.text,
                            type: selectedType,
                            targetAmount: target,
                            currentAmount: 0,
                            deadline: selectedDeadline,
                          ));
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Goal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGoalDetails(FinancialGoalItem goal, int index) {
    final symbol = _currencySymbols[_selectedCurrency] ?? 'Rs';
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $symbol ${_formatNumber(goal.currentAmount)} / $symbol ${_formatNumber(goal.targetAmount)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Add Amount',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintText: 'Enter amount to add',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixText: '$symbol ',
                prefixStyle: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        setState(() {
                          goal.currentAmount += amount;
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Savings', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalOptions(FinancialGoalItem goal, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: const Text('Edit Goal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Edit goal
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Goal', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                setState(() => _goals.removeAt(index));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}

class FinancialGoalItem {
  final String name;
  final String type;
  final double targetAmount;
  double currentAmount;
  final DateTime deadline;

  FinancialGoalItem({
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;
  
  double get monthlySavingsNeeded {
    final monthsRemaining = daysRemaining / 30;
    final remaining = targetAmount - currentAmount;
    if (monthsRemaining <= 0 || remaining <= 0) return 0;
    return remaining / monthsRemaining;
  }
}
