import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final int iconCode; // Unicode code point
  final int colorValue; // ARGB value
  final bool isSystem;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'icon_code': iconCode,
      'color_value': colorValue,
      'is_system': isSystem ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      iconCode: map['icon_code'],
      colorValue: map['color_value'],
      isSystem: map['is_system'] == 1,
    );
  }

  IconData get iconData => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
}
