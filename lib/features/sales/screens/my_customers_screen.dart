import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/sales_api_service.dart';
import 'customer_registration_screen.dart';

class MyCustomersScreen extends StatefulWidget {
  const MyCustomersScreen({super.key});

  @override
  State<MyCustomersScreen> createState() => _MyCustomersScreenState();
}

class _MyCustomersScreenState extends State<MyCustomersScreen> {
  final _salesApi = getIt<SalesApiService>();
  List<Customer> _customers = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _error = null;
      });
    }
    setState(() => _isLoading = true);

    try {
      final result = await _salesApi.getMyCustomers(page: _page, limit: 20);
      final List<dynamic> data = result['data'] ?? [];
      final customers = data
          .map((c) => Customer.fromJson(c is Map<String, dynamic> ? c : {}))
          .toList();

      setState(() {
        _customers = customers;
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
      appBar: AppBar(
        title: const Text('Мои клиенты'),
        backgroundColor: IOSTheme.bgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerRegistrationScreen(salesRepId: ''),
                ),
              );
              _loadCustomers(refresh: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCustomers(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: IOSTheme.systemRed),
            const SizedBox(height: 12),
            Text('Ошибка загрузки', style: IOSTheme.headline),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadCustomers(refresh: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: IOSTheme.labelTertiary),
            const SizedBox(height: 12),
            Text('Нет клиентов',
                style: IOSTheme.bodyMedium
                    .copyWith(color: IOSTheme.labelTertiary)),
            const SizedBox(height: 8),
            Text('Зарегистрируйте первого клиента!',
                style: IOSTheme.caption),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customers.length + (_page < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _customers.length) {
          return _buildLoadMoreButton();
        }
        return _buildCustomerCard(_customers[index]);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: IOSTheme.systemBlue.withOpacity(0.1),
            child: Text(
              customer.firstName.isNotEmpty ? customer.firstName[0].toUpperCase() : '?',
              style: TextStyle(
                color: IOSTheme.systemBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName, style: IOSTheme.headline),
                const SizedBox(height: 2),
                Text(customer.phone, style: IOSTheme.caption),
                if (customer.address != null && customer.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      customer.address!,
                      style: IOSTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: IOSTheme.labelTertiary),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() => _page++);
            _loadCustomers();
          },
          child: const Text('Загрузить ещё'),
        ),
      ),
    );
  }
}
