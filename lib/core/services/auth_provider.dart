import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    final fbUser = _authService.currentUser;
    if (fbUser != null) {
      _user = await _authService.getUserData(fbUser.uid);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'Akun tidak ditemukan.';
    if (error.contains('wrong-password')) return 'Password salah.';
    if (error.contains('invalid-email')) return 'Format email tidak valid.';
    if (error.contains('user-disabled')) return 'Akun telah dinonaktifkan.';
    if (error.contains('network-request-failed')) return 'Tidak ada koneksi internet.';
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
