import 'category_model.dart';

class BudgetModel {
  final int? id;
  final int categoryId;
  final double amount;
  final String month; // Format: 'YYYY-MM'
  
  // Loaded dynamically via SQL joins
  final CategoryModel? category;

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return BudgetModel(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      month: map['month'],
      category: category ?? (map['category_name'] != null ? CategoryModel.fromMap({
        'id': map['category_id'],
        'name': map['category_name'],
        'type': map['category_type'] ?? 'expense',
        'icon_code': map['category_icon'],
        'color_value': map['category_color'],
        'is_system': map['category_is_system'] ?? 0,
      }) : null),
    );
  }
}
