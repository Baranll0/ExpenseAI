import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/src/models/scanned_receipt.dart';
import 'package:project/src/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;

  ReceiptService._internal()
      : _firestore = FirebaseFirestore.instance,
        _auth = AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _auth;

  // Taranan faturaları getir
  Future<List<ScannedReceipt>> getScannedReceipts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanned_receipts')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScannedReceipt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Faturalar yüklenirken hata: $e');
      rethrow;
    }
  }

  // Yeni taranmış fatura ekle
  Future<ScannedReceipt> addScannedReceipt(ScannedReceipt receipt) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      final receiptId = const Uuid().v4();
      final receiptWithId = receipt.copyWith(id: receiptId);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanned_receipts')
          .doc(receiptId)
          .set(receiptWithId.toJson());

      return receiptWithId;
    } catch (e) {
      print('Fatura eklenirken hata: $e');
      rethrow;
    }
  }

  // Faturayı güncelle
  Future<void> updateScannedReceipt(ScannedReceipt receipt) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanned_receipts')
          .doc(receipt.id)
          .update(receipt.toJson());
    } catch (e) {
      print('Fatura güncellenirken hata: $e');
      rethrow;
    }
  }

  // Faturayı sil
  Future<void> deleteScannedReceipt(String receiptId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanned_receipts')
          .doc(receiptId)
          .delete();
    } catch (e) {
      print('Fatura silinirken hata: $e');
      rethrow;
    }
  }

  // Fatura durumunu işlendi olarak güncelle
  Future<void> markReceiptAsProcessed(String receiptId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturum açmamış');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanned_receipts')
          .doc(receiptId)
          .update({'isProcessed': true});
    } catch (e) {
      print('Fatura durumu güncellenirken hata: $e');
      rethrow;
    }
  }

  // Gerçek zamanlı fatura akışı
  Stream<List<ScannedReceipt>> getScannedReceiptsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('scanned_receipts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScannedReceipt.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
} 