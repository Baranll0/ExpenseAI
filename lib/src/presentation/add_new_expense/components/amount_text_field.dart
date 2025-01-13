import 'package:flutter/material.dart';
import 'package:project/src/models/currency.dart';

class AmountTextField extends StatelessWidget {
  const AmountTextField({
    super.key,
    required this.amountController,
    required this.selectedCurrency,
  });

  final TextEditingController amountController;
  final Currency selectedCurrency;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixText: '${selectedCurrency.symbol} ',
        label: const Text('Tutar'),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bir tutar girin';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Lütfen geçerli bir tutar girin';
        }
        return null;
      },
    );
  }
}
