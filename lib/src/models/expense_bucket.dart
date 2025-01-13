

import '../constants.dart';
import 'expense.dart';

class ExpenseBucket {
  ExpenseBucket({
    required this.category,
    required this.expenses,
  });

  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((element) => element.category == category)
            .toList();

  final Category category;
  final List<Expense> expenses;

  double get totalExpenses {
    var sum = 0.0;
    for (final e in expenses) {
      sum += e.amount;
    }

    return sum;
  }
}
