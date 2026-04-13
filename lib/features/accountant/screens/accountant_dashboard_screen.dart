import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

/// Accountant dashboard — invoices, payments, taxes
class AccountantDashboardScreen extends StatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  State<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends State<AccountantDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentInvoices = [];
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
        final res = await api.get('/finance/stats');
        if (res.data is Map<String, dynamic>) {
          setState(() => _stats = res.data as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Failed to load finance stats: $e');
      }
      try {
        final res = await api.get('/finance/invoices', queryParameters: {'limit': 5});
        if (res.data is List) {
          setState(() => _recentInvoices = res.data as List);
        }
      } catch (e) {
        debugPrint('Failed to load invoices: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = getIt<AuthService>().fullName ?? 'Бухгалтер';
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
                      Text('Финансы', style: IOSTheme.caption),
                      const SizedBox(height: 4),
                      Text(userName, style: IOSTheme.title1),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildKpiRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Быстрые действия', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Последние счета', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                )
              else if (_recentInvoices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: IOSTheme.labelTertiary),
                        const SizedBox(height: 12),
                        Text('Нет счетов',
                            style: IOSTheme.bodyMedium
                                .copyWith(color: IOSTheme.labelTertiary)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildInvoiceItem(_recentInvoices[i]),
                    childCount: _recentInvoices.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    final revenue = _stats?['totalRevenue'] ?? 0;
    final vat = _stats?['vatCollected'] ?? 0;
    final unpaid = _stats?['unpaidInvoices'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              icon: Icons.payments_outlined,
              value: _fmt(revenue),
              label: 'Выручка',
              color: IOSTheme.systemGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              icon: Icons.percent,
              value: _fmt(vat),
              label: 'НДС',
              color: IOSTheme.systemOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              icon: Icons.warning_amber_outlined,
              value: '$unpaid',
              label: 'Просроч.',
              color: IOSTheme.systemRed,
            ),
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
      child: Column(
        children: [
          _buildActionCard(
            context,
            icon: Icons.receipt,
            title: 'Счета',
            subtitle: 'Управление счетами',
            color: IOSTheme.systemBlue,
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.account_balance,
            title: 'Налоги',
            subtitle: 'НДС и отчётность',
            color: IOSTheme.systemOrange,
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.bar_chart,
            title: 'Отчёты',
            subtitle: 'P&L, баланс',
            color: IOSTheme.systemPurple,
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.attach_money,
            title: 'Зарплаты',
            subtitle: 'Выплаты сотрудникам',
            color: IOSTheme.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return IOSCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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
          const Icon(Icons.arrow_forward_ios, size: 14,
              color: IOSTheme.labelTertiary),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(dynamic invoice) {
    final status = invoice['status'] ?? 'draft';
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IOSCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice['customerName'] ?? '—', style: IOSTheme.headline),
                  const SizedBox(height: 2),
                  Text(
                    '${invoice['totalAmount'] ?? 0} сум',
                    style: IOSTheme.bodyMedium
                        .copyWith(color: IOSTheme.labelSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':
        return IOSTheme.systemGreen;
      case 'overdue':
        return IOSTheme.systemRed;
      case 'sent':
        return IOSTheme.systemBlue;
      default:
        return IOSTheme.systemOrange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'paid':
        return 'Оплачен';
      case 'overdue':
        return 'Просрочен';
      case 'sent':
        return 'Отправлен';
      default:
        return 'Черновик';
    }
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: IOSTheme.title2.copyWith(color: color)),
          Text(label,
              style: IOSTheme.caption.copyWith(color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
