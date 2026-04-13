import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/api_service.dart';

// Events
abstract class WarehouseEvent extends Equatable {
  const WarehouseEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends WarehouseEvent {}

class LoadStock extends WarehouseEvent {}

class LoadAlerts extends WarehouseEvent {}

class ScanBarcode extends WarehouseEvent {
  final String barcode;
  const ScanBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class StartReceiving extends WarehouseEvent {}

class StartPicking extends WarehouseEvent {}

class StartWriteOff extends WarehouseEvent {}

class StartInventory extends WarehouseEvent {}

// States
abstract class WarehouseState extends Equatable {
  const WarehouseState();

  @override
  List<Object?> get props => [];
}

class WarehouseInitial extends WarehouseState {}

class WarehouseLoading extends WarehouseState {}

class DashboardLoaded extends WarehouseState {
  final Map<String, dynamic> stats;
  final List<dynamic> alerts;

  const DashboardLoaded({
    required this.stats,
    required this.alerts,
  });

  @override
  List<Object?> get props => [stats, alerts];
}

class StockLoaded extends WarehouseState {
  final List<dynamic> stock;

  const StockLoaded(this.stock);

  @override
  List<Object?> get props => [stock];
}

class WarehouseError extends WarehouseState {
  final String message;

  const WarehouseError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class WarehouseBloc extends Bloc<WarehouseEvent, WarehouseState> {
  final ApiService _apiService;

  WarehouseBloc(this._apiService) : super(WarehouseInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadStock>(_onLoadStock);
    on<LoadAlerts>(_onLoadAlerts);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      final response = await _apiService.get('/warehouse/stock');
      final alertsResponse = await _apiService.get('/warehouse/alerts');

      // Parse response data
      final responseData = response.data;
      final List<dynamic> stock = responseData is List
          ? responseData
          : (responseData is Map ? (responseData['data'] ?? []) : []);

      final alertsData = alertsResponse.data;
      final List<dynamic> alerts = alertsData is Map
          ? (alertsData['alerts'] ?? alertsData['data'] ?? []) as List<dynamic>
          : [];

      final stats = {
        'totalItems': stock.length,
        'lowStock': stock.where((s) => s is Map && (s['quantity'] as num? ?? 0) < 10).length,
        'expiringSoon': alerts.where((a) => a is Map && a['type'] == 'expiring').length,
        'expired': alerts.where((a) => a is Map && a['type'] == 'expired').length,
      };

      emit(DashboardLoaded(stats: stats, alerts: alerts));
    } catch (e) {
      emit(WarehouseError('Не удалось загрузить данные: $e'));
    }
  }

  Future<void> _onLoadStock(
    LoadStock event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      final response = await _apiService.get('/warehouse/stock');
      final data = response.data;
      final List<dynamic> stock = data is List
          ? data
          : (data is Map ? (data['data'] ?? []) : []);
      emit(StockLoaded(stock));
    } catch (e) {
      emit(WarehouseError('Не удалось загрузить склад: $e'));
    }
  }

  Future<void> _onLoadAlerts(
    LoadAlerts event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      final response = await _apiService.get('/warehouse/alerts');
      final data = response.data;
      final List<dynamic> alerts = data is Map
          ? (data['alerts'] ?? data['data'] ?? []) as List<dynamic>
          : [];
      emit(DashboardLoaded(stats: {}, alerts: alerts));
    } catch (e) {
      emit(WarehouseError('Не удалось загрузить оповещения: $e'));
    }
  }
}
