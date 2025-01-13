import 'package:project/src/models/currency.dart';
import 'package:uuid/uuid.dart';

enum RecurringType { none, daily, weekly, monthly, yearly }

class Expense {
  final String id;
  final double amount;
  final DateTime date;
  final String title;
  final Category category;
  final Currency currency;
  final RecurringType recurringType;
  final DateTime? nextRecurringDate;

  Expense({
    String? id,
    required this.amount,
    required this.date,
    required this.title,
    required this.category,
    required this.currency,
    this.recurringType = RecurringType.none,
    this.nextRecurringDate,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'title': title,
    'category': category.toString(),
    'currency': currency.toString(),
    'recurringType': recurringType.toString().split('.').last,
    'nextRecurringDate': nextRecurringDate?.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String,
    category: Category.values.firstWhere(
      (c) => c.toString() == json['category'],
    ),
    currency: Currency.values.firstWhere(
      (c) => c.toString() == json['currency'],
    ),
    recurringType: json['recurringType'] != null
      ? RecurringType.values.firstWhere(
          (t) => t.toString().split('.').last == json['recurringType'],
          orElse: () => RecurringType.none,
        )
      : RecurringType.none,
    nextRecurringDate: json['nextRecurringDate'] != null
      ? DateTime.parse(json['nextRecurringDate'] as String)
      : null,
  );

  Expense copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? title,
    Category? category,
    Currency? currency,
    RecurringType? recurringType,
    DateTime? nextRecurringDate,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      title: title ?? this.title,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      recurringType: recurringType ?? this.recurringType,
      nextRecurringDate: nextRecurringDate ?? this.nextRecurringDate,
    );
  }

  String get formatedDate => '${date.day}/${date.month}/${date.year}';
}

enum Category {
  food,
  transportation,
  entertainment,
  shopping,
  health,
  education,
  bills,
  other
}

