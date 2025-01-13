import 'package:flutter/material.dart';
import 'package:project/src/models/budget.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/services/budget_service.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/services/currency_converter.dart';
import 'package:uuid/uuid.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  final _expenseService = ExpenseService();
  final _amountController = TextEditingController();
  bool _isLoading = true;
  Budget? _currentBudget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final budget = await _budgetService.getCurrentBudget();
      setState(() {
        _currentBudget = budget;
        if (budget != null) {
          _amountController.text = budget.amount.toString();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bütçe yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir bütçe miktarı girin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final budget = Budget(
        id: _currentBudget?.id ?? const Uuid().v4(),
        amount: amount,
        currency: Currency.usd,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      await _budgetService.saveBudget(budget);
      await _loadBudget();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe kaydedildi')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bütçe kaydedilirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesStream(),
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];
        double totalExpenses = 0;
        
        for (final expense in expenses) {
          totalExpenses += CurrencyConverter.convertToUSD(
            amount: expense.amount,
            fromCurrency: expense.currency,
          );
        }

        final progress = _currentBudget != null ? totalExpenses / _currentBudget!.amount : 0.0;
        final isOverBudget = progress > 1.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık Bütçe (USD)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Bütçe Miktarı',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveBudget,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_currentBudget != null) ...[
                Text(
                  'Bütçe Durumu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harcanan: \$${totalExpenses.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isOverBudget ? Colors.red : null,
                      ),
                    ),
                    Text('Toplam: \$${_currentBudget!.amount.toStringAsFixed(2)}'),
                  ],
                ),
                if (isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Bütçe aşıldı! (\$${(totalExpenses - _currentBudget!.amount).toStringAsFixed(2)})',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
} 