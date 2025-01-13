import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/src/models/expense.dart';
import 'package:project/src/services/auth_service.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;

  ExpenseService._internal()
      : _firestore = FirebaseFirestore.instance,
        _authService = AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  Future<List<Expense>> getExpenses() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        print('Kullanıcı oturumu bulunamadı');
        return [];
      }

      print('Harcamalar yükleniyor... UserID: $userId');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      print('Bulunan harcama sayısı: ${querySnapshot.docs.length}');
      final expenses = <Expense>[];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Harcama verisi işleniyor: $data');
          final expense = Expense.fromJson({...data, 'id': doc.id});
          expenses.add(expense);
          print('Harcama başarıyla dönüştürüldü: ${expense.title}');
        } catch (e) {
          print('Harcama dönüştürme hatası: $e');
          continue;
        }
      }

      print('Başarıyla yüklenen harcama sayısı: ${expenses.length}');
      return expenses;
    } catch (e) {
      print('Harcamalar yüklenirken hata: $e');
      return [];
    }
  }

  Future<Expense> addExpense(Expense expense) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı oturum açmamış');

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .add(expense.toJson());

    return expense.copyWith(id: docRef.id);
  }

  Future<void> updateExpense(Expense expense) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı oturum açmamış');

    final data = expense.toJson();
    data.remove('id');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expense.id)
        .update(data);
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Stream<List<Expense>> getExpensesStream() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
} 