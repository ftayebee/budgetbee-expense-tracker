import 'transaction_model.dart';

class DashboardModel {
  const DashboardModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.recentTransactions,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<TransactionModel> recentTransactions;
  final List<Map<String, dynamic>> expenseByCategory;
  final List<Map<String, dynamic>> incomeByCategory;

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    totalIncome: _d(json['total_income']),
    totalExpense: _d(json['total_expense']),
    currentBalance: _d(json['current_balance']),
    monthlyIncome: _d(json['monthly_income']),
    monthlyExpense: _d(json['monthly_expense']),
    recentTransactions: _list(
      json['recent_transactions'],
    ).map((e) => TransactionModel.fromJson(e)).toList(),
    expenseByCategory: _list(json['expense_by_category']),
    incomeByCategory: _list(json['income_by_category']),
  );

  static double _d(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is Map && value['data'] is List) value = value['data'];
    return value is List
        ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
  }
}
