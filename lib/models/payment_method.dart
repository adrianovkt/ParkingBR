import 'package:flutter/material.dart';

enum PaymentType { creditCard, debitCard, pix, cash }

class PaymentMethod {
  final String id;
  final String name;
  final PaymentType type;
  final IconData icon;
  final Color color;
  final String? details; // e.g. "**** 1234"

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.details,
  });
}
