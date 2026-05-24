class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isDefault = false,
  });
  final int id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDefault;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    type: json['type'] ?? 'expense',
    icon: json['icon'],
    color: json['color'],
    isDefault: json['is_default'] == true,
  );
}
