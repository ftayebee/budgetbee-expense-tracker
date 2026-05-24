import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);
  Future<void> save(String token) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_tokenKey);
}
