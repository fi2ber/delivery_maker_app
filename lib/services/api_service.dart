import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  late Dio dio;
  String? _tenantId;
  String? _authToken;

  ApiService() {
    final baseUrl = 'https://api.deliverymaker.uz/v1';

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inject auth token
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        // Inject tenant ID
        if (_tenantId != null) {
          options.headers['x-tenant-id'] = _tenantId;
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _tryRefreshToken();
          if (refreshed && e.requestOptions.extra['retry'] != true) {
            // Retry the original request
            e.requestOptions.extra['retry'] = true;
            e.requestOptions.headers['Authorization'] = 'Bearer $_authToken';
            try {
              final response = await dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              // Refresh failed or retry failed — propagate error
            }
          }
          // Token refresh failed — notify listeners for logout
          _onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }

  // Callback for unauthorized (logout)
  Function? _onUnauthorized;
  void setOnUnauthorized(Function callback) {
    _onUnauthorized = callback;
  }

  // Refresh token storage
  String? _refreshToken;

  /// Set auth token and extract tenantId from JWT
  void setAuthToken(String token, {String? refreshToken}) {
    _authToken = token;
    _refreshToken = refreshToken;

    // Decode JWT payload to extract tenantId
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        // Decode base64 payload
        String payload = parts[1];
        // Add padding if needed
        switch (payload.length % 4) {
          case 2:
            payload += '==';
            break;
          case 3:
            payload += '=';
            break;
        }
        final decoded = utf8.decode(base64Url.decode(payload));
        final Map<String, dynamic> claims = jsonDecode(decoded);

        // Extract tenantId from JWT claims
        _tenantId = claims['tenantId'] ?? claims['tenant_id'] ?? claims['tid'];

        if (_tenantId != null) {
          print('ApiService: tenantId from JWT: $_tenantId');
        }
      }
    } catch (e) {
      print('ApiService: Failed to decode JWT: $e');
    }
  }

  /// Legacy method for backward compatibility
  void setToken(String token) {
    setAuthToken(token);
  }

  /// Set tenant ID manually (fallback)
  void setTenantId(String tenantId) {
    _tenantId = tenantId;
  }

  /// Get current tenant ID
  String? get tenantId => _tenantId;

  /// Get current auth token
  String? get authToken => _authToken;

  /// Try to refresh the auth token
  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await Dio().post(
        'https://api.deliverymaker.uz/v1/auth/refresh',
        data: {'refreshToken': _refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_tenantId != null) 'x-tenant-id': _tenantId!,
          },
        ),
      );

      if (response.data['success'] == true && response.data['token'] != null) {
        final newToken = response.data['token'] as String;
        final newRefresh = response.data['refreshToken'] as String?;
        setAuthToken(newToken, refreshToken: newRefresh ?? _refreshToken);
        // Notify auth service to persist new tokens
        _onTokenRefreshed?.call(newToken, newRefresh ?? _refreshToken);
        return true;
      }
    } catch (e) {
      print('ApiService: Token refresh failed: $e');
    }
    return false;
  }

  // Callback when token is refreshed
  Function(String token, String? refreshToken)? _onTokenRefreshed;
  void setOnTokenRefreshed(Function(String token, String? refreshToken) callback) {
    _onTokenRefreshed = callback;
  }

  // ============ HTTP Methods ============

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, dynamic data) =>
      dio.post(path, data: data);

  Future<Response> put(String path, dynamic data) =>
      dio.put(path, data: data);

  Future<Response> patch(String path, dynamic data) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);

  /// Upload a file and return the server URL
  Future<String?> uploadFile(File file, {String? fieldName}) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      fieldName ?? 'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    try {
      final response = await dio.post(
        '/uploads',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.data['success'] == true) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      print('ApiService: File upload failed: $e');
    }
    return null;
  }
}
