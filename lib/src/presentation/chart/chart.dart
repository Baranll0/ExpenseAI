import 'package:flutter/material.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/models/expense_bucket.dart';
import 'package:project/src/widgets/shimmer_widgets.dart';
import 'package:project/src/presentation/chart/chart_bar.dart';
import 'package:project/src/constants.dart';

class Chart extends StatelessWidget {
  final List<Expense>? expenses;
  final bool isLoading;

  const Chart({
    super.key,
    required this.expenses,
    this.isLoading = false,
  });

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(expenses!, Category.food),
      ExpenseBucket.forCategory(expenses!, Category.transportation),
      ExpenseBucket.forCategory(expenses!, Category.entertainment),
      ExpenseBucket.forCategory(expenses!, Category.bills),
      ExpenseBucket.forCategory(expenses!, Category.shopping),
      ExpenseBucket.forCategory(expenses!, Category.health),
      ExpenseBucket.forCategory(expenses!, Category.education),
      ExpenseBucket.forCategory(expenses!, Category.other),
    ];
  }

  double get maxTotalExpense {
    double maxTotalExpense = 0;

    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotalExpense) {
        maxTotalExpense = bucket.totalExpenses;
      }
    }

    return maxTotalExpense;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerChart();
    }

    if (expenses == null || expenses!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.primary.withOpacity(0.0)
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in buckets)
                  ChartBar(
                    fill: bucket.totalExpenses == 0
                        ? 0
                        : bucket.totalExpenses / maxTotalExpense,
                  )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: buckets
                .map(
                  (bucket) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        getCategoryIcons()[bucket.category],
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        ],
      ),
    );
  }
}
