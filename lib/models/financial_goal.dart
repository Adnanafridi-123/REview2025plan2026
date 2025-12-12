import 'package:hive/hive.dart';

part 'financial_goal.g.dart';

@HiveType(typeId: 11)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String type; // 'savings', 'investment', 'debt_payoff', 'emergency_fund', 'purchase', 'income'
  
  @HiveField(3)
  double targetAmount;
  
  @HiveField(4)
  double currentAmount;
  
  @HiveField(5)
  String currency;
  
  @HiveField(6)
  DateTime deadline;
  
  @HiveField(7)
  String priority; // High, Medium, Low
  
  @HiveField(8)
  String notes;
  
  @HiveField(9)
  List<FinancialTransaction> transactions;
  
  @HiveField(10)
  DateTime createdAt;
  
  @HiveField(11)
  bool isCompleted;
  
  @HiveField(12)
  DateTime? completedAt;
  
  @HiveField(13)
  int colorValue;
  
  @HiveField(14)
  String icon;

  FinancialGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0,
    this.currency = 'PKR',
    required this.deadline,
    this.priority = 'Medium',
    this.notes = '',
    List<FinancialTransaction>? transactions,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.colorValue = 0xFF4CAF50,
    this.icon = '💰',
  }) : transactions = transactions ?? [];
  
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
  
  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);
  
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;
  
  double get dailySavingsNeeded {
    if (daysRemaining <= 0) return remainingAmount;
    return remainingAmount / daysRemaining;
  }
  
  double get monthlySavingsNeeded {
    final monthsRemaining = daysRemaining / 30;
    if (monthsRemaining <= 0) return remainingAmount;
    return remainingAmount / monthsRemaining;
  }
  
  FinancialGoal copyWith({
    String? id,
    String? name,
    String? type,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    DateTime? deadline,
    String? priority,
    String? notes,
    List<FinancialTransaction>? transactions,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    int? colorValue,
    String? icon,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      transactions: transactions ?? List.from(this.transactions),
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
    );
  }
}

@HiveType(typeId: 12)
class FinancialTransaction extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  double amount;
  
  @HiveField(2)
  String type; // 'deposit', 'withdrawal'
  
  @HiveField(3)
  String note;
  
  @HiveField(4)
  DateTime date;

  FinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.note = '',
    required this.date,
  });
}

class FinancialGoalType {
  static const List<String> types = [
    'savings',
    'investment',
    'debt_payoff',
    'emergency_fund',
    'purchase',
    'income',
  ];
  
  static const Map<String, String> typeNames = {
    'savings': 'Savings Goal',
    'investment': 'Investment',
    'debt_payoff': 'Debt Payoff',
    'emergency_fund': 'Emergency Fund',
    'purchase': 'Major Purchase',
    'income': 'Income Goal',
  };
  
  static const Map<String, String> typeIcons = {
    'savings': '🏦',
    'investment': '📈',
    'debt_payoff': '💳',
    'emergency_fund': '🛡️',
    'purchase': '🛒',
    'income': '💵',
  };
  
  static const Map<String, int> typeColors = {
    'savings': 0xFF4CAF50,
    'investment': 0xFF2196F3,
    'debt_payoff': 0xFFFF5722,
    'emergency_fund': 0xFF9C27B0,
    'purchase': 0xFFFF9800,
    'income': 0xFF00BCD4,
  };
}

class Currency {
  static const List<String> currencies = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'INR'];
  
  static const Map<String, String> symbols = {
    'PKR': 'Rs',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': '﷼',
    'INR': '₹',
  };
}
