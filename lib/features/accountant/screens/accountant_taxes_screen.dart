import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../core/di/service_locator.dart';

/// Accountant taxes screen — tax calculations, declarations, payments history
class AccountantTaxesScreen extends StatefulWidget {
  const AccountantTaxesScreen({super.key});

  @override
  State<AccountantTaxesScreen> createState() => _AccountantTaxesScreenState();
}

class _AccountantTaxesScreenState extends State<AccountantTaxesScreen> {
  final _api = getIt<ApiService>();

  bool _isLoading = true;
  Map<String, dynamic> _taxData = {};

  @override
  void initState() {
    super.initState();
    _loadTaxData();
  }

  Future<void> _loadTaxData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/finance/taxes');
      if (mounted) {
        setState(() {
          _taxData = response.data as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _taxData = _getMockTaxData();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockTaxData() {
    return {
      'currentPeriod': '2026 Q1',
      'vatRate': 12,
      'incomeTaxRate': 15,
      'summary': {
        'vatPayable': 5475000,
        'incomeTax': 8062500,
        'socialTax': 3600000,
        'totalDue': 17137500,
        'nextPaymentDate': '2026-04-15',
      },
      'vatBreakdown': {
        'vatCollected': 21900000,
        'vatPaid': 16425000,
        'vatPayable': 5475000,
      },
      'history': [
        {
          'period': '2025 Q4',
          'type': 'НДС',
          'amount': 4850000,
          'status': 'paid',
          'paidAt': '2026-01-15',
        },
        {
          'period': '2025 Q4',
          'type': 'Налог на прибыль',
          'amount': 7200000,
          'status': 'paid',
          'paidAt': '2026-01-15',
        },
        {
          'period': '2025 Q4',
          'type': 'Соц. налог',
          'amount': 3200000,
          'status': 'paid',
          'paidAt': '2026-01-15',
        },
        {
          'period': '2025 Q3',
          'type': 'НДС',
          'amount': 4200000,
          'status': 'paid',
          'paidAt': '2025-10-15',
        },
        {
          'period': '2025 Q3',
          'type': 'Налог на прибыль',
          'amount': 6800000,
          'status': 'paid',
          'paidAt': '2025-10-15',
        },
      ],
      'declarations': [
        {
          'name': 'НДС декларация Q1 2026',
          'dueDate': '2026-04-20',
          'status': 'pending',
        },
        {
          'name': 'Декларация по прибыли Q1 2026',
          'dueDate': '2026-04-25',
          'status': 'pending',
        },
        {
          'name': 'НДС декларация Q4 2025',
          'dueDate': '2026-01-20',
          'status': 'submitted',
        },
      ],
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
                onRefresh: _loadTaxData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildTotalDueCard(),
                    const SizedBox(height: 16),
                    _buildVatBreakdown(),
                    const SizedBox(height: 20),
                    _buildTaxSummary(),
                    const SizedBox(height: 20),
                    _buildDeclarations(),
                    const SizedBox(height: 20),
                    _buildPaymentHistory(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Налоги', style: IOSTheme.title2),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: IOSTheme.systemIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _taxData['currentPeriod'] ?? '',
            style: IOSTheme.caption1.copyWith(
              color: IOSTheme.systemIndigo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalDueCard() {
    final summary = _taxData['summary'] as Map<String, dynamic>? ?? {};
    final totalDue = (summary['totalDue'] as num?) ?? 0;
    final nextDate = summary['nextPaymentDate'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IOSTheme.systemIndigo,
            IOSTheme.systemBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: IOSTheme.systemIndigo.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'К оплате за период',
            style: IOSTheme.subheadline.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(totalDue),
            style: IOSTheme.title1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Крайний срок: $nextDate',
                style: IOSTheme.caption1.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVatBreakdown() {
    final vat = _taxData['vatBreakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('НДС ${_taxData['vatRate'] ?? 12}%', style: IOSTheme.headline),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: IOSTheme.systemOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'К оплате: ${_formatCurrency(vat['vatPayable'] ?? 0)}',
                  style: IOSTheme.caption1.copyWith(
                    color: IOSTheme.systemOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildVatRow('НДС начисленный', vat['vatCollected'] ?? 0,
              IOSTheme.systemGreen),
          const SizedBox(height: 6),
          _buildVatRow(
              'НДС уплаченный', vat['vatPaid'] ?? 0, IOSTheme.systemRed),
          const Divider(height: 20),
          _buildVatRow(
              'Итого к оплате', vat['vatPayable'] ?? 0, IOSTheme.systemBlue),
        ],
      ),
    );
  }

  Widget _buildVatRow(String label, num amount, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: IOSTheme.subheadline),
        ),
        Text(
          _formatCurrency(amount),
          style: IOSTheme.subheadline.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTaxSummary() {
    final summary = _taxData['summary'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Налоги за период', style: IOSTheme.headline),
        const SizedBox(height: 10),
        _buildTaxCard(
          icon: Icons.receipt,
          title: 'НДС',
          amount: summary['vatPayable'] ?? 0,
          color: IOSTheme.systemBlue,
        ),
        const SizedBox(height: 8),
        _buildTaxCard(
          icon: Icons.account_balance,
          title: 'Налог на прибыль',
          amount: summary['incomeTax'] ?? 0,
          color: IOSTheme.systemIndigo,
        ),
        const SizedBox(height: 8),
        _buildTaxCard(
          icon: Icons.people,
          title: 'Социальный налог',
          amount: summary['socialTax'] ?? 0,
          color: IOSTheme.systemOrange,
        ),
      ],
    );
  }

  Widget _buildTaxCard({
    required IconData icon,
    required String title,
    required num amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: IOSTheme.subheadline)),
          Text(
            _formatCurrency(amount),
            style: IOSTheme.headline.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarations() {
    final declarations = (_taxData['declarations'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Декларации', style: IOSTheme.headline),
        const SizedBox(height: 10),
        ...declarations.map((d) {
          final decl = d as Map<String, dynamic>;
          final status = decl['status'] ?? 'pending';
          final isPending = status == 'pending';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: isPending
                  ? Border.all(
                      color: IOSTheme.systemOrange.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isPending ? Icons.pending_actions : Icons.check_circle,
                  color: isPending
                      ? IOSTheme.systemOrange
                      : IOSTheme.systemGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(decl['name'] ?? '', style: IOSTheme.subheadline),
                      Text(
                        'Срок: ${decl['dueDate'] ?? ''}',
                        style: IOSTheme.caption1
                            .copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPending
                            ? IOSTheme.systemOrange
                            : IOSTheme.systemGreen)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? 'Ожидает' : 'Подана',
                    style: IOSTheme.caption2.copyWith(
                      color: isPending
                          ? IOSTheme.systemOrange
                          : IOSTheme.systemGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    final history = (_taxData['history'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('История платежей', style: IOSTheme.headline),
        const SizedBox(height: 10),
        ...history.map((h) {
          final item = h as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: IOSTheme.systemGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['type']} — ${item['period']}',
                        style: IOSTheme.subheadline,
                      ),
                      Text(
                        'Оплачено: ${item['paidAt']}',
                        style: IOSTheme.caption2
                            .copyWith(color: IOSTheme.labelTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(item['amount'] ?? 0),
                  style: IOSTheme.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
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
