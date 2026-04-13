import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class DriverApiService {
  final ApiService _api;

  DriverApiService(this._api);

  /// Get driver's orders for today
  Future<Map<String, dynamic>> getMyOrders(String driverId,
      {DateTime? date}) async {
    final dateStr = date?.toIso8601String().split('T').first;
    final response = await _api.get('/driver/orders/my', queryParameters: {
      'driverId': driverId,
      if (dateStr != null) 'date': dateStr,
    });
    return response.data;
  }

  /// Get optimized route for today
  Future<Map<String, dynamic>> getRoute(String driverId,
      {DateTime? date,
      double? warehouseLat,
      double? warehouseLng}) async {
    final dateStr = date?.toIso8601String().split('T').first;
    final response = await _api.get('/driver/orders/route', queryParameters: {
      'driverId': driverId,
      if (dateStr != null) 'date': dateStr,
      if (warehouseLat != null) 'warehouseLat': warehouseLat.toString(),
      if (warehouseLng != null) 'warehouseLng': warehouseLng.toString(),
    });
    return response.data;
  }

  /// Pick up order from warehouse
  Future<Map<String, dynamic>> pickupOrder(String orderId, String driverId,
      {String? notes}) async {
    final response = await _api.post('/driver/orders/$orderId/pickup', {
      'driverId': driverId,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  /// Mark order as delivered with photo/signature upload
  Future<Map<String, dynamic>> deliverOrder(
    String orderId,
    String driverId, {
    String? photoPath,
    String? signaturePath,
    String? notes,
  }) async {
    // Upload photo if provided as file path
    String? photoUrl;
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (await file.exists()) {
        photoUrl = await _api.uploadFile(file, fieldName: 'file');
      }
    }

    // Upload signature if provided as file path
    String? signatureUrl;
    if (signaturePath != null && signaturePath.isNotEmpty) {
      final file = File(signaturePath);
      if (await file.exists()) {
        signatureUrl = await _api.uploadFile(file, fieldName: 'file');
      }
    }

    final response = await _api.post('/driver/orders/$orderId/deliver', {
      'driverId': driverId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  /// Mark delivery as failed
  Future<Map<String, dynamic>> deliveryFailed(
    String orderId,
    String driverId,
    String reason,
  ) async {
    final response = await _api.post('/driver/orders/$orderId/failed', {
      'driverId': driverId,
      'reason': reason,
    });
    return response.data;
  }

  /// Get today's statistics
  Future<Map<String, dynamic>> getTodayStats(String driverId) async {
    final response = await _api
        .get('/driver/orders/stats/today', queryParameters: {
      'driverId': driverId,
    });
    return response.data;
  }

  /// Get driver earnings
  Future<Map<String, dynamic>> getEarnings(String driverId,
      {DateTime? startDate, DateTime? endDate}) async {
    final response =
        await _api.get('/driver/earnings/$driverId', queryParameters: {
      if (startDate != null) 'start': startDate.toIso8601String(),
      if (endDate != null) 'end': endDate.toIso8601String(),
    });
    return response.data;
  }
}
