import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper around [FlutterSecureStorage].
///
/// Mirrors the token management from `fe-web-novel/src/lib/auth.ts`:
/// - accessToken  (1 day expiry in web cookies)
/// - refreshToken (7 day expiry in web cookies)
/// - userRole     (READER / WRITER / ADMIN)
class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _themeKey = 'app_theme';
  static const _readerThemeKey = 'reader_theme';
  static const _readerFontSizeKey = 'reader_font_size';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Auth Tokens ─────────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<void> setTokens(
    String accessToken,
    String refreshToken, [
    String? role,
  ]) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (role != null) {
      await _storage.write(key: _userRoleKey, value: role);
    }
  }

  Future<void> removeTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userRoleKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Preferences ─────────────────────────────────────────────
  Future<String?> getThemeMode() => _storage.read(key: _themeKey);
  Future<void> setThemeMode(String mode) =>
      _storage.write(key: _themeKey, value: mode);

  Future<String?> getReaderTheme() => _storage.read(key: _readerThemeKey);
  Future<void> setReaderTheme(String theme) =>
      _storage.write(key: _readerThemeKey, value: theme);

  Future<double> getReaderFontSize() async {
    final raw = await _storage.read(key: _readerFontSizeKey);
    return raw != null ? double.tryParse(raw) ?? 18.0 : 18.0;
  }

  Future<void> setReaderFontSize(double size) =>
      _storage.write(key: _readerFontSizeKey, value: size.toString());
}
