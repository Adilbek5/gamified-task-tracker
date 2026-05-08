import 'package:flutter/material.dart';

enum ShopItemType { avatar, border, badge }

class ShopItemModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final ShopItemType type;
  final String emoji;
  final Color? previewColor;
  final bool isLimited;
  final int requiredLevel;

  const ShopItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.emoji,
    this.previewColor,
    this.isLimited = false,
    required this.requiredLevel,
  });
}
