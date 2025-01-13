import 'package:flutter/material.dart';
import 'package:project/src/models/expense.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem(this.expense, {super.key});

  final Expense expense;

  String _getRecurringText() {
    switch (expense.recurringType) {
      case RecurringType.daily:
        return 'Günlük';
      case RecurringType.weekly:
        return 'Haftalık';
      case RecurringType.monthly:
        return 'Aylık';
      case RecurringType.yearly:
        return 'Yıllık';
      default:
        return '';
    }
  }

  IconData getCategoryIcon(Category category) {
    switch (category) {
      case Category.food:
        return Icons.restaurant;
      case Category.transportation:
        return Icons.directions_car;
      case Category.entertainment:
        return Icons.movie;
      case Category.bills:
        return Icons.receipt;
      case Category.shopping:
        return Icons.shopping_bag;
      case Category.health:
        return Icons.medical_services;
      case Category.education:
        return Icons.school;
      case Category.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recurringText = _getRecurringText();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(getCategoryIcon(expense.category)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (recurringText.isNotEmpty)
                  Chip(
                    label: Text(
                      recurringText,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${expense.currency.symbol}${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(expense.formatedDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
