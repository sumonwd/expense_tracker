import 'category_model.dart';

class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income', 'expense', or 'transfer'
  final int? categoryId; // Nullable for transfers
  final int walletId;
  final int? transferWalletId; // Nullable, only populated for transfers
  final DateTime date;
  final String? note;
  
  // Loaded dynamically via SQL joins
  final CategoryModel? category;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.walletId,
    this.transferWalletId,
    required this.date,
    this.note,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'wallet_id': walletId,
      'transfer_wallet_id': transferWalletId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      type: map['type'],
      categoryId: map['category_id'],
      walletId: map['wallet_id'] ?? 1, // Fallback to default wallet id
      transferWalletId: map['transfer_wallet_id'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      category: category ?? (map['category_name'] != null ? CategoryModel.fromMap({
        'id': map['category_id'],
        'name': map['category_name'],
        'type': map['category_type'] ?? map['type'],
        'icon_code': map['category_icon'],
        'color_value': map['category_color'],
        'is_system': map['category_is_system'] ?? 0,
      }) : null),
    );
  }
}
