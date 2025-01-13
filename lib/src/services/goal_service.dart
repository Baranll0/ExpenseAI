import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/src/models/goal.dart';
import 'package:project/src/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;

  GoalService._internal()
      : _firestore = FirebaseFirestore.instance,
        _auth = AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _auth;

  Future<List<Goal>> getGoals() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .orderBy('targetDate')
          .get();

      return querySnapshot.docs
          .map((doc) => Goal.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Hedefler yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<Goal> addGoal(Goal goal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final goalId = const Uuid().v4();
      final goalWithId = goal.copyWith(id: goalId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .set(goalWithId.toJson());

      return goalWithId;
    } catch (e) {
      print('Hedef eklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goal.id)
          .update(goal.toJson());
    } catch (e) {
      print('Hedef güncellenirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .delete();
    } catch (e) {
      print('Hedef silinirken hata: $e');
      rethrow;
    }
  }

  Future<void> updateGoalProgress(String goalId, double newAmount) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final goalDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) throw Exception('Hedef bulunamadı');

      final goal = Goal.fromJson({...goalDoc.data()!, 'id': goalDoc.id});
      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: newAmount >= goal.targetAmount,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .update(updatedGoal.toJson());
    } catch (e) {
      print('Hedef ilerleme güncellenirken hata: $e');
      rethrow;
    }
  }
} 