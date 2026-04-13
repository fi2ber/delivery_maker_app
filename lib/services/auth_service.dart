import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app.dart';
import 'api_service.dart';

/// Authentication Service
/// Handles login, token storage, role management, and JWT-based tenant ID
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _roleKey = 'user_role';
  static const _firstRunKey = 'is_first_run';

  final ApiService _api;

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  String? _tenantId;

  AuthService(this._api);

  /// Initialize auth service — restore saved session
  Future<void> init() async {
    _token = await _storage.read(key: _tokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      try {
        _userData = jsonDecode(userJson);
      } catch (e) {
        debugPrint('Failed to parse user data: $e');
      }
    }

    // Set token in API service if exists (also decodes JWT for tenantId)
    if (_token != null) {
      _api.setAuthToken(_token!, refreshToken: _refreshToken);
      _tenantId = _api.tenantId;
    }

    // Setup token refresh callback to persist new tokens
    _api.setOnTokenRefreshed((newToken, newRefresh) async {
      _token = newToken;
      if (newRefresh != null) _refreshToken = newRefresh;
      await _storage.write(key: _tokenKey, value: newToken);
      if (newRefresh != null) {
        await _storage.write(key: _refreshTokenKey, value: newRefresh);
      }
      _tenantId = _api.tenantId;
    });
  }

  /// Get stored auth token
  String? get token => _token;

  /// Get tenant ID (extracted from JWT)
  String? get tenantId => _tenantId ?? _api.tenantId;

  /// Check if user is logged in
  bool get isLoggedIn => _token != null;

  /// Check if this is the first run
  Future<bool> isFirstRun() async {
    final value = await _storage.read(key: _firstRunKey);
    return value == null;
  }

  /// Mark first run as completed
  Future<void> markFirstRunCompleted() async {
    await _storage.write(key: _firstRunKey, value: 'completed');
  }

  /// Get current user data
  Map<String, dynamic>? get userData => _userData;

  /// Get current user ID
  String? get userId =>
      _userData?['id'] ?? _userData?['userId'] ?? _userData?['sub'];

  /// Get user's full name
  String? get fullName =>
      _userData?['fullName'] ?? _userData?['name'] ?? _userData?['firstName'];

  /// Get user's phone
  String? get phone => _userData?['phone'];

  /// Get user role
  Future<UserRole> getUserRole() async {
    final roleStr = await _storage.read(key: _roleKey);
    return _parseRole(roleStr);
  }

  /// Get current role synchronously (from cached user data)
  String? get roleString => _userData?['role'];

  /// Save user role
  Future<void> setUserRole(UserRole role) async {
    await _storage.write(key: _roleKey, value: role.name);
  }

  /// Login with phone/telegram
  Future<AuthResult> login({
    String? phone,
    String? telegramId,
    String? telegramInitData,
  }) async {
    try {
      final response = await _api.post('/auth/login', {
        if (phone != null) 'phone': phone,
        if (telegramId != null) 'telegramId': telegramId,
        if (telegramInitData != null) 'telegramInitData': telegramInitData,
      });

      final data = response.data;

      if (data['success'] == true) {
        _token = data['token'];
        _refreshToken = data['refreshToken'];
        _userData = data['user'];

        // Save to storage
        await _storage.write(key: _tokenKey, value: _token!);
        if (_refreshToken != null) {
          await _storage.write(key: _refreshTokenKey, value: _refreshToken!);
        }
        await _storage.write(key: _userKey, value: jsonEncode(_userData));

        // Set token in API (also decodes JWT → tenantId)
        _api.setAuthToken(_token!, refreshToken: _refreshToken);
        _tenantId = _api.tenantId;

        // Save role
        final roleStr = _userData?['role'] ?? 'driver';
        await _storage.write(key: _roleKey, value: roleStr);

        return AuthResult.success(
          token: _token!,
          role: _parseRole(roleStr),
        );
      } else {
        return AuthResult.error(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult.error('Network error: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _userData = null;
    _tenantId = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _roleKey);
  }

  /// Parse role string from backend to app enum
  UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'sales':
      case 'sales_rep':
        return UserRole.sales;
      case 'warehouse':
      case 'warehouse_manager':
        return UserRole.warehouse;
      case 'accountant':
        return UserRole.accountant;
      case 'director':
        return UserRole.director;
      case 'owner':
      case 'admin':
      case 'super_admin':
        return UserRole.owner;
      default:
        return UserRole.driver;
    }
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? token;
  final UserRole? role;
  final String? error;

  AuthResult._({
    required this.success,
    this.token,
    this.role,
    this.error,
  });

  factory AuthResult.success({
    required String token,
    required UserRole role,
  }) =>
      AuthResult._(
        success: true,
        token: token,
        role: role,
      );

  factory AuthResult.error(String message) => AuthResult._(
        success: false,
        error: message,
      );
}
