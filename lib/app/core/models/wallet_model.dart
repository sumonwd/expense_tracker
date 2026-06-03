import 'package:flutter/material.dart';

class WalletModel {
  final int? id;
  final String name;
  final int colorValue;
  final int iconCode;
  double balance; // Computed dynamically or cached

  WalletModel({
    this.id,
    required this.name,
    required this.colorValue,
    required this.iconCode,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color_value': colorValue,
      'icon_code': iconCode,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map, {double balance = 0.0}) {
    return WalletModel(
      id: map['id'],
      name: map['name'],
      colorValue: map['color_value'],
      iconCode: map['icon_code'],
      balance: balance,
    );
  }

  IconData get iconData => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
}
