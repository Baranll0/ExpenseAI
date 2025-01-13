import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/presentation/expenses/expenses_screen.dart';
import 'package:project/src/presentation/charts/charts_screen.dart';
import 'package:project/src/presentation/budget/budget_screen.dart';
import 'package:project/src/presentation/goals/goals_screen.dart';
import 'package:project/src/presentation/balance/balance_screen.dart';
import 'package:project/src/presentation/profile/profile_screen.dart';
import 'package:project/src/presentation/add_new_expense/new_expense.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  final _expenseService = ExpenseService();
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _expenseService.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = expenses;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcamalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => AddNewExpenseScreen(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) async {
    setState(() => _isLoading = true);
    try {
      final addedExpense = await _expenseService.addExpense(expense);
      if (mounted) {
        setState(() {
          _expenses.insert(0, addedExpense);
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harcama başarıyla eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcama eklenirken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ExpensesScreen(),
      const ChartsScreen(),
      const BudgetScreen(),
      const GoalsScreen(),
      const BalanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0 
          ? const Text('Harcama Takibi') 
          : _selectedIndex == 1 
            ? const Text('Grafikler') 
            : _selectedIndex == 2 
              ? const Text('Bütçe')
              : _selectedIndex == 3
                ? const Text('Hedefler')
                : _selectedIndex == 4
                  ? const Text('Gelir/Gider')
                  : const Text('Profil'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () => _showAddExpenseBottomSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        color: Theme.of(context).colorScheme.primary,
        buttonBackgroundColor: Theme.of(context).colorScheme.primary,
        height: 60,
        items: const [
          Icon(Icons.list, color: Colors.white),
          Icon(Icons.insert_chart, color: Colors.white),
          Icon(Icons.account_balance_wallet, color: Colors.white),
          Icon(Icons.flag, color: Colors.white),
          Icon(Icons.balance, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
} 