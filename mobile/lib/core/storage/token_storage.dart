import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _secureStorage;

  Future<String?> read() async {
    String? secure;
    try {
      secure = await _secureStorage.read(key: _tokenKey);
    } on MissingPluginException {
      // Unit-test and unsupported desktop runners do not register the plugin.
    }
    if (secure != null && secure.isNotEmpty) return secure;

    // One-time migration from releases that stored the bearer token in plain
    // SharedPreferences.
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_tokenKey);
    if (legacy == null || legacy.isEmpty) return null;
    try {
      await _secureStorage.write(key: _tokenKey, value: legacy);
    } on MissingPluginException {
      return legacy;
    }
    await preferences.remove(_tokenKey);
    return legacy;
  }

  Future<void> save(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await (await SharedPreferences.getInstance()).remove(_tokenKey);
    } on MissingPluginException {
      await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
    }
  }

  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } on MissingPluginException {
      // See read(): this is only a fallback for plugin-less runners.
    }
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }
}
