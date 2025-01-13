import 'package:flutter/material.dart';
import 'package:project/src/widgets/shimmer_widgets.dart';

import '../../models/expense.dart';
import 'expense_item.dart';
import '../add_new_expense/new_expense.dart';

class ExpensesList extends StatelessWidget {
  final List<Expense>? expenses;
  final bool isLoading;
  final Function(Expense) onRemoveExpense;
  final Function(Expense) onUpdateExpense;

  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
    required this.onUpdateExpense,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerExpenseList();
    }

    if (expenses == null || expenses!.isEmpty) {
      return const Center(
        child: Text('Henüz hiç harcama eklenmemiş.'),
      );
    }

    return ListView.builder(
      itemCount: expenses!.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Dismissible(
        background: Container(
          color: Colors.blue.withOpacity(0.75),
          margin: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          color: Theme.of(context).colorScheme.error.withOpacity(.80),
          margin: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        key: ValueKey(expenses![index]),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onRemoveExpense(expenses![index] as Expense);
          }
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Güncelleme modalını göster
            final expense = expenses![index] as Expense;
            await showModalBottomSheet(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: double.infinity,
              ),
              isScrollControlled: true,
              useSafeArea: true,
              context: context,
              builder: (ctx) => AddNewExpenseScreen(
                onAddExpense: (updatedExpense) async {
                  await onUpdateExpense(updatedExpense);
                },
                expenseToEdit: expense,
              ),
            );
            return false; // Liste öğesini kaydırma animasyonunu geri al
          }
          return true; // Silme işlemi için true döndür
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ExpenseItem(expenses![index] as Expense),
        ),
      ),
    );
  }
}
