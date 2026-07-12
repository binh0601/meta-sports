import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import 'game_state.dart';

/// Vai tro: nguoi choi dang nhap qua Firebase (email/Google),
/// admin "nha cai" van dang nhap cung (admin/123456) khong qua Firebase.
enum UserRole { player, admin }

class AuthState extends ChangeNotifier {
  UserRole? role;
  String username = '';
  bool isDemo = false; // true khi dang nhap tai khoan thu demo/123456

  bool get isLoggedIn => role != null;

  /// Dang nhap: input "admin" -> bypass Firebase; con lai coi la email.
  /// Tra ve null neu thanh cong, nguoc lai la thong bao loi.
  Future<String?> loginEmail(String input, String password) async {
    final id = input.trim();
    if (id.toLowerCase() == 'admin') {
      if (password != '123456') return 'Sai mật khẩu admin.';
      role = UserRole.admin;
      username = 'admin';
      notifyListeners();
      return null;
    }
    if (id.toLowerCase() == 'demo') {
      if (password != '123456') return 'Sai mật khẩu demo.';
      role = UserRole.player;
      username = 'demo';
      isDemo = true;
      gameState.attachDemo();
      notifyListeners();
      return null;
    }
    final err = await AuthService.instance.signInEmail(id, password);
    if (err != null) return err;
    _onPlayerSignedIn();
    return null;
  }

  Future<String?> register(
      String displayName, String email, String password) async {
    final err = await AuthService.instance
        .registerEmail(displayName, email, password);
    if (err != null) return err;
    _onPlayerSignedIn(fallbackName: displayName);
    return null;
  }

  Future<String?> loginGoogle() async {
    final err = await AuthService.instance.signInGoogle();
    if (err != null) return err;
    _onPlayerSignedIn();
    return null;
  }

  /// Firebase nho phien dang nhap — goi luc mo app de vao thang san keo.
  bool tryRestoreSession() {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;
    _onPlayerSignedIn();
    return true;
  }

  void _onPlayerSignedIn({String? fallbackName}) {
    isDemo = false;
    final user = AuthService.instance.currentUser;
    role = UserRole.player;
    username = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : fallbackName ?? user?.email?.split('@').first ?? 'player';
    // Tai vi + lich su tu Firestore ve (chay ngam, UI cap nhat khi xong)
    if (user != null) {
      gameState.attachUser(user);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.signOut();
    gameState.detachUser();
    role = null;
    username = '';
    isDemo = false;
    notifyListeners();
  }
}

/// Trang thai dang nhap dung chung toan app.
final AuthState authState = AuthState();
