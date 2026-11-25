import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._prefs, this._api);

  final SharedPreferences _prefs;
  final ApiClient _api;

  static const _tokenKey = 'imago_token';

  User? user;
  String? token;
  bool ready = false;
  bool busy = false;

  bool get isAuthenticated => token != null && token!.isNotEmpty && user != null;

  Future<void> bootstrap() async {
    await Future<void>.delayed(Duration.zero);
    token = _prefs.getString(_tokenKey);
    if (token != null && token!.isNotEmpty) {
      _api.token = token;
      try {
        user = User.fromJson(await _api.me());
      } on ApiException {
        await _clear();
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    busy = true;
    notifyListeners();
    try {
      final data = await _api.login(identifier.trim(), password);
      token = '${data['access_token']}';
      user = User.fromJson(data['user'] as Map<String, dynamic>);
      _api.token = token;
      await _prefs.setString(_tokenKey, token!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) {
    return _api.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      username: username.trim(),
      email: email.trim(),
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  Future<String?> requestReset(String email) async {
    final data = await _api.forgotPassword(email.trim());
    final value = data['reset_token'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirm,
  }) {
    return _api.resetPassword(
      token: token.trim(),
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final data = await _api.updateProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      username: username.trim(),
    );
    user = User.fromJson(data);
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) {
    return _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }

  Future<void> logout() async {
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    token = null;
    user = null;
    _api.token = null;
    await _prefs.remove(_tokenKey);
  }
}
