import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/sales_api_service.dart';

/// Sales analytics — revenue, top products, top customers
class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _topProducts = [];
  List<dynamic> _topCustomers = [];
  bool _isLoading = true;
  String _period = 'month'; // 'week' | 'month'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<SalesApiService>();

      try {
        final s = await api.getDashboardStats();
        setState(() => _stats = s);
      } catch (e) {
        debugPrint('Stats error: $e');
      }

      try {
        final products = await api.getTopProducts(limit: 5);
        setState(() => _topProducts = products);
      } catch (e) {
        debugPrint('Top products error: $e');
      }

      try {
        final customers = await api.getTopCustomers(limit: 5);
        setState(() => _topCustomers = customers);
      } catch (e) {
        debugPrint('Top customers error: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Аналитика продаж', style: IOSTheme.title1),
                      _buildPeriodSwitch(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildKpiRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildRevenueChart()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Топ продуктов', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_isLoading)
                const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator())))
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildProductItem(_topProducts[i], i),
                    childCount: _topProducts.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Топ клиентов', style: IOSTheme.headline),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildCustomerItem(_topCustomers[i], i),
                    childCount: _topCustomers.length,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.fill,
        borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodBtn(
            label: 'Неделя',
            isActive: _period == 'week',
            onTap: () => setState(() => _period = 'week'),
          ),
          _PeriodBtn(
            label: 'Месяц',
            isActive: _period == 'month',
            onTap: () => setState(() => _period = 'month'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final revenue = _stats?['totalRevenue'] ?? 0;
    final orders = _stats?['totalOrders'] ?? 0;
    final avgOrder = orders > 0
        ? ((revenue is num ? revenue : 0) / (orders is num ? orders : 1))
            .round()
        : 0;
    final convRate = _stats?['conversionRate'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.payments,
                  value: _fmt(revenue),
                  label: 'Выручка',
                  color: IOSTheme.systemGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.shopping_bag,
                  value: '$orders',
                  label: 'Заказов',
                  color: IOSTheme.systemBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.receipt,
                  value: _fmt(avgOrder),
                  label: 'Средний чек',
                  color: IOSTheme.systemOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.trending_up,
                  value: '$convRate%',
                  label: 'Конверсия',
                  color: IOSTheme.systemPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final daily = _stats?['dailyRevenue'] as List? ?? _mockDailyRevenue();
    final maxVal = daily
        .map((e) => (e is Map ? (e['amount'] ?? 0) : 0) as num)
        .fold<num>(1, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IOSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Выручка по дням', style: IOSTheme.headline),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daily.length, (i) {
                  final item = daily[i] is Map ? daily[i] as Map : {};
                  final amount = (item['amount'] ?? 0) as num;
                  final h = maxVal > 0 ? (amount / maxVal).toDouble() : 0.05;
                  final label = item['day']?.toString() ??
                      (i + 1).toString().padLeft(2, '0');
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (h * 90).clamp(4, 90),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  IOSTheme.systemGreen.withOpacity(0.6),
                                  IOSTheme.systemGreen,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 9, color: IOSTheme.labelTertiary)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic product, int index) {
    final name = product['name'] ?? product['title'] ?? 'Продукт';
    final quantity = product['totalQuantity'] ?? product['quantity'] ?? 0;
    final revenue = product['totalRevenue'] ?? product['revenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IOSCard(
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _rankColor(index).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                      color: _rankColor(index),
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: IOSTheme.headline),
                  Text('$quantity шт', style: IOSTheme.caption),
                ],
              ),
            ),
            Text(
              '${_fmt(revenue)} сум',
              style:
                  IOSTheme.bodyMedium.copyWith(color: IOSTheme.systemGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(dynamic customer, int index) {
    final name = customer['firstName'] != null
        ? '${customer['firstName']} ${customer['lastName'] ?? ''}'.trim()
        : (customer['name'] ?? 'Клиент');
    final orders = customer['totalOrders'] ?? customer['ordersCount'] ?? 0;
    final revenue = customer['totalRevenue'] ?? customer['revenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IOSCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: IOSTheme.systemBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: IOSTheme.systemBlue,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: IOSTheme.headline),
                  Text('$orders заказов', style: IOSTheme.caption),
                ],
              ),
            ),
            Text(
              '${_fmt(revenue)} сум',
              style:
                  IOSTheme.bodyMedium.copyWith(color: IOSTheme.systemBlue),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return IOSTheme.systemYellow;
      case 1:
        return IOSTheme.labelSecondary;
      case 2:
        return IOSTheme.systemOrange;
      default:
        return IOSTheme.systemBlue;
    }
  }

  String _fmt(dynamic v) {
    final n = v is num ? v : 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toInt()}k';
    return '$n';
  }

  List<Map<String, dynamic>> _mockDailyRevenue() {
    final days = _period == 'week'
        ? ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
        : List.generate(
            DateTime.now().day, (i) => (i + 1).toString().padLeft(2, '0'));
    return days
        .asMap()
        .entries
        .map((e) => {'day': e.value, 'amount': 100000 + (e.key * 50000) % 500000})
        .toList();
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _KpiCard({
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: IOSTheme.title2.copyWith(color: color)),
                Text(label, style: IOSTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PeriodBtn(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        IOSTheme.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? IOSTheme.systemBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : IOSTheme.labelSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
