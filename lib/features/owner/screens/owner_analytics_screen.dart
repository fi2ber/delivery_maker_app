import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../core/di/service_locator.dart';

/// Owner analytics screen — business overview with key metrics, revenue charts, top items
class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  final _api = getIt<ApiService>();

  String _selectedPeriod = 'week';
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/analytics/overview', queryParameters: {
        'period': _selectedPeriod,
      });
      if (mounted) {
        setState(() {
          _analytics = response.data as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analytics = _getMockAnalytics();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockAnalytics() {
    return {
      'revenue': 48500000,
      'revenueGrowth': 12.5,
      'orders': 342,
      'ordersGrowth': 8.3,
      'averageCheck': 141800,
      'averageCheckGrowth': 3.8,
      'customers': 156,
      'customersGrowth': 15.2,
      'deliveries': 298,
      'deliveriesOnTime': 94.2,
      'topProducts': [
        {'name': 'Молоко 1л', 'quantity': 520, 'revenue': 5200000},
        {'name': 'Хлеб белый', 'quantity': 480, 'revenue': 3360000},
        {'name': 'Кефир 0.5л', 'quantity': 350, 'revenue': 4550000},
        {'name': 'Масло сливочное', 'quantity': 280, 'revenue': 5600000},
        {'name': 'Сметана 20%', 'quantity': 210, 'revenue': 3150000},
      ],
      'topCustomers': [
        {'name': 'Магазин "Свежесть"', 'orders': 45, 'revenue': 8500000},
        {'name': 'Маркет "Бозор"', 'orders': 38, 'revenue': 7200000},
        {'name': 'Минимаркет "24/7"', 'orders': 32, 'revenue': 6100000},
      ],
      'revenueByDay': [32.0, 28.5, 41.2, 38.7, 45.1, 48.5, 42.3],
      'dayLabels': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    };
  }

  String _formatCurrency(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M сум';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K сум';
    }
    return '${value.toInt()} сум';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildMainMetrics(),
                    const SizedBox(height: 16),
                    _buildRevenueChart(),
                    const SizedBox(height: 16),
                    _buildDeliveryMetrics(),
                    const SizedBox(height: 20),
                    _buildTopProducts(),
                    const SizedBox(height: 20),
                    _buildTopCustomers(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Аналитика', style: IOSTheme.title2),
        const Spacer(),
        GestureDetector(
          onTap: () {
            IOSTheme.lightImpact();
            _loadAnalytics();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.refresh, size: 20, color: IOSTheme.systemBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'today', 'label': 'Сегодня'},
      {'key': 'week', 'label': 'Неделя'},
      {'key': 'month', 'label': 'Месяц'},
      {'key': 'year', 'label': 'Год'},
    ];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: periods.map((p) {
          final isActive = _selectedPeriod == p['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                IOSTheme.lightImpact();
                setState(() => _selectedPeriod = p['key']!);
                _loadAnalytics();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? IOSTheme.systemBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(2),
                child: Text(
                  p['label']!,
                  style: IOSTheme.caption1.copyWith(
                    color: isActive ? Colors.white : IOSTheme.labelPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainMetrics() {
    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard(
              icon: Icons.payments,
              title: 'Выручка',
              value: _formatCurrency(_analytics['revenue'] ?? 0),
              growth: (_analytics['revenueGrowth'] as num?)?.toDouble(),
              color: IOSTheme.systemGreen,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              icon: Icons.shopping_cart,
              title: 'Заказы',
              value: '${_analytics['orders'] ?? 0}',
              growth: (_analytics['ordersGrowth'] as num?)?.toDouble(),
              color: IOSTheme.systemBlue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMetricCard(
              icon: Icons.receipt_long,
              title: 'Средний чек',
              value: _formatCurrency(_analytics['averageCheck'] ?? 0),
              growth: (_analytics['averageCheckGrowth'] as num?)?.toDouble(),
              color: IOSTheme.systemIndigo,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              icon: Icons.people,
              title: 'Клиенты',
              value: '${_analytics['customers'] ?? 0}',
              growth: (_analytics['customersGrowth'] as num?)?.toDouble(),
              color: IOSTheme.systemOrange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    double? growth,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (growth != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: growth >= 0
                          ? IOSTheme.systemGreen.withOpacity(0.12)
                          : IOSTheme.systemRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growth >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 12,
                          color: growth >= 0
                              ? IOSTheme.systemGreen
                              : IOSTheme.systemRed,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${growth.abs().toStringAsFixed(1)}%',
                          style: IOSTheme.caption2.copyWith(
                            color: growth >= 0
                                ? IOSTheme.systemGreen
                                : IOSTheme.systemRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: IOSTheme.headline),
            const SizedBox(height: 2),
            Text(
              title,
              style:
                  IOSTheme.caption1.copyWith(color: IOSTheme.labelSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final data = (_analytics['revenueByDay'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [0, 0, 0, 0, 0, 0, 0];
    final labels = (_analytics['dayLabels'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Выручка по дням', style: IOSTheme.headline),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final height = maxVal > 0 ? (data[i] / maxVal) * 110 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${data[i].toStringAsFixed(0)}M',
                          style: IOSTheme.caption2.copyWith(
                            color: IOSTheme.labelSecondary,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                IOSTheme.systemBlue,
                                IOSTheme.systemBlue.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: IOSTheme.caption2.copyWith(
                            color: IOSTheme.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMetrics() {
    final deliveries = _analytics['deliveries'] ?? 0;
    final onTime = (_analytics['deliveriesOnTime'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Доставки', style: IOSTheme.headline),
                const SizedBox(height: 4),
                Text(
                  '$deliveries выполнено',
                  style: IOSTheme.subheadline
                      .copyWith(color: IOSTheme.labelSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onTime >= 90
                    ? IOSTheme.systemGreen
                    : IOSTheme.systemOrange,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '${onTime.toStringAsFixed(0)}%',
                style: IOSTheme.headline.copyWith(
                  color: onTime >= 90
                      ? IOSTheme.systemGreen
                      : IOSTheme.systemOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Вовремя',
            style: IOSTheme.caption1.copyWith(color: IOSTheme.labelSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = (_analytics['topProducts'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Топ товары', style: IOSTheme.headline),
        const SizedBox(height: 10),
        ...products.take(5).map((p) {
          final product = p as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: IOSTheme.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2, color: IOSTheme.systemBlue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] ?? '', style: IOSTheme.subheadline),
                      Text(
                        '${product['quantity'] ?? 0} шт',
                        style: IOSTheme.caption1
                            .copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(product['revenue'] ?? 0),
                  style: IOSTheme.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: IOSTheme.systemGreen,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopCustomers() {
    final customers = (_analytics['topCustomers'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Топ клиенты', style: IOSTheme.headline),
        const SizedBox(height: 10),
        ...customers.take(5).map((c) {
          final customer = c as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: IOSTheme.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.store, color: IOSTheme.systemOrange, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'] ?? '', style: IOSTheme.subheadline),
                      Text(
                        '${customer['orders'] ?? 0} заказов',
                        style: IOSTheme.caption1
                            .copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(customer['revenue'] ?? 0),
                  style: IOSTheme.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: IOSTheme.systemGreen,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
