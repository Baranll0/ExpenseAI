import 'package:flutter/material.dart';

import '../../../constants.dart';


class DatePickerWidget extends StatelessWidget {
  const DatePickerWidget({
    super.key,
    required this.presentDatePicker,
    required this.selectedDate,
  });

  final void Function() presentDatePicker;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      onTap: presentDatePicker,
      decoration: const InputDecoration(
        labelText: 'Tarih',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: selectedDate == null
            ? ''
            : formatter.format(selectedDate!),
      ),
      validator: (value) {
        if (selectedDate == null) {
          return 'Lütfen bir tarih seçin';
        }
        return null;
      },
    );
  }
}
