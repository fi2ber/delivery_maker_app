import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api_service.dart';
import 'location_model.dart';

/// Service for tracking work time, breaks, and productivity
class WorkTimeService {
  static final WorkTimeService _instance = WorkTimeService._internal();
  factory WorkTimeService() => _instance;
  WorkTimeService._internal();

  final ApiService _api = ApiService();
  
  WorkSession? _currentSession;
  Timer? _activityTimer;
  
  // Tracking state
  DateTime? _lastActivityTime;
  bool _isOnBreak = false;
  Duration _totalBreakTime = Duration.zero;
  DateTime? _breakStartTime;
  
  // Idle detection
  Position? _lastPosition;
  int _idleMinutes = 0;
  static const int idleThresholdMinutes = 10;

  /// Getters
  WorkSession? get currentSession => _currentSession;
  bool get isWorking => _currentSession != null && !_isOnBreak;
  bool get isOnBreak => _isOnBreak;
  Duration get currentWorkTime => _calculateCurrentWorkTime();

  /// Calculate current work time excluding breaks
  Duration _calculateCurrentWorkTime() {
    if (_currentSession == null) return Duration.zero;
    
    final totalElapsed = DateTime.now().difference(_currentSession!.startTime);
    return totalElapsed - _totalBreakTime;
  }

  /// Start work shift
  Future<WorkSession> startShift(String userId) async {
    if (_currentSession != null) {
      throw Exception('Shift already started');
    }

    final position = await Geolocator.getCurrentPosition();
    
    _currentSession = WorkSession(
      id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      startTime: DateTime.now(),
      startLat: position.latitude,
      startLng: position.longitude,
    );

    // Start activity monitoring
    _startActivityMonitoring();

    // Send to server
    try {
      await _api.post('/tracking/work-sessions', {
        'id': _currentSession!.id,
        'userId': userId,
        'startTime': _currentSession!.startTime.toIso8601String(),
        'startLat': position.latitude,
        'startLng': position.longitude,
      });
    } catch (e) {
      debugPrint('Failed to record shift start: $e');
    }

    debugPrint('Work shift started: ${_currentSession!.id}');
    return _currentSession!;
  }

  /// End work shift
  Future<WorkSession?> endShift() async {
    if (_currentSession == null) return null;

    // End break if active
    if (_isOnBreak) {
      await endBreak();
    }

    final position = await Geolocator.getCurrentPosition();
    
    final completedSession = WorkSession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      startLat: _currentSession!.startLat,
      startLng: _currentSession!.startLng,
      endLat: position.latitude,
      endLng: position.longitude,
      totalWorkTime: currentWorkTime,
      totalBreakTime: _totalBreakTime,
    );

    // Stop monitoring
    _stopActivityMonitoring();

    // Send to server
    try {
      await _api.put('/tracking/work-sessions/${completedSession.id}', {
        'endTime': completedSession.endTime!.toIso8601String(),
        'endLat': position.latitude,
        'endLng': position.longitude,
        'totalWorkTimeMinutes': completedSession.totalWorkTime.inMinutes,
        'totalBreakTimeMinutes': completedSession.totalBreakTime.inMinutes,
      });
    } catch (e) {
      debugPrint('Failed to record shift end: $e');
    }

    // Reset state
    _currentSession = null;
    _totalBreakTime = Duration.zero;
    _idleMinutes = 0;

