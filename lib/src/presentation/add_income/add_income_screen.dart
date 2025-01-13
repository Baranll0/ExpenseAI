import 'package:flutter/material.dart';
import 'package:project/src/models/income.dart';
import 'package:project/src/models/currency.dart';
import 'package:project/src/services/income_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddIncomeScreen extends StatefulWidget {
  final Function(Income) onAddIncome;
  final Income? incomeToEdit;

  const AddIncomeScreen({
    super.key,
    required this.onAddIncome,
    this.incomeToEdit,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Currency _selectedCurrency = Currency.try_;
  IncomeType _selectedType = IncomeType.salary;
  bool _isRecurring = false;
  int? _recurringDay;
  bool _isLoading = false;

  final _incomeService = IncomeService();

  @override
  void initState() {
    super.initState();
    if (widget.incomeToEdit != null) {
      _titleController.text = widget.incomeToEdit!.title;
      _descriptionController.text = widget.incomeToEdit!.description;
      _amountController.text = widget.incomeToEdit!.amount.toString();
      _selectedDate = widget.incomeToEdit!.date;
      _selectedCurrency = widget.incomeToEdit!.currency;
      _selectedType = widget.incomeToEdit!.type;
      _isRecurring = widget.incomeToEdit!.isRecurring;
      _recurringDay = widget.incomeToEdit!.recurringDay;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final income = Income(
        id: widget.incomeToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        date: _selectedDate!,
        type: _selectedType,
        isRecurring: _isRecurring,
        recurringDay: _isRecurring ? _selectedDate!.day : null,
      );

      await widget.onAddIncome(income);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gelir kaydedilirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Miktar',
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
                          setState(() => _selectedCurrency = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<IncomeType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Gelir Tipi',
                  border: OutlineInputBorder(),
                ),
                items: IncomeType.values.map((type) {
                  String label;
                  switch (type) {
                    case IncomeType.salary:
                      label = 'Maaş';
                      break;
                    case IncomeType.bonus:
                      label = 'Prim/İkramiye';
                      break;
                    case IncomeType.rental:
                      label = 'Kira Geliri';
                      break;
                    case IncomeType.dividend:
                      label = 'Temettü';
                      break;
                    case IncomeType.freelance:
                      label = 'Serbest Çalışma';
                      break;
                    case IncomeType.interest:
                      label = 'Faiz Geliri';
                      break;
                    case IncomeType.other:
                      label = 'Diğer';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _selectedDate == null
                      ? ''
                      : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Lütfen bir tarih seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Düzenli Gelir'),
                subtitle: const Text('Her ay aynı günde tekrarlanır'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() => _isRecurring = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveIncome,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 