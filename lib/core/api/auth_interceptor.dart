import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/secure_storage.dart';
import '../constants/app_constants.dart';

/// Dio interceptor that:
/// 1. Attaches JWT Bearer token to every request.
/// 2. Skips `Content-Type` for [FormData] uploads (Dio auto-handles).
/// 3. On 401, attempts a **single** token refresh then retries.
/// 4. Prevents duplicate concurrent refresh calls via [Completer].
///
/// Mirrors the logic from `fe-web-novel/src/lib/api.ts`.
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  /// Callback invoked when the user is fully logged out (refresh also failed).
  final void Function()? onLoggedOut;

  /// Guards against multiple concurrent refresh calls.
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this._storage, this._dio, {this.onLoggedOut});

  // ── REQUEST ─────────────────────────────────────────────────
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Don't set Content-Type for FormData — Dio sets multipart boundary.
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    handler.next(options);
  }

  // ── ERROR ───────────────────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Never retry the login endpoint itself.
    if (err.requestOptions.path == '/auth/login') {
      return handler.next(err);
    }

    final refreshed = await _tryRefreshToken();

    if (refreshed) {
      // Retry original request with new token.
      final newToken = await _storage.getAccessToken();
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (retryError) {
        return handler.next(
          retryError is DioException
              ? retryError
              : DioException(requestOptions: err.requestOptions, error: retryError),
        );
      }
    }

    // Refresh failed → force logout.
    await _storage.removeTokens();
    onLoggedOut?.call();
    handler.next(err);
  }

  // ── REFRESH ─────────────────────────────────────────────────
  Future<bool> _tryRefreshToken() async {
    // If a refresh is already in-flight, wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Use a fresh Dio to avoid interceptor recursion.
      final freshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final response = await freshDio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data;
      final data = body is Map && body.containsKey('data') ? body['data'] : body;

      if (data is Map &&
          data['accessToken'] != null &&
          data['refreshToken'] != null) {
        final currentRole = await _storage.getUserRole();
        await _storage.setTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
          currentRole,
        );
        _refreshCompleter!.complete(true);
        return true;
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
