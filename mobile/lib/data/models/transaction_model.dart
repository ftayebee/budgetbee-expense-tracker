import 'account_model.dart';
import 'category_model.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.note,
    this.paymentMethod,
    this.account,
    this.category,
    this.fromAccount,
    this.toAccount,
    this.createdAt,
  });
  final int id;
  final String title;
  final String type;
  final double amount;
  final DateTime transactionDate;
  final String? note;
  final String? paymentMethod;
  final AccountModel? account;
  final CategoryModel? category;
  final AccountModel? fromAccount;
  final AccountModel? toAccount;
  final DateTime? createdAt;

  factory TransactionModel.fromJson(
    Map<String, dynamic> json,
  ) => TransactionModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    type: json['type'] ?? 'expense',
    amount: _d(json['amount']),
    transactionDate:
        DateTime.tryParse(json['transaction_date'] ?? '') ?? DateTime.now(),
    note: json['note'],
    paymentMethod: json['payment_method'],
    account: json['account'] is Map
        ? AccountModel.fromJson(Map<String, dynamic>.from(json['account']))
        : null,
    category: json['category'] is Map
        ? CategoryModel.fromJson(Map<String, dynamic>.from(json['category']))
        : null,
    fromAccount: json['from_account'] is Map
        ? AccountModel.fromJson(Map<String, dynamic>.from(json['from_account']))
        : null,
    toAccount: json['to_account'] is Map
        ? AccountModel.fromJson(Map<String, dynamic>.from(json['to_account']))
        : null,
    createdAt: DateTime.tryParse(json['created_at'] ?? ''),
  );

  static double _d(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
