import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api_service.dart';
import 'location_model.dart';
import 'location_tracking_service.dart';

/// Geofence service for monitoring zone entry/exit
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final ApiService _api = ApiService();
  final LocationTrackingService _locationService = LocationTrackingService();
  
  // Active geofences
  final List<Geofence> _geofences = [];
  
  // Track which geofences user is currently inside
  final Set<String> _activeGeofences = {};
  
  StreamSubscription<Position>? _positionStream;
  bool _isMonitoring = false;
  String _userId = '';

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;
  List<Geofence> get activeGeofences => List.unmodifiable(_geofences);

  /// Initialize geofence service
  Future<void> initialize() async {
    await _loadGeofences();
    debugPrint('GeofenceService initialized with ${_geofences.length} geofences');
  }

  /// Load geofences from server
  Future<void> _loadGeofences() async {
    try {
      final response = await _api.get('/tracking/geofences');
      final List<dynamic> data = response.data['geofences'] ?? [];
      
      _geofences.clear();
      _geofences.addAll(data.map((json) => Geofence.fromJson(json)));
    } catch (e) {
      debugPrint('Failed to load geofences: $e');
    }
  }

  /// Start monitoring geofences
  Future<void> startMonitoring({required String userId}) async {
    if (_isMonitoring) return;
    
    _userId = userId;
    await initialize();
    
    _isMonitoring = true;
    
    // Subscribe to position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20, // Check every 20 meters
      ),
    ).listen(_checkGeofences);

    debugPrint('Geofence monitoring started');
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await _positionStream?.cancel();
    _positionStream = null;
    _activeGeofences.clear();
    _userId = '';
    
    debugPrint('Geofence monitoring stopped');
  }

  /// Check current position against all geofences
  void _checkGeofences(Position position) {
    for (final geofence in _geofences) {
      final isInside = geofence.contains(position.latitude, position.longitude);
      final wasInside = _activeGeofences.contains(geofence.id);
      
      if (isInside && !wasInside) {
        // Entered geofence
        _activeGeofences.add(geofence.id);
        _handleGeofenceEvent(
          geofence: geofence,
          eventType: 'enter',
          position: position,
        );
      } else if (!isInside && wasInside) {
        // Exited geofence
        _activeGeofences.remove(geofence.id);
        _handleGeofenceEvent(
          geofence: geofence,
          eventType: 'exit',
          position: position,
        );
      }
    }
  }

  /// Handle geofence enter/exit event
  Future<void> _handleGeofenceEvent({
    required Geofence geofence,
    required String eventType,
    required Position position,
  }) async {
    final event = GeofenceEvent(
      id: '${_userId}_${geofence.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId,
      geofenceId: geofence.id,
      geofenceName: geofence.name,
      eventType: eventType,
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    try {
      await _api.post('/tracking/geofence-events', event.toJson());
      debugPrint('Geofence ${eventType.toUpperCase()}: ${geofence.name}');
      
      // Show local notification
      _showGeofenceNotification(event);
    } catch (e) {
      debugPrint('Failed to send geofence event: $e');
    }
  }

  /// Show local notification for geofence event
  void _showGeofenceNotification(GeofenceEvent event) {
    // This can be integrated with flutter_local_notifications
    debugPrint('[NOTIFICATION] ${event.eventType == 'enter' ? 'Вошли в' : 'Вышли из'}: ${event.geofenceName}');
  }

  /// Add a new geofence (admin only)
  Future<void> addGeofence(Geofence geofence) async {
    try {
      await _api.post('/tracking/geofences', geofence.toJson());
      _geofences.add(geofence);
    } catch (e) {
      debugPrint('Failed to add geofence: $e');
      throw Exception('Failed to add geofence');
    }
  }

  /// Remove a geofence
  Future<void> removeGeofence(String geofenceId) async {
    try {
      await _api.delete('/tracking/geofences/$geofenceId');
      _geofences.removeWhere((g) => g.id == geofenceId);
      _activeGeofences.remove(geofenceId);
    } catch (e) {
      debugPrint('Failed to remove geofence: $e');
      throw Exception('Failed to remove geofence');
    }
  }

  /// Get geofences for a specific customer
  List<Geofence> getGeofencesForCustomer(String customerId) {
    return _geofences.where((g) => g.associatedId == customerId).toList();
  }

  /// Check if currently inside a specific geofence
  bool isInsideGeofence(String geofenceId) {
    return _activeGeofences.contains(geofenceId);
  }

  /// Get current geofence the user is in (if any)
  Geofence? getCurrentGeofence() {
    if (_activeGeofences.isEmpty) return null;
    final id = _activeGeofences.first;
    return _geofences.firstWhere(
      (g) => g.id == id,
      orElse: () => throw Exception('Geofence not found'),
    );
  }

  /// Manual check for geofence entry (for order completion)
  Future<bool> checkCustomerProximity({
    required String customerId,
    required double customerLat,
    required double customerLng,
    double thresholdMeters = 100,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        customerLat,
        customerLng,
      );
      
      debugPrint('Distance to customer: ${distance.toStringAsFixed(1)}m');
      return distance <= thresholdMeters;
    } catch (e) {
      debugPrint('Failed to check proximity: $e');
      return false;
    }
  }

  /// Dispose service
  Future<void> dispose() async {
    await stopMonitoring();
    _geofences.clear();
  }
}
