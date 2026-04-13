import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

/// Owner dashboard — financial overview, employees, settings
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  Map<String, dynamic>? _overview;
  List<dynamic> _employees = [];
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
        final res = await api.get('/analytics/dashboard');
        if (res.data is Map<String, dynamic>) {
          setState(() => _overview = res.data as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Failed to load overview: $e');
      }
      try {
        final res = await api.get('/users', queryParameters: {'limit': 10});
        if (res.data is List) {
          setState(() => _employees = res.data as List);
        }
      } catch (e) {
        debugPrint('Failed to load employees: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = getIt<AuthService>().fullName ?? 'Владелец';
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
                      Text('Обзор бизнеса', style: IOSTheme.caption),
                      const SizedBox(height: 4),
                      Text(userName, style: IOSTheme.title1),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildFinancialOverview()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Управление', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildManagementActions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Сотрудники', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_employees.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: IOSTheme.labelTertiary),
                        const SizedBox(height: 12),
                        Text('Нет сотрудников',
                            style: IOSTheme.bodyMedium
                                .copyWith(color: IOSTheme.labelTertiary)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildEmployeeItem(_employees[i]),
                    childCount: _employees.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final revenue = _overview?['monthRevenue'] ?? 0;
    final growth = _overview?['revenueGrowth'] ?? 0;
    final orders = _overview?['monthOrders'] ?? 0;
    final employees = _overview?['employeeCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Main revenue card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(IOSTheme.radius2Xl),
              boxShadow: IOSTheme.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выручка за месяц',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fmt(revenue)} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      growth >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white70,
                      size: 14,
                    ),
                    Text(
                      ' ${growth.abs()}% vs прошлый месяц',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  icon: Icons.receipt,
                  value: '$orders',
                  label: 'Заказов',
                  color: IOSTheme.systemBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  icon: Icons.badge,
                  value: '$employees',
                  label: 'Сотрудников',
                  color: IOSTheme.systemPurple,
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

  Widget _buildManagementActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionRow(
            context,
            icon1: Icons.people,
            label1: 'Сотрудники',
            color1: IOSTheme.systemBlue,
            icon2: Icons.settings,
            label2: 'Настройки',
            color2: IOSTheme.systemOrange,
          ),
          const SizedBox(height: 10),
          _buildActionRow(
            context,
            icon1: Icons.integration_instructions,
            label1: 'Интеграции',
            color1: IOSTheme.systemPurple,
            icon2: Icons.analytics,
            label2: 'Аналитика',
            color2: IOSTheme.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon1,
    required String label1,
    required Color color1,
    required IconData icon2,
    required String label2,
    required Color color2,
  }) {
    return Row(
      children: [
        Expanded(
          child: IOSCard(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color1.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon1, color: color1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label1, style: IOSTheme.bodyMedium)),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: IOSTheme.labelTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: IOSCard(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color2.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon2, color: color2, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label2, style: IOSTheme.bodyMedium)),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: IOSTheme.labelTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeItem(dynamic user) {
    final role = user['role'] ?? 'staff';
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
                  Text(
                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim().isEmpty
                        ? (user['email'] ?? '—')
                        : '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                    style: IOSTheme.headline,
                  ),
                  Text(_roleLabel(role), style: IOSTheme.caption),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _roleLabel(role),
                style: TextStyle(color: _roleColor(role), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'driver':
        return IOSTheme.systemBlue;
      case 'sales':
        return IOSTheme.systemGreen;
      case 'accountant':
        return IOSTheme.systemOrange;
      case 'director':
        return IOSTheme.systemPurple;
      case 'admin':
        return IOSTheme.systemRed;
      default:
        return IOSTheme.labelSecondary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'driver':
        return 'Водитель';
      case 'sales':
        return 'Продажи';
      case 'accountant':
        return 'Бухгалтер';
      case 'director':
        return 'Директор';
      case 'manager':
        return 'Менеджер';
      case 'admin':
        return 'Админ';
      case 'owner':
        return 'Владелец';
      default:
        return role;
    }
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
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
