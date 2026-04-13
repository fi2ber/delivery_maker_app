import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_api_service.dart';
import '../../driver/screens/kpi_screen.dart';

/// Universal Profile Screen for all roles
class ProfileScreen extends StatefulWidget {
  final String role;

  const ProfileScreen({
    super.key,
    this.role = '',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authService = getIt<AuthService>();
      final apiService = getIt<ApiService>();

      // Load user data from AuthService (cached from login)
      final cachedUser = authService.userData;

      // Try to get fresh data from API
      Map<String, dynamic>? apiUser;
      try {
        final response = await apiService.get('/users/me');
        if (response.data['success'] == true) {
          apiUser = response.data['data'] as Map<String, dynamic>?;
        }
      } catch (e) {
        debugPrint('Failed to fetch user from API: $e');
      }

      final user = apiUser ?? cachedUser;
      final name = user?['fullName'] ?? user?['name'] ??
          '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();

      setState(() {
        _userData = {
          'name': name.isNotEmpty ? name : 'Пользователь',
          'phone': user?['phone'] ?? authService.phone ?? '',
          'email': user?['email'] ?? '',
          'joinedAt': user?['createdAt'] ?? '',
          'avatar': _getInitials(name),
        };
      });

      // Load role-specific stats
      try {
        if (widget.role == 'driver') {
          final driverApi = getIt<DriverApiService>();
          final driverId = authService.userId ?? '';
          if (driverId.isNotEmpty) {
            final statsResponse = await driverApi.getTodayStats(driverId);
            if (statsResponse['success'] == true) {
              final data = statsResponse['data'];
              setState(() {
                _stats = {
                  'deliveries': data['delivered'] ?? 0,
                  'total': data['total'] ?? 0,
                  'completionRate': data['completionRate'] ?? 0,
                };
              });
            }
          }
        } else if (widget.role == 'sales') {
          // Try to load sales stats
          try {
            final response = await apiService.get('/sales-rep/my-stats');
            final data = response.data;
            setState(() {
              _stats = {
                'orders': data['totalOrders'] ?? 0,
                'customers': data['completedOrders'] ?? 0,
                'revenue': data['totalRevenue'] ?? 0,
              };
            });
          } catch (e) {
            debugPrint('Sales stats not available: $e');
          }
        }
      } catch (e) {
        debugPrint('Failed to load stats: $e');
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await getIt<AuthService>().logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_stats != null)
                    SliverToBoxAdapter(child: _buildStats()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildMenu()),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [IOSTheme.systemBlue, IOSTheme.systemIndigo],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  _userData?['avatar'] ?? '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userData?['name'] ?? 'Загрузка...',
              style: IOSTheme.title1,
            ),
            const SizedBox(height: 4),
            Text(
              _getRoleLabel(),
              style: IOSTheme.bodyMedium.copyWith(
                color: IOSTheme.labelSecondary,
              ),
            ),
            if (_userData?['phone'] != null &&
                _userData!['phone'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _userData!['phone'],
                style: IOSTheme.body.copyWith(
                  color: IOSTheme.labelSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final stats = _stats!;

    if (widget.role == 'driver') {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика за сегодня', style: IOSTheme.headline),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Доставлено',
                    value: '${stats['deliveries']}',
                    icon: Icons.check_circle,
                    color: IOSTheme.systemGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Всего',
                    value: '${stats['total']}',
                    icon: Icons.local_shipping,
                    color: IOSTheme.systemBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Успех',
                    value: '${stats['completionRate']}%',
                    icon: Icons.trending_up,
                    color: IOSTheme.systemOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Sales stats
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статистика', style: IOSTheme.headline),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Заказов',
                  value: '${stats['orders']}',
                  icon: Icons.shopping_bag,
                  color: IOSTheme.systemBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Клиентов',
                  value: '${stats['customers']}',
                  icon: Icons.people,
                  color: IOSTheme.systemOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Выручка',
                  value: _formatRevenue(stats['revenue'] ?? 0),
                  icon: Icons.payments,
                  color: IOSTheme.systemGreen,
                ),
              ),
            ],
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

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Настройки', style: IOSTheme.headline),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.person_outline,
            title: 'Личные данные',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () {},
          ),
          if (widget.role == 'driver')
            _MenuItem(
              icon: Icons.trending_up,
              title: 'Мой KPI',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverKpiScreen()),
              ),
            ),
          _MenuItem(
            icon: Icons.logout,
            title: 'Выйти',
            color: IOSTheme.systemRed,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  String _getRoleLabel() {
    switch (widget.role) {
      case 'driver':
        return 'Водитель';
      case 'sales':
        return 'Менеджер продаж';
      case 'warehouse':
        return 'Кладовщик';
      case 'accountant':
        return 'Бухгалтер';
      case 'director':
        return 'Директор';
      case 'owner':
        return 'Владелец';
      default:
        return 'Сотрудник';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: IOSTheme.title2.copyWith(color: color)),
          Text(label,
              style: IOSTheme.caption
                  .copyWith(color: IOSTheme.labelSecondary)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? IOSTheme.labelPrimary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: color))),
            Icon(Icons.chevron_right, color: IOSTheme.labelTertiary),
          ],
        ),
      ),
    );
  }
}
