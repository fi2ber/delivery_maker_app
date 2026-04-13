import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

enum ShiftStatus { offDuty, onDuty, onBreak }

class ShiftControlPanel extends StatefulWidget {
  final VoidCallback? onStatusChanged;

  const ShiftControlPanel({super.key, this.onStatusChanged});

  @override
  State<ShiftControlPanel> createState() => _ShiftControlPanelState();
}

class _ShiftControlPanelState extends State<ShiftControlPanel> {
  ShiftStatus _status = ShiftStatus.offDuty;
  DateTime? _shiftStartTime;
  String? _workSessionId;
  bool _isSending = false;

  String get _userId {
    try {
      return getIt<AuthService>().userId ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  ApiService get _api {
    try {
      return getIt<ApiService>();
    } catch (_) {
      return ApiService();
    }
  }

  Future<void> _toggleDuty() async {
    if (_isSending) return;
    IOSTheme.mediumImpact();

    setState(() => _isSending = true);

    try {
      if (_status == ShiftStatus.offDuty) {
        // Start shift
        final now = DateTime.now();
        final sessionId = '${_userId}_${now.millisecondsSinceEpoch}';

        // Record shift start event
        await _api.post('/tracking/shift-events', {
          'userId': _userId,
          'eventType': 'shift_start',
          'timestamp': now.toIso8601String(),
          'latitude': 0.0,
          'longitude': 0.0,
        });

        // Start work session
        await _api.post('/tracking/work-sessions', {
          'id': sessionId,
          'userId': _userId,
          'startTime': now.toIso8601String(),
          'startLat': 0.0,
          'startLng': 0.0,
        });

        setState(() {
          _status = ShiftStatus.onDuty;
          _shiftStartTime = now;
          _workSessionId = sessionId;
        });
      } else {
        // End shift
        final now = DateTime.now();
        final duration = _shiftStartTime != null
            ? now.difference(_shiftStartTime!)
            : Duration.zero;

        // Record shift end event
        await _api.post('/tracking/shift-events', {
          'userId': _userId,
          'eventType': 'shift_end',
          'timestamp': now.toIso8601String(),
          'latitude': 0.0,
          'longitude': 0.0,
        });

        // End work session
        if (_workSessionId != null) {
          await _api.put('/tracking/work-sessions/$_workSessionId', {
            'endTime': now.toIso8601String(),
            'endLat': 0.0,
            'endLng': 0.0,
            'totalWorkTimeMinutes': duration.inMinutes,
            'totalBreakTimeMinutes': 0,
          });
        }

        setState(() {
          _status = ShiftStatus.offDuty;
          _shiftStartTime = null;
          _workSessionId = null;
        });
      }
    } catch (e) {
      debugPrint('Shift toggle error: $e');
      // Still update UI even on error (offline-first)
      setState(() {
        if (_status == ShiftStatus.offDuty) {
          _status = ShiftStatus.onDuty;
          _shiftStartTime = DateTime.now();
        } else {
          _status = ShiftStatus.offDuty;
          _shiftStartTime = null;
          _workSessionId = null;
        }
      });
    } finally {
      setState(() => _isSending = false);
    }

    widget.onStatusChanged?.call();
  }

  Future<void> _toggleBreak() async {
    if (_status == ShiftStatus.offDuty || _isSending) return;
    IOSTheme.lightImpact();

    setState(() => _isSending = true);

    try {
      final now = DateTime.now();

      if (_status == ShiftStatus.onBreak) {
        // End break
        await _api.post('/tracking/break-events', {
          'userId': _userId,
          'sessionId': _workSessionId ?? '',
          'eventType': 'break_end',
          'timestamp': now.toIso8601String(),
        });
        setState(() => _status = ShiftStatus.onDuty);
      } else {
        // Start break
        await _api.post('/tracking/break-events', {
          'userId': _userId,
          'sessionId': _workSessionId ?? '',
          'eventType': 'break_start',
          'timestamp': now.toIso8601String(),
          'reason': 'Перерыв',
        });
        setState(() => _status = ShiftStatus.onBreak);
      }
    } catch (e) {
      debugPrint('Break toggle error: $e');
      // Still update UI even on error (offline-first)
      setState(() {
        _status = _status == ShiftStatus.onBreak
            ? ShiftStatus.onDuty
            : ShiftStatus.onBreak;
      });
    } finally {
      setState(() => _isSending = false);
    }

    widget.onStatusChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnDuty = _status != ShiftStatus.offDuty;
    final bool isOnBreak = _status == ShiftStatus.onBreak;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: IOSTheme.radiusMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnDuty
                          ? (isOnBreak ? IOSTheme.systemOrange : IOSTheme.systemGreen)
                          : IOSTheme.systemRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnDuty
                        ? (isOnBreak ? 'Перерыв' : 'На линии')
                        : 'Смена закрыта',
                    style: IOSTheme.headline,
                  ),
                ],
              ),
              if (isOnDuty && _shiftStartTime != null)
                Text(
                  _formatDuration(DateTime.now().difference(_shiftStartTime!)),
                  style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                )
              else
                Text(
                  '--:--',
                  style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: IOSButton(
                  text: _isSending
                      ? '...'
                      : isOnDuty
                          ? 'Завершить'
                          : 'Начать смену',
                  isPrimary: !isOnDuty,
                  isDestructive: isOnDuty,
                  icon: isOnDuty ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                  onPressed: _isSending ? null : _toggleDuty,
                ),
              ),
              if (isOnDuty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: IOSButton(
                    text: isOnBreak ? 'Продолжить' : 'Пауза',
                    isPrimary: false,
                    onPressed: _isSending ? null : _toggleBreak,
                    icon: isOnBreak ? Icons.play_arrow : Icons.pause,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}';
  }
}
