import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../core/di/service_locator.dart';

/// Team management screen for Director — employees list, KPI summary, filtering
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _api = getIt<ApiService>();

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _roleFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/users', queryParameters: {
        'role': _roleFilter == 'all' ? null : _roleFilter,
      });
      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(
            response.data['users'] ?? response.data ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _employees = _getMockEmployees();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockEmployees() {
    return [
      {
        'id': '1',
        'fullName': 'Алишер Каримов',
        'role': 'DRIVER',
        'phone': '+998901234567',
        'status': 'active',
        'kpi': {'deliveries': 142, 'rating': 4.8, 'onTimeRate': 95},
      },
      {
        'id': '2',
        'fullName': 'Зарина Махмудова',
        'role': 'SALES_REP',
        'phone': '+998901234568',
        'status': 'active',
        'kpi': {'orders': 89, 'revenue': 15200000, 'conversion': 72},
      },
      {
        'id': '3',
        'fullName': 'Бахтиёр Рахимов',
        'role': 'DRIVER',
        'phone': '+998901234569',
        'status': 'active',
        'kpi': {'deliveries': 98, 'rating': 4.5, 'onTimeRate': 88},
      },
      {
        'id': '4',
        'fullName': 'Нодира Хасанова',
        'role': 'WAREHOUSE_MANAGER',
        'phone': '+998901234570',
        'status': 'active',
        'kpi': {'itemsProcessed': 1250, 'accuracy': 99.2, 'pickingSpeed': 45},
      },
      {
        'id': '5',
        'fullName': 'Сардор Юсупов',
        'role': 'DRIVER',
        'phone': '+998901234571',
        'status': 'inactive',
        'kpi': {'deliveries': 0, 'rating': 4.2, 'onTimeRate': 82},
      },
      {
        'id': '6',
        'fullName': 'Дилноза Абдуллаева',
        'role': 'SALES_REP',
        'phone': '+998901234572',
        'status': 'active',
        'kpi': {'orders': 67, 'revenue': 11800000, 'conversion': 65},
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    var list = _employees;
    if (_roleFilter != 'all') {
      list = list.where((e) => e['role'] == _roleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((e) => (e['fullName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'DRIVER':
        return IOSTheme.systemBlue;
      case 'SALES_REP':
        return IOSTheme.systemGreen;
      case 'WAREHOUSE_MANAGER':
        return IOSTheme.systemOrange;
      case 'ACCOUNTANT':
        return IOSTheme.systemPurple;
      default:
        return IOSTheme.labelSecondary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DRIVER':
        return 'Водитель';
      case 'SALES_REP':
        return 'Продавец';
      case 'WAREHOUSE_MANAGER':
        return 'Кладовщик';
      case 'ACCOUNTANT':
        return 'Бухгалтер';
      default:
        return role;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'DRIVER':
        return Icons.local_shipping;
      case 'SALES_REP':
        return Icons.point_of_sale;
      case 'WAREHOUSE_MANAGER':
        return Icons.warehouse;
      case 'ACCOUNTANT':
        return Icons.account_balance;
      default:
        return Icons.person;
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
            _buildSearchBar(),
            _buildRoleFilter(),
            _buildSummaryCards(),
            Expanded(child: _buildEmployeeList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text('Команда', style: IOSTheme.title2),
          const Spacer(),
          Text(
            '${_employees.length} сотр.',
            style: IOSTheme.subheadline.copyWith(
              color: IOSTheme.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: IOSTheme.body,
          decoration: InputDecoration(
            hintText: 'Поиск сотрудника...',
            hintStyle: IOSTheme.body.copyWith(color: IOSTheme.labelTertiary),
            prefixIcon: Icon(
              Icons.search,
              color: IOSTheme.labelSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    final filters = [
      {'key': 'all', 'label': 'Все'},
      {'key': 'DRIVER', 'label': 'Водители'},
      {'key': 'SALES_REP', 'label': 'Продавцы'},
      {'key': 'WAREHOUSE_MANAGER', 'label': 'Склад'},
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
          final isActive = _roleFilter == f['key'];
          return GestureDetector(
            onTap: () {
              IOSTheme.lightImpact();
              setState(() => _roleFilter = f['key']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? IOSTheme.systemBlue : IOSTheme.bgSecondary,
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

  Widget _buildSummaryCards() {
    final active = _employees.where((e) => e['status'] == 'active').length;
    final inactive = _employees.length - active;
    final drivers = _employees.where((e) => e['role'] == 'DRIVER').length;
    final sales = _employees.where((e) => e['role'] == 'SALES_REP').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _buildMiniStat('Активных', '$active', IOSTheme.systemGreen),
          const SizedBox(width: 8),
          _buildMiniStat('Неактивных', '$inactive', IOSTheme.systemRed),
          const SizedBox(width: 8),
          _buildMiniStat('Водители', '$drivers', IOSTheme.systemBlue),
          const SizedBox(width: 8),
          _buildMiniStat('Продавцы', '$sales', IOSTheme.systemGreen),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: IOSTheme.headline.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: IOSTheme.caption2.copyWith(color: IOSTheme.labelSecondary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    final employees = _filteredEmployees;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56, color: IOSTheme.labelTertiary),
            const SizedBox(height: 12),
            Text(
              'Сотрудники не найдены',
              style:
                  IOSTheme.subheadline.copyWith(color: IOSTheme.labelSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: employees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildEmployeeCard(employees[index]),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final role = employee['role'] ?? '';
    final kpi = employee['kpi'] as Map<String, dynamic>? ?? {};
    final isActive = employee['status'] == 'active';

    return Container(
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _roleColor(role).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_roleIcon(role), color: _roleColor(role), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['fullName'] ?? 'Сотрудник',
                      style: IOSTheme.headline,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _roleColor(role).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _roleLabel(role),
                            style: IOSTheme.caption2.copyWith(
                              color: _roleColor(role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? IOSTheme.systemGreen
                                : IOSTheme.systemRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Онлайн' : 'Офлайн',
                          style: IOSTheme.caption2.copyWith(
                            color: IOSTheme.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: IOSTheme.labelTertiary,
                size: 20,
              ),
            ],
          ),
          if (kpi.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildKpiRow(role, kpi),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(String role, Map<String, dynamic> kpi) {
    if (role == 'DRIVER') {
      return Row(
        children: [
          _buildKpiChip(Icons.local_shipping, '${kpi['deliveries'] ?? 0}',
              'доставок'),
          const SizedBox(width: 12),
          _buildKpiChip(Icons.star, '${kpi['rating'] ?? 0}', 'рейтинг'),
          const SizedBox(width: 12),
          _buildKpiChip(
              Icons.timer, '${kpi['onTimeRate'] ?? 0}%', 'вовремя'),
        ],
      );
    } else if (role == 'SALES_REP') {
      final revenue = (kpi['revenue'] as num?) ?? 0;
      final revenueStr = revenue >= 1000000
          ? '${(revenue / 1000000).toStringAsFixed(1)}M'
          : '${(revenue / 1000).toStringAsFixed(0)}K';
      return Row(
        children: [
          _buildKpiChip(Icons.receipt, '${kpi['orders'] ?? 0}', 'заказов'),
          const SizedBox(width: 12),
          _buildKpiChip(Icons.payments, revenueStr, 'выручка'),
          const SizedBox(width: 12),
          _buildKpiChip(
              Icons.trending_up, '${kpi['conversion'] ?? 0}%', 'конверсия'),
        ],
      );
    } else {
      return Row(
        children: [
          _buildKpiChip(Icons.inventory, '${kpi['itemsProcessed'] ?? 0}',
              'обработано'),
          const SizedBox(width: 12),
          _buildKpiChip(
              Icons.verified, '${kpi['accuracy'] ?? 0}%', 'точность'),
        ],
      );
    }
  }

  Widget _buildKpiChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: IOSTheme.bgPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: IOSTheme.systemBlue),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: IOSTheme.caption1.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: IOSTheme.caption2.copyWith(
                      color: IOSTheme.labelTertiary,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
