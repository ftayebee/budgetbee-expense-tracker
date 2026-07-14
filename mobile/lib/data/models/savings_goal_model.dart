class GoalContributionModel {
  const GoalContributionModel({
    required this.id,
    required this.amount,
    this.note,
    this.contributedAt,
  });

  final int id;
  final double amount;
  final String? note;
  final String? contributedAt;

  factory GoalContributionModel.fromJson(Map<String, dynamic> json) =>
      GoalContributionModel(
        id: json['id'] ?? 0,
        amount: _d(json['amount']),
        note: json['note'],
        contributedAt: json['contributed_at'],
      );
}

class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.progress,
    required this.status,
    this.targetDate,
    this.monthlyContributionNeeded,
    this.accountId,
    this.icon,
    this.color,
    this.contributions = const [],
  });

  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final double progress; // 0..100
  final String status; // active | completed | cancelled
  final String? targetDate;
  final double? monthlyContributionNeeded;
  final int? accountId;
  final String? icon;
  final String? color;
  final List<GoalContributionModel> contributions;

  bool get isCompleted => status == 'completed';

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        targetAmount: _d(json['target_amount']),
        currentAmount: _d(json['current_amount']),
        remainingAmount: _d(json['remaining_amount']),
        progress: _d(json['progress']),
        status: json['status'] ?? 'active',
        targetDate: json['target_date'],
        monthlyContributionNeeded: json['monthly_contribution_needed'] == null
            ? null
            : _d(json['monthly_contribution_needed']),
        accountId: json['account_id'],
        icon: json['icon'],
        color: json['color'],
        contributions: json['contributions'] is List
            ? (json['contributions'] as List)
                  .map(
                    (e) => GoalContributionModel.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList()
            : const [],
      );
}

double _d(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
