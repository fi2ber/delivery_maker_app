import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../services/sales_api_service.dart';
import 'catalog_screen.dart';
import 'customer_search_screen.dart';
import 'my_customers_screen.dart';

/// Sales home with dashboard stats
class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final salesApi = getIt<SalesApiService>();

      // Load stats
      try {
        final stats = await salesApi.getDashboardStats();
        setState(() => _stats = stats);
      } catch (e) {
        debugPrint('Failed to load stats: $e');
      }

      // Load recent orders
      try {
        final orders = await salesApi.getMyOrders();
        setState(() => _recentOrders = orders.take(5).toList());
      } catch (e) {
        debugPrint('Failed to load orders: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final userName = authService.fullName ?? 'Менеджер';

    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Добро пожаловать!', style: IOSTheme.caption),
                      const SizedBox(height: 4),
                      Text(userName, style: IOSTheme.title1),
                    ],
                  ),
                ),
              ),

              // Stats cards
              SliverToBoxAdapter(child: _buildStatsSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Быстрые действия', style: IOSTheme.headline),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(child: _buildQuickActions(context)),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Последние заказы', style: IOSTheme.headline),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (_recentOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: IOSTheme.labelTertiary),
                        const SizedBox(height: 12),
                        Text('Нет заказов',
                            style: IOSTheme.bodyMedium
                                .copyWith(color: IOSTheme.labelTertiary)),
                        const SizedBox(height: 8),
                        Text('Создайте первый заказ!',
                            style: IOSTheme.caption),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = _recentOrders[index];
                      return _buildOrderCard(order);
                    },
                    childCount: _recentOrders.length,
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totalOrders = _stats?['totalOrders'] ?? 0;
    final completedOrders = _stats?['completedOrders'] ?? 0;
    final revenue = _stats?['totalRevenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.shopping_bag,
              value: '$totalOrders',
              label: 'Заказов',
              color: IOSTheme.systemBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              value: '$completedOrders',
              label: 'Доставлено',
              color: IOSTheme.systemGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.payments,
              value: _formatRevenue(revenue),
              label: 'Выручка',
              color: IOSTheme.systemOrange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRevenue(dynamic amount) {
    final num val = amount is num ? amount : 0;
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toInt()}k';
    }
    return '$val';
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, style: IOSTheme.headline),
                  const SizedBox(height: 4),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} сум',
                    style: IOSTheme.body,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return IOSTheme.systemGreen;
      case 'pending':
        return IOSTheme.systemOrange;
      case 'cancelled':
        return IOSTheme.systemRed;
      default:
        return IOSTheme.systemBlue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Доставлен';
      case 'pending':
        return 'Ожидает';
      case 'processing':
        return 'Обработка';
      case 'cancelled':
        return 'Отменён';
      default:
        return status;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ActionCard(
            icon: Icons.storefront,
            title: 'Каталог продуктов',
            subtitle: 'Создать заказ из каталога',
            color: IOSTheme.systemBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.person_add,
            title: 'Новый клиент',
            subtitle: 'Зарегистрировать клиента',
            color: IOSTheme.systemGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CustomerSearchScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.people_outline,
            title: 'Мои клиенты',
            subtitle: 'Список и история',
            color: IOSTheme.systemPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyCustomersScreen()),
              );
            },
          ),
        ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: IOSTheme.title2.copyWith(color: color)),
          Text(label,
              style: IOSTheme.caption.copyWith(color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IOSCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IOSTheme.headline),
                Text(subtitle, style: IOSTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}