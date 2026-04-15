import 'package:delivery_maker_app/core/theme/ios_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../services/driver_api_service.dart';
import '../../services/auth_service.dart';
import '../../features/driver/bloc/driver_api_bloc.dart';
import '../../features/driver/models/delivery_stop.dart';
import 'delivery_completion_screen.dart';

/// Route Screen - Main screen for delivery driver
/// Shows list of orders for the day with optimized route
/// Now uses DriverApiBloc for real API data instead of mock
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authService = getIt<AuthService>();
        final driverId = authService.userId ?? 'unknown';
        return DriverApiBloc(
          getIt<DriverApiService>(),
          driverId,
        )..add(LoadDriverRoute(driverId));
      },
      child: const _RouteScreenContent(),
    );
  }
}

class _RouteScreenContent extends StatelessWidget {
  const _RouteScreenContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverApiBloc, DriverApiState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: IOSTheme.systemRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.stops.isEmpty) {
          return Scaffold(
            backgroundColor: IOSTheme.bgSecondary,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(IOSTheme.systemBlue),
              ),
            ),
          );
        }

        final stops = state.stops;
        final stats = state.stats;

        final completedCount = stats?.delivered ?? stops.where((s) => s.isDelivered).length;
        final totalCount = stats?.total ?? stops.length;
        final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

        return Scaffold(
          backgroundColor: IOSTheme.bgSecondary,
          body: RefreshIndicator(
            onRefresh: () async {
              final authService = getIt<AuthService>();
              final driverId = authService.userId ?? 'unknown';
              context.read<DriverApiBloc>().add(LoadDriverRoute(driverId));
            },
            child: CustomScrollView(
              slivers: [
                // Header with progress
                SliverToBoxAdapter(
                  child: _buildHeader(progress, completedCount, totalCount),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: _buildStats(stats, stops),
                ),

                // Section Title
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Маршрут',
                          style: IOSTheme.title2.copyWith(
                            color: IOSTheme.labelPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (state.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),

                // Orders List
                if (stops.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 64, color: IOSTheme.labelTertiary),
                          SizedBox(height: 16),
                          Text(
                            'Нет назначенных заказов',
                            style: TextStyle(
                              fontSize: 18,
                              color: IOSTheme.labelSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Потяните вниз для обновления',
                            style: TextStyle(
                              fontSize: 14,
                              color: IOSTheme.labelTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final stop = stops[index];
                          final isCurrent = index == 0 && stop.isPending;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              stop: stop,
                              isCurrent: isCurrent,
                              onNavigate: () => _openNavigation(context, stop),
                              onCall: () => _callCustomer(stop.phone),
                              onStart: () => _startDelivery(context, stop),
                            ),
                          );
                        },
                        childCount: stops.length,
                      ),
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double progress, int completedCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: IOSTheme.systemBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: IOSTheme.systemBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сегодня',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    Text(
                      'Маршрут доставки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(DriverStats? stats, List<DeliveryStop> stops) {
    final pending = stats?.pending ?? stops.where((s) => s.isPending).length;
    final completed = stats?.delivered ?? stops.where((s) => s.isDelivered).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.schedule,
              value: '$pending',
              label: 'Осталось',
              color: IOSTheme.systemOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              value: '$completed',
              label: 'Выполнено',
              color: IOSTheme.systemGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.percent,
              value: '${stats?.completionRate ?? 0}%',
              label: 'Процент',
              color: IOSTheme.systemPurple,
            ),
          ),
        ],
      ),
    );
  }

  void _openNavigation(BuildContext context, DeliveryStop stop) {
    IOSTheme.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _NavigationSheet(stop: stop),
    );
  }

  void _callCustomer(String? phone) {
    IOSTheme.lightImpact();
    if (phone == null || phone.isEmpty) return;
    // Launch dialer would go here
  }

  void _startDelivery(BuildContext context, DeliveryStop stop) {
    IOSTheme.mediumImpact();
    final order = _stopToDeliveryOrder(stop);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryCompletionScreen(order: order),
      ),
    );
  }

  /// Bridge from DeliveryStop to legacy DeliveryOrder model
  DeliveryOrder _stopToDeliveryOrder(DeliveryStop stop) {
    return DeliveryOrder(
      id: stop.orderCode.isNotEmpty ? stop.orderCode : stop.orderId,
      customerName: stop.customerName,
      address: stop.address,
      phone: stop.phone ?? '',
      totalAmount: 0,
      items: 0,
      status: stop.isDelivered
          ? OrderStatus.completed
          : stop.isInTransit
              ? OrderStatus.current
              : OrderStatus.pending,
      notes: stop.comment ?? '',
      latitude: stop.location.latitude,
      longitude: stop.location.longitude,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryStop stop;
  final bool isCurrent;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final VoidCallback onStart;

  const _OrderCard({
    required this.stop,
    required this.isCurrent,
    required this.onNavigate,
    required this.onCall,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? IOSTheme.systemBlue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: IOSTheme.systemBlue.withOpacity(0.3), width: 2)
            : null,
        boxShadow: IOSTheme.shadowSm,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent ? IOSTheme.systemBlue : IOSTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${stop.sequence > 0 ? stop.sequence : ""}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : IOSTheme.labelPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stop.orderCode,
                        style: TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // StatusBadge(
                //   text: _getStatusText(stop.status),
                //   type: _getStatusType(stop.status),
                // ),
              ],
            ),
          ),

          // Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: IOSTheme.systemBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.address,
                    style: const TextStyle(fontSize: 15, color: IOSTheme.labelPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Comment badge
          if (stop.comment != null && stop.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: IOSTheme.systemYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 14, color: IOSTheme.systemOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stop.comment!,
                        style: const TextStyle(fontSize: 13, color: IOSTheme.systemOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Spacer(),
                _ActionButton(icon: Icons.navigation, color: IOSTheme.systemBlue, onTap: onNavigate),
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.phone, color: IOSTheme.systemGreen, onTap: onCall),
              ],
            ),
          ),

          // Start Delivery Button (only for pending stops)
          if (stop.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? IOSTheme.systemBlue : IOSTheme.bgSecondary,
                    foregroundColor: isCurrent ? Colors.white : IOSTheme.labelPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isCurrent ? 'Начать доставку' : 'Доставить',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(StopStatus status) {
    switch (status) {
      case StopStatus.pending:
        return 'В очереди';
      case StopStatus.inProgress:
        return 'В пути';
      case StopStatus.completed:
        return 'Готово';
      case StopStatus.failed:
        return 'Не доставлено';
    }
  }

  //  _getStatusType(StopStatus status) {
  //   switch (status) {
  //     case StopStatus.pending:
  //       return StatusBadge.pending;
  //     case StopStatus.inProgress:
  //       return StatusBadgeType.info;
  //     case StopStatus.completed:
  //       return StatusBadgeType.success;
  //     case StopStatus.failed:
  //       return StatusBadgeType.error;
  //   }
  // }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: IOSTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: IOSTheme.labelSecondary)),
        ],
      ),
    );
  }
}

class _NavigationSheet extends StatelessWidget {
  final DeliveryStop stop;

  const _NavigationSheet({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(stop.customerName, style: IOSTheme.title2),
          const SizedBox(height: 8),
          Text(
            stop.address,
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _NavigationOption(
                  icon: Icons.navigation,
                  label: 'Google Maps',
                  color: IOSTheme.systemGreen,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavigationOption(
                  icon: Icons.map,
                  label: 'Yandex Maps',
                  color: IOSTheme.systemYellow,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavigationOption(
                  icon: Icons.content_copy,
                  label: 'Копировать',
                  color: IOSTheme.systemBlue,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: stop.address));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Адрес скопирован')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavigationOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// Legacy Data Models (kept for backward compatibility with DeliveryCompletionScreen)
class DeliveryOrder {
  final String id;
  final String customerName;
  final String address;
  final String phone;
  final int totalAmount;
  final int items;
  OrderStatus status;
  final String notes;
  final double latitude;
  final double longitude;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.totalAmount,
    required this.items,
    required this.status,
    required this.notes,
    required this.latitude,
    required this.longitude,
  });
}

enum OrderStatus {
  current,
  pending,
  completed,
}
