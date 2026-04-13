import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

/// Director dashboard — team KPIs, live tracking, reports
class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() =>
      _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  Map<String, dynamic>? _kpis;
  List<dynamic> _activeDrivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiService>();
      try {
        final res = await api.get('/analytics/kpi');
        if (res.data is Map<String, dynamic>) {
          setState(() => _kpis = res.data as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Failed to load KPIs: $e');
      }
      try {
        final res = await api.get('/tracking/drivers/active');
        if (res.data is List) {
          setState(() => _activeDrivers = res.data as List);
        }
      } catch (e) {
        debugPrint('Failed to load active drivers: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = getIt<AuthService>().fullName ?? 'Директор';
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Панель директора', style: IOSTheme.caption),
                      const SizedBox(height: 4),
                      Text(userName, style: IOSTheme.title1),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildKpiGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Активные водители', style: IOSTheme.headline),
                      Text(
                        '${_activeDrivers.length} онлайн',
                        style: IOSTheme.caption
                            .copyWith(color: IOSTheme.systemGreen),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_activeDrivers.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: IOSCard(
                      child: Row(
                        children: [
                          const Icon(Icons.location_off,
                              color: IOSTheme.labelTertiary),
                          const SizedBox(width: 12),
                          Text('Нет активных водителей',
                              style: IOSTheme.bodyMedium
                                  .copyWith(color: IOSTheme.labelTertiary)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildDriverItem(_activeDrivers[i]),
                    childCount: _activeDrivers.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final orders = _kpis?['totalOrdersToday'] ?? 0;
    final delivered = _kpis?['deliveredToday'] ?? 0;
    final revenue = _kpis?['revenueToday'] ?? 0;
    final satisfaction = _kpis?['customerSatisfaction'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  icon: Icons.shopping_cart,
                  value: '$orders',
                  label: 'Заказов сегодня',
                  color: IOSTheme.systemBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  icon: Icons.check_circle,
                  value: '$delivered',
                  label: 'Доставлено',
                  color: IOSTheme.systemGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  icon: Icons.payments,
                  value: _fmt(revenue),
                  label: 'Выручка',
                  color: IOSTheme.systemOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  icon: Icons.star,
                  value: '${satisfaction.toStringAsFixed != null ? (satisfaction is num ? satisfaction.toStringAsFixed(1) : satisfaction) : satisfaction}',
                  label: 'Рейтинг',
                  color: IOSTheme.systemYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final n = v is num ? v : 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toInt()}k';
    return '$n';
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.map,
              label: 'Карта',
              color: IOSTheme.systemBlue,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.people,
              label: 'Команда',
              color: IOSTheme.systemPurple,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.bar_chart,
              label: 'Отчёты',
              color: IOSTheme.systemGreen,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverItem(dynamic driver) {
    final status = driver['status'] ?? 'offline';
    final color = status == 'active'
        ? IOSTheme.systemGreen
        : status == 'idle'
            ? IOSTheme.systemOrange
            : IOSTheme.labelTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IOSCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: IOSTheme.systemBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: IOSTheme.systemBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver['name'] ?? '—', style: IOSTheme.headline),
                  Text('${driver['activeOrders'] ?? 0} заказов',
                      style: IOSTheme.caption),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${driver['speed'] ?? 0} км/ч',
              style: IOSTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _KpiTile({
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: IOSTheme.title2.copyWith(color: color)),
              Text(label, style: IOSTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        IOSTheme.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: IOSTheme.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
