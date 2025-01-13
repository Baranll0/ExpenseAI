import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/src/models/income.dart';
import 'package:project/src/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class IncomeService {
  static final IncomeService _instance = IncomeService._internal();
  factory IncomeService() => _instance;

  IncomeService._internal()
      : _firestore = FirebaseFirestore.instance,
        _auth = AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _auth;

  Future<List<Income>> getIncomes({DateTime? startDate, DateTime? endDate}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      var query = _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Income.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Gelirler yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<Income> addIncome(Income income) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final incomeId = const Uuid().v4();
      final incomeWithId = income.copyWith(id: incomeId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .doc(incomeId)
          .set(incomeWithId.toJson());

      return incomeWithId;
    } catch (e) {
      print('Gelir eklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .doc(income.id)
          .update(income.toJson());
    } catch (e) {
      print('Gelir güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteIncome(String incomeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .doc(incomeId)
          .delete();
    } catch (e) {
      print('Gelir silinirken hata: $e');
      rethrow;
    }
  }

  Future<void> processRecurringIncomes() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final now = DateTime.now();
      final today = now.day;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .where('isRecurring', isEqualTo: true)
          .where('recurringDay', isEqualTo: today)
          .get();

      for (var doc in querySnapshot.docs) {
        final income = Income.fromJson({...doc.data(), 'id': doc.id});
        final newIncome = income.copyWith(
          id: const Uuid().v4(),
          date: DateTime(now.year, now.month, today),
        );
        await addIncome(newIncome);
      }
    } catch (e) {
      print('Düzenli gelirler işlenirken hata: $e');
      rethrow;
    }
  }
} 