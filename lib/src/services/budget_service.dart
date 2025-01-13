import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/src/models/budget.dart';
import 'package:project/src/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;

  BudgetService._internal()
      : _firestore = FirebaseFirestore.instance,
        _auth = AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _auth;

  Future<Budget?> getCurrentBudget() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .where('startDate', isEqualTo: startOfMonth.toIso8601String())
          .where('endDate', isEqualTo: endOfMonth.toIso8601String())
          .get();

      if (doc.docs.isEmpty) return null;

      return Budget.fromJson({
        ...doc.docs.first.data(),
        'id': doc.docs.first.id,
      });
    } catch (e) {
      print('Bütçe getirilirken hata: $e');
      return null;
    }
  }

  Future<void> saveBudget(Budget budget) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final budgetId = budget.id.isEmpty ? const Uuid().v4() : budget.id;
      final budgetWithId = budget.copyWith(id: budgetId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc(budgetId)
          .set(budgetWithId.toJson());
    } catch (e) {
      print('Bütçe kaydedilirken hata: $e');
      throw Exception('Bütçe kaydedilemedi: $e');
    }
  }
} 