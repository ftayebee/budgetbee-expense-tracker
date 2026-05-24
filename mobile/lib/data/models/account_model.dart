class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currentBalance,
    this.color,
    this.icon,
    this.isDefault = false,
  });
  final int id;
  final String name;
  final String type;
  final double openingBalance;
  final double currentBalance;
  final String? color;
  final String? icon;
  final bool isDefault;

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    type: json['type'] ?? 'cash',
    openingBalance: _d(json['opening_balance']),
    currentBalance: _d(json['current_balance']),
    color: json['color'],
    icon: json['icon'],
    isDefault: json['is_default'] == true,
  );

  static double _d(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
