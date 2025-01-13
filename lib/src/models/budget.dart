import 'package:project/src/models/currency.dart';

class Budget {
  final String id;
  final double amount;
  final Currency currency;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'currency': currency.toString(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    amount: json['amount'] as double,
    currency: Currency.values.firstWhere(
      (c) => c.toString() == json['currency'],
    ),
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
  );

  Budget copyWith({
    String? id,
    double? amount,
    Currency? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Budget(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
} 