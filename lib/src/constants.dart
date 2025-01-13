import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:project/src/models/expense.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

Map<Category, IconData> getCategoryIcons() {
  return {
    Category.food: Icons.restaurant,
    Category.transportation: Icons.directions_car,
    Category.entertainment: Icons.movie,
    Category.bills: Icons.receipt,
    Category.shopping: Icons.shopping_bag,
    Category.health: Icons.medical_services,
    Category.education: Icons.school,
    Category.other: Icons.more_horiz,
  };
}
