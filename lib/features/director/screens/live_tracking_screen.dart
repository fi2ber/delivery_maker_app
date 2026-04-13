import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../core/di/service_locator.dart';

/// Live tracking screen — shows all active drivers on a map in real-time
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _api = getIt<ApiService>();
  final _mapController = MapController();

  List<Map<String, dynamic>> _drivers = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;
  String? _selectedDriverId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadDrivers();
    // Auto-refresh every 30 seconds
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadDrivers();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadDrivers() async {
    try {
      final response = await _api.get('/tracking/drivers/active');
      if (mounted) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(
            response.data['drivers'] ?? response.data ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Use mock data for demo
          _drivers = _getMockDrivers();
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockDrivers() {
    return [
      {
        'id': '1',
        'name': 'Алишер Каримов',
        'status': 'active',
        'lat': 41.3111,
        'lng': 69.2797,
        'speed': 35.0,
        'activeOrders': 3,
        'completedToday': 12,
        'phone': '+998901234567',
      },
      {
        'id': '2',
        'name': 'Бахтиёр Рахимов',
        'status': 'active',
        'lat': 41.2995,
        'lng': 69.2401,
        'speed': 42.0,
        'activeOrders': 2,
        'completedToday': 8,
        'phone': '+998901234568',
      },
      {
        'id': '3',
        'name': 'Сардор Юсупов',
        'status': 'idle',
        'lat': 41.3250,
        'lng': 69.2200,
        'speed': 0.0,
        'activeOrders': 0,
        'completedToday': 15,
        'phone': '+998901234569',
      },
      {
        'id': '4',
        'name': 'Дилшод Насимов',
        'status': 'offline',
        'lat': 41.2800,
        'lng': 69.2600,
        'speed': 0.0,
        'activeOrders': 0,
        'completedToday': 5,
        'phone': '+998901234570',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredDrivers {
    if (_selectedFilter == 'all') return _drivers;
    return _drivers.where((d) => d['status'] == _selectedFilter).toList();
  }

  int _countByStatus(String status) =>
      _drivers.where((d) => d['status'] == status).length;

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return IOSTheme.systemGreen;
      case 'idle':
        return IOSTheme.systemOrange;
      case 'offline':
        return IOSTheme.systemRed;
      default:
        return IOSTheme.labelSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'На маршруте';
      case 'idle':
        return 'Ожидает';
      case 'offline':
        return 'Офлайн';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),
                  _buildDriverList(),
                  if (_selectedDriverId != null) _buildDriverDetail(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text('Отслеживание', style: IOSTheme.title2),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: IOSTheme.systemGreen.withOpacity(
                    0.5 + 0.5 * _pulseController.value,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: IOSTheme.caption1.copyWith(
              color: IOSTheme.systemGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              IOSTheme.lightImpact();
              _loadDrivers();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh,
                size: 20,
                color: IOSTheme.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final filters = [
      {'key': 'all', 'label': 'Все (${_drivers.length})'},
      {'key': 'active', 'label': 'Активные (${_countByStatus('active')})'},
      {'key': 'idle', 'label': 'Ожидание (${_countByStatus('idle')})'},
      {'key': 'offline', 'label': 'Офлайн (${_countByStatus('offline')})'},
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isActive = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () {
              IOSTheme.lightImpact();
              setState(() => _selectedFilter = f['key']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? IOSTheme.systemBlue
                    : IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                f['label']!,
                style: IOSTheme.caption1.copyWith(
                  color: isActive ? Colors.white : IOSTheme.labelPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(41.2995, 69.2401),
        initialZoom: 12.0,
        onTap: (_, __) {
          setState(() => _selectedDriverId = null);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'uz.deliverymaker.app',
        ),
        MarkerLayer(
          markers: _filteredDrivers.map((driver) {
            final lat = (driver['lat'] as num?)?.toDouble() ?? 41.2995;
            final lng = (driver['lng'] as num?)?.toDouble() ?? 69.2401;
            final status = driver['status'] ?? 'offline';
            final isSelected = driver['id'] == _selectedDriverId;

            return Marker(
              point: LatLng(lat, lng),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () {
                  IOSTheme.mediumImpact();
                  setState(() => _selectedDriverId = driver['id']);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? IOSTheme.systemBlue
                          : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(status).withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDriverList() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              IOSTheme.bgPrimary.withOpacity(0.8),
              IOSTheme.bgPrimary,
            ],
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          itemCount: _filteredDrivers.length,
          itemBuilder: (context, index) {
            final driver = _filteredDrivers[index];
            final isSelected = driver['id'] == _selectedDriverId;

            return GestureDetector(
              onTap: () {
                IOSTheme.lightImpact();
                setState(() => _selectedDriverId = driver['id']);
                final lat = (driver['lat'] as num?)?.toDouble() ?? 41.2995;
                final lng = (driver['lng'] as num?)?.toDouble() ?? 69.2401;
                _mapController.move(LatLng(lat, lng), 14.0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? IOSTheme.systemBlue.withOpacity(0.1)
                      : IOSTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? IOSTheme.systemBlue
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(driver['status'] ?? 'offline'),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            driver['name'] ?? 'Водитель',
                            style: IOSTheme.caption1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${driver['activeOrders'] ?? 0} заказов • ${(driver['speed'] as num?)?.toInt() ?? 0} км/ч',
                      style: IOSTheme.caption2.copyWith(
                        color: IOSTheme.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverDetail() {
    final driver = _drivers.firstWhere(
      (d) => d['id'] == _selectedDriverId,
      orElse: () => <String, dynamic>{},
    );
    if (driver.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(driver['status'] ?? 'offline')
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: _statusColor(driver['status'] ?? 'offline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'] ?? 'Водитель',
                        style: IOSTheme.headline,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(driver['status'] ?? 'offline')
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(driver['status'] ?? 'offline'),
                          style: IOSTheme.caption2.copyWith(
                            color:
                                _statusColor(driver['status'] ?? 'offline'),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedDriverId = null),
                  child: Icon(
                    Icons.close,
                    color: IOSTheme.labelSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDetailStat(
                  Icons.speed,
                  '${(driver['speed'] as num?)?.toInt() ?? 0} км/ч',
                  'Скорость',
                ),
                _buildDetailStat(
                  Icons.shopping_bag,
                  '${driver['activeOrders'] ?? 0}',
                  'Активных',
                ),
                _buildDetailStat(
                  Icons.check_circle,
                  '${driver['completedToday'] ?? 0}',
                  'Выполнено',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: IOSTheme.systemBlue),
          const SizedBox(height: 4),
          Text(value, style: IOSTheme.headline),
          Text(
            label,
            style: IOSTheme.caption2.copyWith(color: IOSTheme.labelSecondary),
          ),
        ],
      ),
    );
  }
}
