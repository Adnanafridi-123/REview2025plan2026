import 'package:hive/hive.dart';

part 'financial_goal.g.dart';

@HiveType(typeId: 12)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title; // e.g., "Emergency Fund", "Vacation Fund"

  @HiveField(2)
  double targetAmount; // Target amount to save

  @HiveField(3)
  double currentAmount; // Current saved amount

  @HiveField(4)
  String currency; // PKR, USD, etc.

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime targetDate;

  @HiveField(7)
  String category; // Savings, Investment, Debt, Emergency

  @HiveField(8)
  String? description;

  @HiveField(9)
  List<SavingsEntry> entries;

  @HiveField(10)
  bool isCompleted;

  @HiveField(11)
  String icon; // emoji icon

  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.currency = 'PKR',
    required this.startDate,
    required this.targetDate,
    required this.category,
    this.description,
    List<SavingsEntry>? entries,
    this.isCompleted = false,
    this.icon = '💰',
  }) : entries = entries ?? [];

  double get progressPercent => 
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  double get dailySavingsNeeded {
    if (daysRemaining <= 0) return remainingAmount;
    return remainingAmount / daysRemaining;
  }
}

@HiveType(typeId: 13)
class SavingsEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  @HiveField(4)
  bool isDeposit; // true = deposit, false = withdrawal

  SavingsEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.isDeposit = true,
  });
}
