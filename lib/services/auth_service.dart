import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

const String _kNoFirebaseMsg =
    'Firebase chưa được cấu hình — đặt google-services.json vào android/app/ '
    'rồi build lại (xem checklist trong plan).';

/// Boc FirebaseAuth + Google Sign-In. Moi ham tra ve null neu thanh cong,
/// nguoc lai la thong bao loi tieng Viet de hien thang len UI.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _googleInitialized = false;

  User? get currentUser =>
      firebaseReady ? FirebaseAuth.instance.currentUser : null;

  Future<String?> signInEmail(String email, String password) async {
    if (!firebaseReady) return _kNoFirebaseMsg;
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  Future<String?> registerEmail(
      String displayName, String email, String password) async {
    if (!firebaseReady) return _kNoFirebaseMsg;
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(displayName.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  Future<String?> signInGoogle() async {
    if (!firebaseReady) return _kNoFirebaseMsg;
    try {
      final gsi = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await gsi.initialize();
        _googleInitialized = true;
      }
      final account = await gsi.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return 'Không lấy được thông tin từ Google, thử lại.';
      }
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken));
      return null;
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled
          ? 'Bạn đã hủy đăng nhập Google.'
          : 'Lỗi Google Sign-In: ${e.description ?? e.code.name}. '
              'Kiểm tra SHA-1 đã thêm vào Firebase console chưa.';
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    await FirebaseAuth.instance.signOut();
  }

  String _mapError(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'Email không đúng định dạng.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Sai email hoặc mật khẩu.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu quá yếu (tối thiểu 6 ký tự).',
        'network-request-failed' => 'Mất mạng — kiểm tra kết nối.',
        'too-many-requests' => 'Thử sai quá nhiều, đợi một lát rồi thử lại.',
        _ => 'Lỗi đăng nhập: ${e.code}',
      };
}
