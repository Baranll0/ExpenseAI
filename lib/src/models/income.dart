import 'package:project/src/models/currency.dart';

enum IncomeType {
  salary,     // Maaş
  bonus,      // Prim/İkramiye
  rental,     // Kira Geliri
  dividend,   // Temettü
  freelance,  // Serbest Çalışma
  interest,   // Faiz Geliri
  other       // Diğer
}

class Income {
  final String id;
  final String title;
  final String description;
  final double amount;
  final Currency currency;
  final DateTime date;
  final IncomeType type;
  final bool isRecurring;      // Düzenli gelir mi?
  final int? recurringDay;     // Ayın hangi günü? (düzenli gelirler için)

  Income({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    required this.type,
    this.isRecurring = false,
    this.recurringDay,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'amount': amount,
    'currency': currency.toString(),
    'date': date.toIso8601String(),
    'type': type.toString(),
    'isRecurring': isRecurring,
    'recurringDay': recurringDay,
  };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    amount: json['amount'] as double,
    currency: Currency.values.firstWhere(
      (c) => c.toString() == json['currency'],
    ),
    date: DateTime.parse(json['date'] as String),
    type: IncomeType.values.firstWhere(
      (t) => t.toString() == json['type'],
    ),
    isRecurring: json['isRecurring'] as bool,
    recurringDay: json['recurringDay'] as int?,
  );

  Income copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    Currency? currency,
    DateTime? date,
    IncomeType? type,
    bool? isRecurring,
    int? recurringDay,
  }) => Income(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    type: type ?? this.type,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringDay: recurringDay ?? this.recurringDay,
  );
} 