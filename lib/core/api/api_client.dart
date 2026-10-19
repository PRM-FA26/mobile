import 'package:dio/dio.dart';
import '../auth/secure_storage.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// Custom error that includes the HTTP status code and parsed message.
///
/// Mirrors `ApiRequestError` from `fe-web-novel/src/lib/api.ts`.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Singleton-style Dio wrapper.
///
/// Responsibilities:
/// 1. Base URL and timeout configuration.
/// 2. Token injection via [AuthInterceptor].
/// 3. Response unwrapping (`json.data !== undefined ? json.data : json`).
/// 4. Error message parsing (NestJS Zod / array / string formats).
class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;
  final void Function()? onLoggedOut;

  ApiClient({
    required SecureStorage storage,
    this.onLoggedOut,
  }) : _storage = storage {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(_storage, dio, onLoggedOut: onLoggedOut),
      _ResponseUnwrapInterceptor(),
      // Uncomment for debugging:
      // LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  // ── Convenience methods ─────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await dio.put<T>(
        path,
        data: data,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await dio.delete<T>(
        path,
        data: data,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await dio.patch<T>(
        path,
        data: data,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload a file using multipart FormData.
  Future<T> upload<T>(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Error handling ──────────────────────────────────────────

  ApiException _handleDioError(DioException e) {
    // Network / timeout errors
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        'Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại kết nối.',
        0,
      );
    }

    final statusCode = e.response?.statusCode ?? 0;
    final body = e.response?.data;

    if (body == null) {
      return ApiException(e.message ?? 'Đã có lỗi xảy ra', statusCode);
    }

    return ApiException(_parseErrorMessage(body), statusCode);
  }

  /// Parse error body from NestJS.
  ///
  /// Handles three formats:
  /// 1. Zod errors:  `{ errors: [{ path: [...], message: "..." }] }`
  /// 2. NestJS array: `{ message: ["err1", "err2"] }`
  /// 3. Simple string: `{ message: "string" }`
  String _parseErrorMessage(dynamic body) {
    if (body is Map) {
      // Zod validation errors
      if (body['errors'] is List) {
        return (body['errors'] as List)
            .map((e) {
              final path = (e['path'] as List?)?.join('.') ?? '';
              return '$path: ${e['message']}';
            })
            .join(', ');
      }

      // NestJS default validation (array of messages)
      if (body['message'] is List) {
        return (body['message'] as List).join(', ');
      }

      // Simple string message
      if (body['message'] is String) {
        return body['message'] as String;
      }
    }

    return 'Đã có lỗi xảy ra';
  }
}

/// Interceptor that unwraps the NestJS standard response envelope.
///
/// Backend wraps responses as `{ data: <payload>, message, statusCode }`.
/// This interceptor extracts `data` so callers see the payload directly.
class _ResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      response.data = data['data'];
    }
    handler.next(response);
  }
}
