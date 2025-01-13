import 'package:flutter/material.dart';
import 'package:project/src/models/income.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/services/income_service.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/services/currency_converter.dart';
import 'package:project/src/presentation/add_income/add_income_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final _incomeService = IncomeService();
  final _expenseService = ExpenseService();
  bool _isLoading = true;
  List<Income> _incomes = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);
    try {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final incomes = await _incomeService.getIncomes(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _incomes = incomes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata: $e')),
        );
      }
    }
  }

  void _showAddIncomeDialog() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => AddIncomeScreen(
        onAddIncome: _addIncome,
      ),
    );
  }

  Future<void> _addIncome(Income income) async {
    try {
      setState(() => _isLoading = true);
      await _incomeService.addIncome(income);
      await _loadIncomes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gelir başarıyla eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gelir eklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesStream(),
      builder: (context, expenseSnapshot) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = expenseSnapshot.data ?? [];
        final filteredExpenses = expenses.where((e) {
          final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          return e.date.isAfter(startDate) && e.date.isBefore(endDate);
        }).toList();

        final totalIncome = _getTotalIncome();
        final totalExpense = _getTotalExpense(filteredExpenses);
        final balance = totalIncome - totalExpense;
        final isPositive = balance >= 0;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month - 1,
                                  );
                                });
                                _loadIncomes();
                              },
                            ),
                            Text(
                              DateFormat('MMMM y', 'tr_TR').format(_selectedDate),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month + 1,
                                  );
                                });
                                _loadIncomes();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Gelir'),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalIncome.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            Column(
                              children: [
                                const Text('Gider'),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalExpense.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            Column(
                              children: [
                                const Text('Bakiye'),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${balance.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gelir Dağılımı',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _getIncomeByType().entries.map((entry) {
                        final percentage = (entry.value / totalIncome * 100);
                        return PieChartSectionData(
                          color: Colors.primaries[entry.key.index % Colors.primaries.length],
                          value: entry.value,
                          title: '${_getIncomeTypeText(entry.key)}\n%${percentage.toStringAsFixed(1)}',
                          radius: 100,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gider Dağılımı',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _getExpenseByCategory(filteredExpenses).entries.map((entry) {
                        final percentage = (entry.value / totalExpense * 100);
                        return PieChartSectionData(
                          color: Colors.primaries[entry.key.index % Colors.primaries.length],
                          value: entry.value,
                          title: '${entry.key.toString().split('.').last}\n%${percentage.toStringAsFixed(1)}',
                          radius: 100,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddIncomeDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  double _getTotalIncome() {
    double total = 0;
    for (var income in _incomes) {
      total += CurrencyConverter.convertToUSD(
        amount: income.amount,
        fromCurrency: income.currency,
      );
    }
    return total;
  }

  double _getTotalExpense(List<Expense> expenses) {
    double total = 0;
    for (var expense in expenses) {
      total += CurrencyConverter.convertToUSD(
        amount: expense.amount,
        fromCurrency: expense.currency,
      );
    }
    return total;
  }

  Map<IncomeType, double> _getIncomeByType() {
    final Map<IncomeType, double> data = {};
    for (var income in _incomes) {
      final amount = CurrencyConverter.convertToUSD(
        amount: income.amount,
        fromCurrency: income.currency,
      );
      data[income.type] = (data[income.type] ?? 0) + amount;
    }
    return data;
  }

  Map<Category, double> _getExpenseByCategory(List<Expense> expenses) {
    final Map<Category, double> data = {};
    for (var expense in expenses) {
      final amount = CurrencyConverter.convertToUSD(
        amount: expense.amount,
        fromCurrency: expense.currency,
      );
      data[expense.category] = (data[expense.category] ?? 0) + amount;
    }
    return data;
  }

  String _getIncomeTypeText(IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return 'Maaş';
      case IncomeType.bonus:
        return 'Prim';
      case IncomeType.rental:
        return 'Kira';
      case IncomeType.dividend:
        return 'Temettü';
      case IncomeType.freelance:
        return 'Serbest';
      case IncomeType.interest:
        return 'Faiz';
      case IncomeType.other:
        return 'Diğer';
    }
  }
} 