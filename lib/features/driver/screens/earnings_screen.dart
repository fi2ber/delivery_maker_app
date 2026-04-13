import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_api_service.dart';

/// Driver earnings screen — weekly/monthly breakdown and bonuses
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _earnings;
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
      final driverApi = getIt<DriverApiService>();
      final authService = getIt<AuthService>();
      final driverId = authService.userId ?? '';

      final now = DateTime.now();
      final startDate = _period == 'week'
          ? now.subtract(const Duration(days: 7))
          : DateTime(now.year, now.month, 1);

      final data = await driverApi.getEarnings(
        driverId,
        startDate: startDate,
        endDate: now,
      );
      setState(() => _earnings = data);
    } catch (e) {
      debugPrint('Failed to load earnings: $e');
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
                      Text('Мой заработок', style: IOSTheme.title1),
                      _buildPeriodSwitch(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildTotalCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Детализация', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildBreakdownCards()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Прогресс к цели', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildGoalProgress()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('По дням', style: IOSTheme.headline),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildDailyChart()),
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
            onTap: () {
              setState(() => _period = 'week');
              _loadData();
            },
          ),
          _PeriodBtn(
            label: 'Месяц',
            isActive: _period == 'month',
            onTap: () {
              setState(() => _period = 'month');
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final total = _earnings?['totalEarnings'] ?? 0;
    final bonus = _earnings?['bonus'] ?? 0;
    final deliveries = _earnings?['completedDeliveries'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF007AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(IOSTheme.radius2Xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34C759).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Итого за период',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatAmount(total)} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _WhiteStat(
                        icon: Icons.local_shipping,
                        value: '$deliveries',
                        label: 'доставок'),
                    const SizedBox(width: 24),
                    _WhiteStat(
                        icon: Icons.star,
                        value: '${_formatAmount(bonus)} сум',
                        label: 'бонус'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildBreakdownCards() {
    final base = _earnings?['baseEarnings'] ?? 0;
    final bonus = _earnings?['bonus'] ?? 0;
    final fuel = _earnings?['fuelCompensation'] ?? 0;
    final deductions = _earnings?['deductions'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BreakdownCard(
                  icon: Icons.payments,
                  label: 'База',
                  value: _formatAmount(base),
                  color: IOSTheme.systemBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BreakdownCard(
                  icon: Icons.emoji_events,
                  label: 'Бонус',
                  value: _formatAmount(bonus),
                  color: IOSTheme.systemGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BreakdownCard(
                  icon: Icons.local_gas_station,
                  label: 'Топливо',
                  value: _formatAmount(fuel),
                  color: IOSTheme.systemOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BreakdownCard(
                  icon: Icons.remove_circle_outline,
                  label: 'Вычеты',
                  value: '-${_formatAmount(deductions)}',
                  color: IOSTheme.systemRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress() {
    final total = (_earnings?['totalEarnings'] ?? 0) as num;
    final goal = (_earnings?['monthlyGoal'] ?? 3000000) as num;
    final progress = goal > 0 ? (total / goal).clamp(0.0, 1.0).toDouble() : 0.0;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IOSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Цель месяца', style: IOSTheme.headline),
                Text('$pct%',
                    style: IOSTheme.headline
                        .copyWith(color: IOSTheme.systemGreen)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: IOSTheme.separator,
                valueColor: const AlwaysStoppedAnimation(IOSTheme.systemGreen),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_formatAmount(total)} сум', style: IOSTheme.bodyMedium),
                Text('из ${_formatAmount(goal)} сум',
                    style:
                        IOSTheme.caption.copyWith(color: IOSTheme.labelSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    final dailyData = _earnings?['dailyBreakdown'] as List? ?? _mockDailyData();

    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(dailyData.length, (i) {
            final item = dailyData[i] is Map ? dailyData[i] as Map : {};
            final amount = (item['amount'] ?? 0) as num;
            final maxVal = dailyData
                .map((e) => (e is Map ? (e['amount'] ?? 0) : 0) as num)
                .reduce((a, b) => a > b ? a : b);
            final heightFraction =
                maxVal > 0 ? (amount / maxVal).toDouble() : 0.1;
            final label = item['day']?.toString() ??
                (i + 1).toString();

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (heightFraction * 110).clamp(4, 110),
                      decoration: BoxDecoration(
                        color: IOSTheme.systemBlue.withOpacity(
                            heightFraction > 0.8 ? 1 : 0.5 + heightFraction * 0.5),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 9, color: IOSTheme.labelTertiary),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _mockDailyData() {
    return List.generate(
        7,
        (i) => {
              'day': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i],
              'amount': (50000 + (i * 30000) % 200000),
            });
  }

  String _formatAmount(dynamic v) {
    final n = v is num ? v : 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toInt()}k';
    return '$n';
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

class _WhiteStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WhiteStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BreakdownCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text('$value сум',
              style: IOSTheme.headline.copyWith(color: color, fontSize: 15)),
          Text(label, style: IOSTheme.caption),
        ],
      ),
    );
  }
}
