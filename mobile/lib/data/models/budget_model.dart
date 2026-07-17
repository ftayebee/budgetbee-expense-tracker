import 'category_model.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    this.name = 'Budget',
    this.category,
    required this.amount,
    required this.spent,
    required this.period,
    required this.month,
    required this.year,
    this.startDate,
    this.endDate,
    this.alertThreshold = 80,
  });
  final int id;
  final String name;
  final CategoryModel? category;
  final double amount;
  final double spent;
  final String period;
  final int month;
  final int year;
  final DateTime? startDate;
  final DateTime? endDate;
  final int alertThreshold;
  double get remaining => amount - spent;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? 'Budget',
    category: json['category'] is Map
        ? CategoryModel.fromJson(Map<String, dynamic>.from(json['category']))
        : null,
    amount: _d(json['amount']),
    spent: _d(json['spent']),
    period: json['period'] ?? 'monthly',
    month: json['month'] ?? 1,
    year: json['year'] ?? DateTime.now().year,
    startDate:
        DateTime.tryParse('${json['start_date'] ?? ''}') ??
        DateTime(
          json['year'] ?? DateTime.now().year,
          json['month'] ?? DateTime.now().month,
        ),
    endDate: DateTime.tryParse('${json['end_date'] ?? ''}'),
    alertThreshold: json['alert_threshold'] ?? 80,
  );

  static double _d(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
