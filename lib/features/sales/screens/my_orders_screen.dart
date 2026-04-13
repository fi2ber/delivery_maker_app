import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/sales_api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _salesApi = getIt<SalesApiService>();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _statusFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _error = null;
      });
    }
    setState(() => _isLoading = true);

    try {
      final result = await _salesApi.getMyOrdersPaginated(
        page: _page,
        limit: 20,
        status: _statusFilter,
      );
      final List<dynamic> data = result['data'] ?? [];

      setState(() {
        _orders = data;
        _totalPages = result['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Мои заказы', style: IOSTheme.title1),
            ),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadOrders(refresh: true),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Все', 'value': null},
      {'label': 'Ожидает', 'value': 'pending'},
      {'label': 'Обработка', 'value': 'processing'},
      {'label': 'Доставлен', 'value': 'delivered'},
      {'label': 'Отменён', 'value': 'cancelled'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = _statusFilter == filter['value'];

          return GestureDetector(
            onTap: () {
              setState(() => _statusFilter = filter['value'] as String?);
              _loadOrders(refresh: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? IOSTheme.systemBlue
                    : IOSTheme.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isActive ? Colors.white : IOSTheme.systemBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: IOSTheme.systemRed),
            const SizedBox(height: 12),
            Text('Ошибка загрузки', style: IOSTheme.headline),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadOrders(refresh: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: IOSTheme.labelTertiary),
            const SizedBox(height: 12),
            Text('Нет заказов',
                style: IOSTheme.bodyMedium
                    .copyWith(color: IOSTheme.labelTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length + (_page < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return _buildLoadMoreButton();
        }
        return _buildOrderCard(_orders[index]);
      },
    );
  }

  Widget _buildOrderCard(dynamic orderData) {
    final order = orderData is Map<String, dynamic> ? orderData : <String, dynamic>{};
    final status = (order['status'] ?? 'pending') as String;
    final totalAmount = (order['totalAmount'] ?? 0);
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'])
        : null;
    final customerName = order['customer']?['firstName'] ?? 'Клиент';
    final orderCode = order['orderCode'] ?? order['id']?.toString().substring(0, 8) ?? '';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$orderCode', style: IOSTheme.headline),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: IOSTheme.labelSecondary),
              const SizedBox(width: 4),
              Text(customerName, style: IOSTheme.body),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (createdAt != null)
                Text(
                  '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}',
                  style: IOSTheme.caption,
                ),
              Text(
                '${_formatAmount(totalAmount)} сум',
                style: IOSTheme.headline.copyWith(color: IOSTheme.systemBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    final num val = amount is num ? amount : 0;
    return val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return IOSTheme.systemGreen;
      case 'pending':
        return IOSTheme.systemOrange;
      case 'processing':
        return IOSTheme.systemBlue;
      case 'cancelled':
        return IOSTheme.systemRed;
      default:
        return IOSTheme.labelSecondary;
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

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() => _page++);
            _loadOrders();
          },
          child: const Text('Загрузить ещё'),
        ),
      ),
    );
  }
}
