import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api_service.dart';
import 'location_model.dart';

/// Location tracking service for employee monitoring
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final ApiService _api = ApiService();
  
  StreamSubscription<Position>? _positionStream;
  Timer? _batchUploadTimer;
  
  bool _isTracking = false;
  String _currentUserId = '';
  String _currentUserRole = '';
  
  // Cache for offline tracking
  final List<LocationPoint> _locationCache = [];
  
  /// Get current tracking status
  bool get isTracking => _isTracking;
  String get currentUserId => _currentUserId;

  /// Initialize location settings
  Future<void> initialize() async {
    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable in settings.');
    }

    debugPrint('LocationTrackingService initialized');
  }

  /// Start tracking location
  Future<void> startTracking({
    required String userId,
    required String userRole,
    Duration uploadInterval = const Duration(seconds: 30),
  }) async {
    if (_isTracking) {
      debugPrint('Tracking already active');
      return;
    }
    
    await initialize();
    
    _isTracking = true;
    _currentUserId = userId;
    _currentUserRole = userRole;
    
    // Configure location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );

    // Start batch upload timer
    _batchUploadTimer = Timer.periodic(uploadInterval, (_) {
      _uploadCachedLocations();
    });

    // Record shift start
    await _recordShiftEvent(eventType: 'shift_start');

    debugPrint('Location tracking started for user: $userId');
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    _isTracking = false;
    
    // Cancel streams and timers
    await _positionStream?.cancel();
    _positionStream = null;
    _batchUploadTimer?.cancel();
    _batchUploadTimer = null;

    // Upload remaining cached locations
    await _uploadCachedLocations();

    // Record shift end
    await _recordShiftEvent(eventType: 'shift_end');

    debugPrint('Location tracking stopped for user: $_currentUserId');
    _currentUserId = '';
    _currentUserRole = '';
  }

  /// Handle position update
  void _onPositionUpdate(Position position) {
    if (_currentUserId.isEmpty) return;
    
    final locationPoint = LocationPoint(
      id: '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId,
      userRole: _currentUserRole,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      timestamp: position.timestamp ?? DateTime.now(),
    );

    _locationCache.add(locationPoint);
    
    // Keep cache size manageable (keep last 100 points)
    if (_locationCache.length > 100) {
      _locationCache.removeAt(0);
    }

    // Check for speed violations
    if (position.speed > 25) { // 90 km/h
      _reportSpeedViolation(position.speed);
    }

    debugPrint('Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} | Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h');
  }

  /// Upload cached locations to server
  Future<void> _uploadCachedLocations() async {
    if (_locationCache.isEmpty || _currentUserId.isEmpty) return;

    final locationsToUpload = List<LocationPoint>.from(_locationCache);
    _locationCache.clear();

    try {
      await _api.post('/tracking/locations/batch', {
        'userId': _currentUserId,
        'userRole': _currentUserRole,
        'locations': locationsToUpload.map((l) => l.toJson()).toList(),
      });
      
      debugPrint('Uploaded ${locationsToUpload.length} locations');
    } catch (e) {
      debugPrint('Failed to upload locations: $e');
      // Put back in cache for retry (limit to 50)
      _locationCache.insertAll(0, locationsToUpload.take(50));
    }
  }

  /// Record shift start/end event
  Future<void> _recordShiftEvent({
    required String eventType,
  }) async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition();
      
      await _api.post('/tracking/shift-events', {
        'userId': _currentUserId,
        'eventType': eventType, // 'shift_start', 'shift_end'
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      
      debugPrint('Shift event recorded: $eventType');
    } catch (e) {
      debugPrint('Failed to record shift event: $e');
    }
  }

  /// Report speed violation
  Future<void> _reportSpeedViolation(double speedMs) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      
      await _api.post('/tracking/violations', {
        'userId': _currentUserId,
        'type': 'speeding',
        'speedKmh': (speedMs * 3.6).round(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Speed violation reported: ${(speedMs * 3.6).round()} km/h');
    } catch (e) {
      debugPrint('Failed to report speed violation: $e');
    }
  }

  /// Get current position
  Future<LocationPoint?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LocationPoint(
        id: '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId,
        userRole: _currentUserRole,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        heading: position.heading,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to get current position: $e');
      return null;
    }
  }

  /// Toggle tracking (start/stop)
  Future<void> toggleTracking({
    required String userId,
    required String userRole,
  }) async {
    if (_isTracking) {
      await stopTracking();
    } else {
      await startTracking(userId: userId, userRole: userRole);
    }
  }

  /// Dispose service
  Future<void> dispose() async {
    await stopTracking();
  }
}
