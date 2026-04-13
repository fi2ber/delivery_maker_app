import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/api_service.dart';
import '../../../core/di/service_locator.dart';

/// Accountant reports screen — financial reports: P&L, cash flow, balance
class AccountantReportsScreen extends StatefulWidget {
  const AccountantReportsScreen({super.key});

  @override
  State<AccountantReportsScreen> createState() =>
      _AccountantReportsScreenState();
}

class _AccountantReportsScreenState extends State<AccountantReportsScreen>
    with SingleTickerProviderStateMixin {
  final _api = getIt<ApiService>();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/finance/reports', queryParameters: {
        'period': _selectedPeriod,
      });
      if (mounted) {
        setState(() {
          _reportData = response.data as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportData = _getMockReportData();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockReportData() {
    return {
      'profitAndLoss': {
        'totalRevenue': 182500000,
        'totalExpenses': 128750000,
        'netProfit': 53750000,
        'margin': 29.5,
        'items': [
          {'category': 'Продажи молочной продукции', 'amount': 85000000, 'type': 'income'},
          {'category': 'Продажи хлебобулочных', 'amount': 52000000, 'type': 'income'},
          {'category': 'Продажи прочее', 'amount': 45500000, 'type': 'income'},
          {'category': 'Зарплата водителей', 'amount': -42000000, 'type': 'expense'},
          {'category': 'Зарплата продавцов', 'amount': -28000000, 'type': 'expense'},
          {'category': 'Зарплата склад', 'amount': -18000000, 'type': 'expense'},
          {'category': 'Топливо', 'amount': -15000000, 'type': 'expense'},
          {'category': 'Аренда склада', 'amount': -12000000, 'type': 'expense'},
          {'category': 'Прочие расходы', 'amount': -13750000, 'type': 'expense'},
        ],
      },
      'cashFlow': {
        'openingBalance': 45000000,
        'closingBalance': 56250000,
        'totalInflows': 175000000,
        'totalOutflows': 163750000,
        'items': [
          {'category': 'Оплата от клиентов', 'amount': 168000000, 'type': 'inflow'},
          {'category': 'Возвраты полученные', 'amount': 7000000, 'type': 'inflow'},
          {'category': 'Оплата поставщикам', 'amount': -95000000, 'type': 'outflow'},
          {'category': 'Зарплата', 'amount': -48000000, 'type': 'outflow'},
          {'category': 'Аренда и коммунальные', 'amount': -15000000, 'type': 'outflow'},
          {'category': 'Налоги', 'amount': -5750000, 'type': 'outflow'},
        ],
      },
      'balance': {
        'totalAssets': 285000000,
        'totalLiabilities': 82000000,
        'equity': 203000000,
        'assets': [
          {'name': 'Денежные средства', 'amount': 56250000},
          {'name': 'Дебиторская задолженность', 'amount': 38500000},
          {'name': 'Товарные запасы', 'amount': 72000000},
          {'name': 'Основные средства', 'amount': 118250000},
        ],
        'liabilities': [
          {'name': 'Кредиторская задолженность', 'amount': 42000000},
          {'name': 'Налоги к оплате', 'amount': 15000000},
          {'name': 'Прочие обязательства', 'amount': 25000000},
        ],
      },
    };
  }

  String _formatCurrency(num value) {
    final absVal = value.abs();
    if (absVal >= 1000000) {
      return '${value < 0 ? "-" : ""}${(absVal / 1000000).toStringAsFixed(1)}M';
    } else if (absVal >= 1000) {
      return '${value < 0 ? "-" : ""}${(absVal / 1000).toStringAsFixed(0)}K';
    }
    return '${value.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPeriodSelector(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfitAndLoss(),
                        _buildCashFlow(),
                        _buildBalance(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text('Отчёты', style: IOSTheme.title2),
          const Spacer(),
          GestureDetector(
            onTap: () {
              IOSTheme.lightImpact();
              // Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Экспорт будет доступен в следующей версии')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: IOSTheme.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 16, color: IOSTheme.systemBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Экспорт',
                    style: IOSTheme.caption1.copyWith(
                      color: IOSTheme.systemBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'week', 'label': 'Неделя'},
      {'key': 'month', 'label': 'Месяц'},
      {'key': 'quarter', 'label': 'Квартал'},
      {'key': 'year', 'label': 'Год'},
    ];

    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: periods.map((p) {
          final isActive = _selectedPeriod == p['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                IOSTheme.lightImpact();
                setState(() => _selectedPeriod = p['key']!);
                _loadReportData();
              },
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isActive ? IOSTheme.systemBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: IOSTheme.systemBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: IOSTheme.labelPrimary,
        labelStyle: IOSTheme.caption1.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: IOSTheme.caption1,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'P&L', height: 34),
          Tab(text: 'Cash Flow', height: 34),
          Tab(text: 'Баланс', height: 34),
        ],
      ),
    );
  }

  Widget _buildProfitAndLoss() {
    final pnl =
        _reportData['profitAndLoss'] as Map<String, dynamic>? ?? {};
    final items = (pnl['items'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          // Summary cards
          Row(
            children: [
              _buildSummaryCard('Выручка', _formatCurrency(pnl['totalRevenue'] ?? 0), IOSTheme.systemGreen),
              const SizedBox(width: 8),
              _buildSummaryCard('Расходы', _formatCurrency(pnl['totalExpenses'] ?? 0), IOSTheme.systemRed),
              const SizedBox(width: 8),
              _buildSummaryCard('Прибыль', _formatCurrency(pnl['netProfit'] ?? 0), IOSTheme.systemBlue),
            ],
          ),
          const SizedBox(height: 12),
          // Margin indicator
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('Маржинальность', style: IOSTheme.subheadline),
                const Spacer(),
                Text(
                  '${(pnl['margin'] as num?)?.toStringAsFixed(1) ?? 0}%',
                  style: IOSTheme.title3.copyWith(color: IOSTheme.systemGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Детализация', style: IOSTheme.headline),
          const SizedBox(height: 8),
          ...items.map((item) {
            final i = item as Map<String, dynamic>;
            final amount = (i['amount'] as num?) ?? 0;
            final isIncome = amount >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isIncome ? IOSTheme.systemGreen : IOSTheme.systemRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i['category'] ?? '', style: IOSTheme.subheadline),
                  ),
                  Text(
                    '${_formatCurrency(amount)} сум',
                    style: IOSTheme.subheadline.copyWith(
                      color: isIncome ? IOSTheme.systemGreen : IOSTheme.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashFlow() {
    final cf = _reportData['cashFlow'] as Map<String, dynamic>? ?? {};
    final items = (cf['items'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          Row(
            children: [
              _buildSummaryCard('Начало', _formatCurrency(cf['openingBalance'] ?? 0), IOSTheme.labelSecondary),
              const SizedBox(width: 8),
              _buildSummaryCard('Конец', _formatCurrency(cf['closingBalance'] ?? 0), IOSTheme.systemBlue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryCard('Приход', _formatCurrency(cf['totalInflows'] ?? 0), IOSTheme.systemGreen),
              const SizedBox(width: 8),
              _buildSummaryCard('Расход', _formatCurrency(cf['totalOutflows'] ?? 0), IOSTheme.systemRed),
            ],
          ),
          const SizedBox(height: 16),
          Text('Движение средств', style: IOSTheme.headline),
          const SizedBox(height: 8),
          ...items.map((item) {
            final i = item as Map<String, dynamic>;
            final amount = (i['amount'] as num?) ?? 0;
            final isInflow = amount >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (isInflow ? IOSTheme.systemGreen : IOSTheme.systemRed)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInflow ? Icons.add : Icons.remove,
                      size: 16,
                      color: isInflow ? IOSTheme.systemGreen : IOSTheme.systemRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i['category'] ?? '', style: IOSTheme.subheadline),
                  ),
                  Text(
                    '${_formatCurrency(amount)} сум',
                    style: IOSTheme.subheadline.copyWith(
                      color: isInflow ? IOSTheme.systemGreen : IOSTheme.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBalance() {
    final bal = _reportData['balance'] as Map<String, dynamic>? ?? {};
    final assets = (bal['assets'] as List?) ?? [];
    final liabilities = (bal['liabilities'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          Row(
            children: [
              _buildSummaryCard('Активы', _formatCurrency(bal['totalAssets'] ?? 0), IOSTheme.systemGreen),
              const SizedBox(width: 8),
              _buildSummaryCard('Обяз-ва', _formatCurrency(bal['totalLiabilities'] ?? 0), IOSTheme.systemRed),
              const SizedBox(width: 8),
              _buildSummaryCard('Капитал', _formatCurrency(bal['equity'] ?? 0), IOSTheme.systemBlue),
            ],
          ),
          const SizedBox(height: 16),
          Text('Активы', style: IOSTheme.headline),
          const SizedBox(height: 8),
          ...assets.map((a) {
            final item = a as Map<String, dynamic>;
            return _buildBalanceItem(item['name'] ?? '', item['amount'] ?? 0, IOSTheme.systemGreen);
          }),
          const SizedBox(height: 16),
          Text('Обязательства', style: IOSTheme.headline),
          const SizedBox(height: 8),
          ...liabilities.map((l) {
            final item = l as Map<String, dynamic>;
            return _buildBalanceItem(item['name'] ?? '', item['amount'] ?? 0, IOSTheme.systemRed);
          }),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String name, num amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: IOSTheme.subheadline)),
          Text(
            '${_formatCurrency(amount)} сум',
            style: IOSTheme.subheadline.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: IOSTheme.headline.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: IOSTheme.caption2.copyWith(color: IOSTheme.labelSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
