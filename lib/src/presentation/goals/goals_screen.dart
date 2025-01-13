import 'package:flutter/material.dart';
import 'package:project/src/models/goal.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/services/goal_service.dart';
import 'package:project/src/services/expense_service.dart';
import 'package:project/src/services/currency_converter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _goalService = GoalService();
  final _expenseService = ExpenseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<Goal> _goals = [];

  // Form alanları için controller'lar
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime? _targetDate;
  Currency _selectedCurrency = Currency.usd;
  GoalType _selectedType = GoalType.saving;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _goalService.getGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hedefler yüklenirken hata: $e')),
        );
      }
    }
  }

  void _showAddGoalDialog() {
    _targetDate = null;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Hedef'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Hedef Başlığı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen bir başlık girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GoalType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Hedef Tipi',
                      border: OutlineInputBorder(),
                    ),
                    items: GoalType.values.map((type) {
                      String label;
                      switch (type) {
                        case GoalType.saving:
                          label = 'Tasarruf';
                          break;
                        case GoalType.spending:
                          label = 'Harcama';
                          break;
                        case GoalType.debt:
                          label = 'Borç Ödeme';
                          break;
                      }
                      return DropdownMenuItem(value: type, child: Text(label));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _targetAmountController,
                          decoration: InputDecoration(
                            labelText: 'Hedef Miktar',
                            border: const OutlineInputBorder(),
                            prefixText: _selectedCurrency.symbol,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir miktar girin';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Geçerli bir miktar girin';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<Currency>(
                          value: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Para Birimi',
                            border: OutlineInputBorder(),
                          ),
                          items: Currency.values.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentAmountController,
                    decoration: InputDecoration(
                      labelText: 'Mevcut Miktar',
                      border: const OutlineInputBorder(),
                      prefixText: _selectedCurrency.symbol,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen mevcut miktarı girin';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Geçerli bir miktar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Hedef Tarihi',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _targetDate == null
                          ? ''
                          : DateFormat('dd.MM.yyyy').format(_targetDate!),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _targetDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setDialogState(() => _targetDate = date);
                      }
                    },
                    validator: (value) {
                      if (_targetDate == null) {
                        return 'Lütfen bir tarih seçin';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                try {
                  final goal = Goal(
                    id: const Uuid().v4(),
                    title: _titleController.text,
                    description: _descriptionController.text,
                    targetAmount: double.parse(_targetAmountController.text),
                    currentAmount: double.parse(_currentAmountController.text),
                    currency: _selectedCurrency,
                    startDate: DateTime.now(),
                    targetDate: _targetDate!,
                    type: _selectedType,
                  );

                  await _goalService.addGoal(goal);
                  if (mounted) {
                    Navigator.pop(context);
                    _clearForm();
                    await _loadGoals();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hedef başarıyla eklendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hedef eklenirken hata: $e')),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _targetAmountController.clear();
    _currentAmountController.clear();
    _targetDate = null;
    _selectedCurrency = Currency.usd;
    _selectedType = GoalType.saving;
  }

  Future<void> _updateGoalProgress(Goal goal) async {
    final controller = TextEditingController(
      text: goal.currentAmount.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlerlemeyi Güncelle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Mevcut Miktar',
            border: const OutlineInputBorder(),
            prefixText: goal.currency.symbol,
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null) return;

              try {
                await _goalService.updateGoalProgress(goal.id, amount);
                await _loadGoals();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Güncelleme hatası: $e')),
                  );
                }
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: const Text('Bu hedefi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _goalService.deleteGoal(goal.id);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hedef silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hedef silinirken hata: $e')),
          );
        }
      }
    }
  }

  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.saving:
        return 'Tasarruf';
      case GoalType.spending:
        return 'Harcama';
      case GoalType.debt:
        return 'Borç Ödeme';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1) {
      return Colors.green;
    } else if (progress >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
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
        
        // Her hedef için ilgili kategorideki harcamaları hesapla
        for (var goal in _goals) {
          double totalExpenseForGoal = 0;
          for (var expense in expenses) {
            if (expense.date.isAfter(goal.startDate) && 
                expense.date.isBefore(goal.targetDate)) {
              totalExpenseForGoal += CurrencyConverter.convertToUSD(
                amount: expense.amount,
                fromCurrency: expense.currency,
              );
            }
          }
          // Hedefin mevcut miktarını güncelle
          if (goal.currentAmount != totalExpenseForGoal) {
            _goalService.updateGoalProgress(goal.id, totalExpenseForGoal);
          }
        }

        return Scaffold(
          body: _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Henüz hedef eklenmemiş',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddGoalDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Hedef Ekle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final progress = goal.progress;
                    final remainingAmount = goal.targetAmount - goal.currentAmount;
                    final progressColor = _getProgressColor(progress);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.title,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getGoalTypeText(goal.type),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () => _updateGoalProgress(goal),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.update),
                                          SizedBox(width: 8),
                                          Text('İlerlemeyi Güncelle'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () => _deleteGoal(goal),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Sil', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (goal.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(goal.description),
                            ],
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 10,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'İlerleme: ${(progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${goal.currency.symbol}${goal.currentAmount.toStringAsFixed(2)} / ${goal.currency.symbol}${goal.targetAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kalan: ${goal.currency.symbol}${remainingAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Kalan Gün: ${goal.remainingDays}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (goal.remainingDays > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Günlük Gereken: ${goal.currency.symbol}${goal.requiredDailyAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            if (goal.isCompleted)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hedef Tamamlandı!',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddGoalDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
} 