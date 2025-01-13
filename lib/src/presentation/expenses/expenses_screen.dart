import 'package:flutter/material.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/presentation/add_new_expense/new_expense.dart';
import 'package:project/src/presentation/expenses_list/expenses_list.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/presentation/expenses_list/expense_item.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _expenseService.getExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcamalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _handleRemoveExpense(Expense expense) async {
    try {
      await _expenseService.deleteExpense(expense.id);
      await _loadExpenses(); // Listeyi yenile
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcama silinirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _handleUpdateExpense(Expense expense) async {
    try {
      await _expenseService.updateExpense(expense);
      await _loadExpenses(); // Listeyi yenile
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcama güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _handleAddExpense() async {
    final result = await showModalBottomSheet<bool>(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => AddNewExpenseScreen(
        onAddExpense: (expense) async {
          try {
            await _expenseService.addExpense(expense);
            if (mounted) {
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Harcama eklenirken hata oluştu: $e')),
              );
            }
          }
        },
      ),
    );

    if (result == true) {
      await _loadExpenses(); // Yeni harcama eklendiyse listeyi yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ExpensesList(
              expenses: _expenses,
              isLoading: _isLoading,
              onRemoveExpense: _handleRemoveExpense,
              onUpdateExpense: _handleUpdateExpense,
            ),
    );
  }
} 