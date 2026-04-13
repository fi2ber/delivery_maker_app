import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/driver_api_service.dart';
import '../models/delivery_stop.dart';

// Events
abstract class DriverApiEvent extends Equatable {
  const DriverApiEvent();

  @override
  List<Object?> get props => [];
}

class LoadDriverRoute extends DriverApiEvent {
  final String driverId;
  const LoadDriverRoute(this.driverId);
}

class PickupOrder extends DriverApiEvent {
  final String orderId;
  final String? notes;
  const PickupOrder(this.orderId, {this.notes});
}

class DeliverOrder extends DriverApiEvent {
  final String orderId;
  final String? photoPath;
  final String? signaturePath;
  final String? notes;
  const DeliverOrder(this.orderId, {this.photoPath, this.signaturePath, this.notes});
}

class DeliveryFailed extends DriverApiEvent {
  final String orderId;
  final String reason;
  const DeliveryFailed(this.orderId, this.reason);
}

// States
class DriverApiState extends Equatable {
  final bool isLoading;
  final List<DeliveryStop> stops;
  final DriverStats? stats;
  final String? error;

  const DriverApiState({
    this.isLoading = false,
    this.stops = const [],
    this.stats,
    this.error,
  });

  DriverApiState copyWith({
    bool? isLoading,
    List<DeliveryStop>? stops,
    DriverStats? stats,
    String? error,
  }) {
    return DriverApiState(
      isLoading: isLoading ?? this.isLoading,
      stops: stops ?? this.stops,
      stats: stats ?? this.stats,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, stops, stats, error];
}

class DriverStats {
  final int total;
  final int pending;
  final int inTransit;
  final int delivered;
  final int completionRate;

  DriverStats({
    required this.total,
    required this.pending,
    required this.inTransit,
    required this.delivered,
    required this.completionRate,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      inTransit: json['inTransit'] ?? 0,
      delivered: json['delivered'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
    );
  }
}

// DeliveryStop is now imported from models/delivery_stop.dart

// BLoC
class DriverApiBloc extends Bloc<DriverApiEvent, DriverApiState> {
  final DriverApiService _apiService;
  final String _driverId;

  DriverApiBloc(this._apiService, this._driverId) : super(const DriverApiState()) {
    on<LoadDriverRoute>(_onLoadRoute);
    on<PickupOrder>(_onPickupOrder);
    on<DeliverOrder>(_onDeliverOrder);
    on<DeliveryFailed>(_onDeliveryFailed);
  }

  Future<void> _onLoadRoute(LoadDriverRoute event, Emitter<DriverApiState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _apiService.getRoute(_driverId);
      
      if (response['success'] == true) {
        final List<dynamic> routeData = response['data'] ?? [];
        final stops = routeData.map((e) => DeliveryStop.fromJson(e)).toList();
        
        // Load stats
        final statsResponse = await _apiService.getTodayStats(_driverId);
        DriverStats? stats;
        if (statsResponse['success'] == true) {
          stats = DriverStats.fromJson(statsResponse['data']);
        }
        
        emit(state.copyWith(
          isLoading: false,
          stops: stops,
          stats: stats,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load route',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Network error: $e',
      ));
    }
  }

  Future<void> _onPickupOrder(PickupOrder event, Emitter<DriverApiState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _apiService.pickupOrder(event.orderId, _driverId, notes: event.notes);
      // Reload route
      add(LoadDriverRoute(_driverId));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to pickup: $e'));
    }
  }

  Future<void> _onDeliverOrder(DeliverOrder event, Emitter<DriverApiState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      // Upload photo and signature files, then send URLs to backend
      await _apiService.deliverOrder(
        event.orderId,
        _driverId,
        photoPath: event.photoPath,
        signaturePath: event.signaturePath,
        notes: event.notes,
      );
      // Reload route
      add(LoadDriverRoute(_driverId));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to deliver: $e'));
    }
  }

  Future<void> _onDeliveryFailed(DeliveryFailed event, Emitter<DriverApiState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _apiService.deliveryFailed(event.orderId, _driverId, event.reason);
      // Reload route
      add(LoadDriverRoute(_driverId));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to mark failed: $e'));
    }
  }
}
