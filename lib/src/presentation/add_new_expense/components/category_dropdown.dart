import 'package:flutter/material.dart';
import 'package:project/src/models/expense.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final Category selectedCategory;
  final void Function(Category?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Category>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      items: Category.values.map((category) {
        String label;
        IconData icon;

        switch (category) {
          case Category.food:
            label = 'Yemek';
            icon = Icons.restaurant;
            break;
          case Category.transportation:
            label = 'Ulaşım';
            icon = Icons.directions_car;
            break;
          case Category.entertainment:
            label = 'Eğlence';
            icon = Icons.movie;
            break;
          case Category.bills:
            label = 'Faturalar';
            icon = Icons.receipt;
            break;
          case Category.shopping:
            label = 'Alışveriş';
            icon = Icons.shopping_bag;
            break;
          case Category.health:
            label = 'Sağlık';
            icon = Icons.medical_services;
            break;
          case Category.education:
            label = 'Eğitim';
            icon = Icons.school;
            break;
          case Category.other:
            label = 'Diğer';
            icon = Icons.more_horiz;
            break;
        }

        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
