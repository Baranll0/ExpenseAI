import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/services/currency_converter.dart';

class CategoryData {
  final Category category;
  final double amount;

  CategoryData({required this.category, required this.amount});
}

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCategoryPieChart(),
            const SizedBox(height: 24),
            _buildMonthlyLineChart(),
            const SizedBox(height: 24),
            _buildWeeklyBarChart(),
            const SizedBox(height: 24),
            _buildYearlyBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('Henüz harcama bulunmamaktadır.'));
    }

    final categoryData = _getCategoryData();
    if (categoryData.isEmpty) {
      return const Center(child: Text('Kategori verisi bulunamadı.'));
    }

    final total = categoryData.fold(0.0, (sum, item) => sum + item.amount);
    final sections = categoryData.asMap().entries.map((entry) {
      final percentage = (entry.value.amount / total * 100).toStringAsFixed(1);
      final color = Colors.primaries[entry.key % Colors.primaries.length];
      return PieChartSectionData(
        value: entry.value.amount,
        title: '',
        color: color.withOpacity(0.85),
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        badgeWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value.category.toString().split('.').last,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${entry.value.amount.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '%$percentage',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        badgePositionPercentageOffset: 0.8,
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          const Text('Kategori Bazlı Harcamalar (USD)', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sections.isEmpty 
              ? const Center(child: Text('Veri bulunamadı'))
              : Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Toplam',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLineChart() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('Henüz harcama bulunmamaktadır.'));
    }

    final monthlyData = _getMonthlyData();
    if (monthlyData.isEmpty) {
      return const Center(child: Text('Aylık veri bulunamadı.'));
    }

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          const Text('Aylık Harcama Trendi (USD)', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.map((data) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '\$${data.amount.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: (data.amount / monthlyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b)) * 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.month,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('Henüz harcama bulunmamaktadır.'));
    }

    final weeklyData = _getWeeklyData();
    if (weeklyData.isEmpty) {
      return const Center(child: Text('Haftalık veri bulunamadı.'));
    }

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          const Text('Haftalık Harcamalar (USD)', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((data) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '\$${data.amount.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: (data.amount / weeklyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b)) * 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.day,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyBarChart() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('Henüz harcama bulunmamaktadır.'));
    }

    final yearlyData = _getYearlyData();
    if (yearlyData.isEmpty) {
      return const Center(child: Text('Yıllık veri bulunamadı.'));
    }

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          const Text('Yıllık Harcamalar (USD)', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: yearlyData.map((data) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '\$${data.amount.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: (data.amount / yearlyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b)) * 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.year,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _convertToUSD(double amount, Currency currency) {
    return CurrencyConverter.convertToUSD(
      amount: amount,
      fromCurrency: currency,
    );
  }

  List<CategoryData> _getCategoryData() {
    if (_expenses.isEmpty) return [];
    
    final Map<Category, double> categoryTotals = {};
    
    for (var expense in _expenses) {
      final amountInUSD = _convertToUSD(expense.amount, expense.currency);
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + amountInUSD;
    }
    
    return categoryTotals.entries.map((entry) => 
      CategoryData(category: entry.key, amount: entry.value)
    ).toList();
  }

  List<MonthlyData> _getMonthlyData() {
    final Map<String, double> monthlySum = {};
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    
    for (var expense in _expenses) {
      final monthYear = '${months[expense.date.month - 1]} ${expense.date.year}';
      final amountInUSD = _convertToUSD(expense.amount, expense.currency);
      monthlySum[monthYear] = (monthlySum[monthYear] ?? 0) + amountInUSD;
    }

    return monthlySum.entries.map((e) => MonthlyData(
      month: e.key,
      amount: e.value,
    )).toList()..sort((a, b) {
      final aDate = a.month.split(' ');
      final bDate = b.month.split(' ');
      final aYear = int.parse(aDate[1]);
      final bYear = int.parse(bDate[1]);
      if (aYear != bYear) return aYear.compareTo(bYear);
      return months.indexOf(aDate[0]).compareTo(months.indexOf(bDate[0]));
    });
  }

  List<YearlyData> _getYearlyData() {
    final Map<int, double> yearlySum = {};
    
    for (var expense in _expenses) {
      final year = expense.date.year;
      final amountInUSD = _convertToUSD(expense.amount, expense.currency);
      yearlySum[year] = (yearlySum[year] ?? 0) + amountInUSD;
    }

    return yearlySum.entries.map((e) => YearlyData(
      year: e.key.toString(),
      amount: e.value,
    )).toList()..sort((a, b) => a.year.compareTo(b.year));
  }

  List<WeeklyData> _getWeeklyData() {
    final Map<String, double> weeklySum = {};
    final daysOfWeek = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    for (var expense in _expenses) {
      final day = daysOfWeek[expense.date.weekday - 1];
      final amountInUSD = _convertToUSD(expense.amount, expense.currency);
      weeklySum[day] = (weeklySum[day] ?? 0) + amountInUSD;
    }

    return daysOfWeek.map((day) => WeeklyData(
      day: day,
      amount: weeklySum[day] ?? 0,
    )).toList();
  }
}

class MonthlyData {
  final String month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}

class WeeklyData {
  final String day;
  final double amount;

  WeeklyData({required this.day, required this.amount});
}

class YearlyData {
  final String year;
  final double amount;

  YearlyData({required this.year, required this.amount});
} 