    debugPrint('Work shift ended. Duration: ${completedSession.totalWorkTime.inHours}h ${completedSession.totalWorkTime.inMinutes % 60}m');
    return completedSession;
  }

  /// Start break
  Future<void> startBreak({String? reason}) async {
    if (_currentSession == null) throw Exception('No active shift');
    if (_isOnBreak) throw Exception('Already on break');

    _isOnBreak = true;
    _breakStartTime = DateTime.now();

    try {
      await _api.post('/tracking/break-events', {
        'userId': _currentSession!.userId,
        'sessionId': _currentSession!.id,
        'eventType': 'break_start',
        'timestamp': _breakStartTime!.toIso8601String(),
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Failed to record break start: $e');
    }

    debugPrint('Break started');
  }

  /// End break
  Future<void> endBreak() async {
    if (!_isOnBreak) return;

    final breakEnd = DateTime.now();
    final breakDuration = breakEnd.difference(_breakStartTime!);
    _totalBreakTime += breakDuration;

    _isOnBreak = false;
    _breakStartTime = null;

    try {
      await _api.post('/tracking/break-events', {
        'userId': _currentSession!.userId,
        'sessionId': _currentSession!.id,
        'eventType': 'break_end',
        'timestamp': breakEnd.toIso8601String(),
        'durationMinutes': breakDuration.inMinutes,
      });
    } catch (e) {
      debugPrint('Failed to record break end: $e');
    }

    debugPrint('Break ended. Duration: ${breakDuration.inMinutes}m');
  }

  /// Start activity monitoring (idle detection)
  void _startActivityMonitoring() {
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkActivity();
    });
  }

  /// Stop activity monitoring
  void _stopActivityMonitoring() {
    _activityTimer?.cancel();
    _activityTimer = null;
  }

  /// Check for idle state
  Future<void> _checkActivity() async {
    if (_currentSession == null || _isOnBreak) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < 50) {
          // Less than 50 meters movement
          _idleMinutes++;
          
          if (_idleMinutes >= idleThresholdMinutes) {
            _reportIdleTime();
          }
        } else {
          _idleMinutes = 0;
        }
      }

      _lastPosition = position;
    } catch (e) {
      debugPrint('Failed to check activity: $e');
    }
  }

  /// Report idle time to server
  Future<void> _reportIdleTime() async {
    try {
      await _api.post('/tracking/idle-events', {
        'userId': _currentSession!.userId,
        'sessionId': _currentSession!.id,
        'idleMinutes': _idleMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Idle time reported: $_idleMinutes minutes');
    } catch (e) {
      debugPrint('Failed to report idle time: $e');
    }
  }

  /// Record stop/delivery completion
  Future<void> recordStop({
    required String orderId,
    required String customerName,
    required double lat,
    required double lng,
    required Duration timeSpent,
  }) async {
    if (_currentSession == null) return;

    try {
      await _api.post('/tracking/stops', {
        'userId': _currentSession!.userId,
        'sessionId': _currentSession!.id,
        'orderId': orderId,
        'customerName': customerName,
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
        'timeSpentMinutes': timeSpent.inMinutes,
      });
      
      debugPrint('Stop recorded: $customerName (${timeSpent.inMinutes}m)');
    } catch (e) {
      debugPrint('Failed to record stop: $e');
    }
  }

  /// Get work history
  Future<List<WorkSession>> getWorkHistory(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _api.get('/tracking/work-sessions', queryParameters: {
        'userId': userId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      });

      final List<dynamic> data = response.data['sessions'] ?? [];
      return data.map((json) => _workSessionFromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to get work history: $e');
      return [];
    }
  }

  WorkSession _workSessionFromJson(Map<String, dynamic> json) => WorkSession(
    id: json['id'],
    userId: json['userId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    startLat: json['startLat']?.toDouble(),
    startLng: json['startLng']?.toDouble(),
    endLat: json['endLat']?.toDouble(),
    endLng: json['endLng']?.toDouble(),
    totalDistanceKm: json['totalDistanceKm']?.toDouble() ?? 0.0,
    totalStops: json['totalStops'] ?? 0,
    totalWorkTime: Duration(minutes: json['totalWorkTimeMinutes'] ?? 0),
    totalBreakTime: Duration(minutes: json['totalBreakTimeMinutes'] ?? 0),
  );

  /// Get today's work stats
  Future<Map<String, dynamic>> getTodayStats(String userId) async {
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day);
    
    final sessions = await getWorkHistory(userId, from: from);
    
    Duration totalWork = Duration.zero;
    Duration totalBreak = Duration.zero;
    int totalStops = 0;
    double totalDistance = 0.0;
    
    for (final session in sessions) {
      totalWork += session.totalWorkTime;
      totalBreak += session.totalBreakTime;
      totalStops += session.totalStops;
      totalDistance += session.totalDistanceKm;
    }

    return {
      'shifts': sessions.length,
      'workHours': totalWork.inHours + (totalWork.inMinutes % 60) / 60,
      'breakMinutes': totalBreak.inMinutes,
      'stops': totalStops,
      'distanceKm': totalDistance.toStringAsFixed(1),
    };
  }

  /// Dispose service
  Future<void> dispose() async {
    if (_currentSession != null) {
      await endShift();
    }
    _stopActivityMonitoring();
  }
}
