import 'category_model.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    this.category,
    required this.amount,
    required this.spent,
    required this.period,
    required this.month,
    required this.year,
  });
  final int id;
  final CategoryModel? category;
  final double amount;
  final double spent;
  final String period;
  final int month;
  final int year;
  double get remaining => amount - spent;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] ?? 0,
    category: json['category'] is Map
        ? CategoryModel.fromJson(Map<String, dynamic>.from(json['category']))
        : null,
    amount: _d(json['amount']),
    spent: _d(json['spent']),
    period: json['period'] ?? 'monthly',
    month: json['month'] ?? 1,
    year: json['year'] ?? DateTime.now().year,
  );

  static double _d(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
