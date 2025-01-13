import 'package:project/src/models/currency.dart';

enum GoalType {
  saving,    // Tasarruf hedefi
  spending,  // Harcama hedefi
  debt       // Borç ödeme hedefi
}

class Goal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final Currency currency;
  final DateTime startDate;
  final DateTime targetDate;
  final GoalType type;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.startDate,
    required this.targetDate,
    required this.type,
    this.isCompleted = false,
  });

  double get progress => currentAmount / targetAmount;
  
  int get remainingDays => targetDate.difference(DateTime.now()).inDays;
  
  double get requiredDailyAmount {
    if (remainingDays <= 0) return 0;
    return (targetAmount - currentAmount) / remainingDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'currency': currency.toString(),
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'type': type.toString(),
    'isCompleted': isCompleted,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    targetAmount: json['targetAmount'] as double,
    currentAmount: json['currentAmount'] as double,
    currency: Currency.values.firstWhere(
      (c) => c.toString() == json['currency'],
    ),
    startDate: DateTime.parse(json['startDate'] as String),
    targetDate: DateTime.parse(json['targetDate'] as String),
    type: GoalType.values.firstWhere(
      (t) => t.toString() == json['type'],
    ),
    isCompleted: json['isCompleted'] as bool,
  );

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    Currency? currency,
    DateTime? startDate,
    DateTime? targetDate,
    GoalType? type,
    bool? isCompleted,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    currency: currency ?? this.currency,
    startDate: startDate ?? this.startDate,
    targetDate: targetDate ?? this.targetDate,
    type: type ?? this.type,
    isCompleted: isCompleted ?? this.isCompleted,
  );
} 