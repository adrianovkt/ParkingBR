import 'package:flutter/material.dart';

enum PaymentType { cash, pix, card, free }

class PaymentMethod {
  final String id;
  final String name;
  final PaymentType type;
  final IconData icon;
  final Color color;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });
}
