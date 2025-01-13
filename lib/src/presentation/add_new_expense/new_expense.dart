import 'package:flutter/material.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/presentation/add_new_expense/components/amount_text_field.dart';
import 'package:project/src/presentation/add_new_expense/components/category_dropdown.dart';
import 'package:project/src/presentation/add_new_expense/components/date_picker_widget.dart';
import 'package:project/src/presentation/add_new_expense/components/title_text_field.dart';
import 'package:project/src/services/expense_service.dart';



class AddNewExpenseScreen extends StatefulWidget {
  final Function(Expense) onAddExpense;
  final Expense? expenseToEdit;

  const AddNewExpenseScreen({
    super.key,
    required this.onAddExpense,
    this.expenseToEdit,
  });

  @override
  State<AddNewExpenseScreen> createState() => _AddNewExpenseScreenState();
}

class _AddNewExpenseScreenState extends State<AddNewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _expenseService = ExpenseService();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.other;
  Currency _selectedCurrency = Currency.defaultCurrency;
  RecurringType _selectedRecurringType = RecurringType.none;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      _titleController.text = widget.expenseToEdit!.title;
      _amountController.text = widget.expenseToEdit!.amount.toString();
      _selectedDate = widget.expenseToEdit!.date;
      _selectedCategory = widget.expenseToEdit!.category;
      _selectedCurrency = widget.expenseToEdit!.currency;
      _selectedRecurringType = widget.expenseToEdit!.recurringType;
    }
  }

  _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  DateTime _calculateNextRecurringDate(DateTime currentDate, RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return currentDate.add(const Duration(days: 1));
      case RecurringType.weekly:
        return currentDate.add(const Duration(days: 7));
      case RecurringType.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case RecurringType.yearly:
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
      default:
        return currentDate;
    }
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<Currency>(
      value: _selectedCurrency,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Para Birimi',
        border: OutlineInputBorder(),
      ),
      items: Currency.availableCurrencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text('${currency.name} (${currency.symbol})'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCurrency = value);
        }
      },
    );
  }

  Widget _buildRecurringTypeDropdown() {
    return DropdownButtonFormField<RecurringType>(
      value: _selectedRecurringType,
      decoration: const InputDecoration(
        labelText: 'Tekrar',
        border: OutlineInputBorder(),
      ),
      items: RecurringType.values.map((type) {
        String label;
        switch (type) {
          case RecurringType.none:
            label = 'Tekrar Yok';
            break;
          case RecurringType.daily:
            label = 'Günlük';
            break;
          case RecurringType.weekly:
            label = 'Haftalık';
            break;
          case RecurringType.monthly:
            label = 'Aylık';
            break;
          case RecurringType.yearly:
            label = 'Yıllık';
            break;
        }
        return DropdownMenuItem(value: type, child: Text(label));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRecurringType = value);
        }
      },
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Harcama kaydediliyor...');
      final expense = Expense(
        id: widget.expenseToEdit?.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate!,
        category: _selectedCategory,
        currency: _selectedCurrency,
        recurringType: _selectedRecurringType,
        nextRecurringDate: _selectedRecurringType != RecurringType.none 
            ? _calculateNextRecurringDate(_selectedDate!, _selectedRecurringType)
            : null,
      );

      print('Oluşturulan harcama: ${expense.toJson()}');
      
      if (widget.expenseToEdit != null) {
        await _expenseService.updateExpense(expense);
        print('Harcama başarıyla güncellendi');
      } else {
        await _expenseService.addExpense(expense);
        print('Harcama başarıyla kaydedildi');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expenseToEdit != null 
              ? 'Harcama başarıyla güncellendi'
              : 'Harcama başarıyla kaydedildi'
            ),
          ),
        );
      }
    } catch (e) {
      print('Harcama işlemi sırasında hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem sırasında hata oluştu: $e')),
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
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleTextField(titleController: _titleController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AmountTextField(
                      amountController: _amountController,
                      selectedCurrency: _selectedCurrency,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCurrencyDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CategoryDropdown(
                      selectedCategory: _selectedCategory,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DatePickerWidget(
                      presentDatePicker: _presentDatePicker,
                      selectedDate: _selectedDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecurringTypeDropdown(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _saveExpense,
                      child: const Text('Kaydet'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
