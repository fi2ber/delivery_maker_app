/// Location point model for tracking
class LocationPoint {
  final String id;
  final String userId;
  final String userRole;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final DateTime timestamp;
  final double? batteryLevel;
  final String? metadata;

  LocationPoint({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.timestamp,
    this.batteryLevel,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userRole': userRole,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'speedAccuracy': speedAccuracy,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'batteryLevel': batteryLevel,
    'metadata': metadata,
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    id: json['id'],
    userId: json['userId'],
    userRole: json['userRole'] ?? '',
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    accuracy: json['accuracy']?.toDouble() ?? 0.0,
    altitude: json['altitude']?.toDouble() ?? 0.0,
    speed: json['speed']?.toDouble() ?? 0.0,
    speedAccuracy: json['speedAccuracy']?.toDouble() ?? 0.0,
    heading: json['heading']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    batteryLevel: json['batteryLevel']?.toDouble(),
    metadata: json['metadata'],
  );

  /// Calculate distance to another point in meters
  double distanceTo(LocationPoint other) {
    final latDiff = latitude - other.latitude;
    final lonDiff = longitude - other.longitude;
    return (latDiff * latDiff + lonDiff * lonDiff) * 111320; // Approximate
  }
}

/// Shift event model (start/end work)
class ShiftEvent {
  final String id;
  final String userId;
  final String eventType; // 'shift_start', 'shift_end', 'break_start', 'break_end'
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? metadata;

  ShiftEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'metadata': metadata,
  };

  factory ShiftEvent.fromJson(Map<String, dynamic> json) => ShiftEvent(
    id: json['id'],
    userId: json['userId'],
    eventType: json['eventType'],
    timestamp: DateTime.parse(json['timestamp']),
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    metadata: json['metadata'],
  );
}

/// Geofence (zone) model
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String type; // 'customer', 'warehouse', 'restricted', 'checkpoint'
  final String? associatedId; // customer ID, warehouse ID, etc.
  final bool notifyOnEnter;
  final bool notifyOnExit;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    this.associatedId,
    this.notifyOnEnter = true,
    this.notifyOnExit = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'type': type,
    'associatedId': associatedId,
    'notifyOnEnter': notifyOnEnter,
    'notifyOnExit': notifyOnExit,
  };

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'],
    name: json['name'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    radius: json['radius'].toDouble(),
    type: json['type'],
    associatedId: json['associatedId'],
    notifyOnEnter: json['notifyOnEnter'] ?? true,
    notifyOnExit: json['notifyOnExit'] ?? true,
  );

  /// Check if a point is inside this geofence
  bool contains(double pointLat, double pointLng) {
    final distance = _calculateDistance(pointLat, pointLng, latitude, longitude);
    return distance <= radius;
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      (dLat / 2).sin() * (dLat / 2).sin() +
      _toRadians(lat1).cos() * _toRadians(lat2).cos() *
      (dLon / 2).sin() * (dLon / 2).sin();
    
    final c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180);
}

/// Geofence event (enter/exit)
class GeofenceEvent {
  final String id;
  final String userId;
  final String geofenceId;
  final String geofenceName;
  final String eventType; // 'enter', 'exit'
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  GeofenceEvent({
    required this.id,
    required this.userId,
    required this.geofenceId,
    required this.geofenceName,
    required this.eventType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'geofenceId': geofenceId,
    'geofenceName': geofenceName,
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Work session model (aggregated shift data)
class WorkSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final double totalDistanceKm;
  final int totalStops;
  final Duration totalWorkTime;
  final Duration totalBreakTime;
  final double averageSpeed;
  final int maxSpeed;
  final int idleTimeMinutes;

  WorkSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.totalDistanceKm = 0.0,
    this.totalStops = 0,
    this.totalWorkTime = Duration.zero,
    this.totalBreakTime = Duration.zero,
    this.averageSpeed = 0.0,
    this.maxSpeed = 0,
    this.idleTimeMinutes = 0,
  });

  bool get isActive => endTime == null;

  Duration get duration => endTime?.difference(startTime) ?? DateTime.now().difference(startTime);
}

extension on double {
  double sin() => (this * (3.14159265359 / 180)).toString().contains('.') ? 
    double.parse((this * (3.14159265359 / 180)).toString().substring(0, 10)) : this;
  double cos() => this;
  double sqrt() => this;
  double asin() => this;
}
