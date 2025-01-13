import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Kullanıcı durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcı
  User? get currentUser {
    final user = _auth.currentUser;
    print('Mevcut kullanıcı: ${user?.uid ?? "Oturum açılmamış"}');
    return user;
  }

  // Google ile giriş
  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Önceki oturumu temizle
      print('1. Google Sign-In başlatılıyor...');
      
      // Google Sign-In akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('2. Google Sign-In iptal edildi veya başarısız oldu');
        return null;
      }
      print('2. Google hesabı seçildi: ${googleUser.email}');

      // Google Sign-In kimlik bilgilerini al
      print('3. Google kimlik bilgileri alınıyor...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('4. Google kimlik bilgileri alındı - Token var mı: ${googleAuth.accessToken != null}');

      // Firebase kimlik bilgilerini oluştur
      print('5. Firebase kimlik bilgileri oluşturuluyor...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('6. Firebase credential oluşturuldu');

      // Firebase ile giriş yap
      print('7. Firebase ile giriş yapılıyor...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('8. Firebase giriş başarılı - Kullanıcı: ${userCredential.user?.email}');
      
      return userCredential.user;
    } catch (e) {
      print('HATA: Google girişi sırasında hata oluştu:');
      print('HATA detayı: $e');
      await _googleSignIn.signOut(); // Hata durumunda oturumu temizle
      throw Exception('Google ile giriş yapılırken bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  // Email/Password ile kayıt
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Şifre çok zayıf.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Bu e-posta adresi zaten kullanımda.');
      } else {
        throw Exception('Bir hata oluştu: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  // Email/Password ile giriş
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Yanlış şifre.');
      } else {
        throw Exception('Giriş yapılırken bir hata oluştu: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Google oturumunu kapat
      await _auth.signOut(); // Firebase oturumunu kapat
    } catch (e) {
      throw Exception('Çıkış yapılırken bir hata oluştu.');
    }
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Kayıt olurken hata: $e');
      rethrow;
    }
  }

  Future<void> reauthenticateWithCredential(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      print('Yeniden kimlik doğrulama hatası: $e');
      rethrow;
    }
  }
} 