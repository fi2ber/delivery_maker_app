import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/warehouse_bloc.dart';
import 'receive_goods_screen.dart';
import 'picking_screen.dart';
import 'write_off_screen.dart';
import 'inventory_screen.dart';

/// Warehouse Dashboard with TSD (external barcode scanner) support.
/// External scanners send keystrokes ending with Enter — we intercept them
/// via KeyboardListener and dispatch ScanBarcode to the BLoC.
class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  State<WarehouseDashboardScreen> createState() => _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime _lastKeyTime = DateTime.now();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();
    // If more than 100ms between keystrokes, reset buffer
    // (TSD sends keys in rapid sequence, manual typing is slower)
    if (now.difference(_lastKeyTime).inMilliseconds > 100) {
      _barcodeBuffer = '';
    }
    _lastKeyTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_barcodeBuffer.length >= 4) {
        // Valid barcode scanned
        context.read<WarehouseBloc>().add(ScanBarcode(_barcodeBuffer));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сканирован: $_barcodeBuffer'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _barcodeBuffer = '';
    } else if (event.character != null && event.character!.isNotEmpty) {
      _barcodeBuffer += event.character!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: _buildDashboard(context),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад WMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WarehouseBloc>().add(LoadDashboard());
            },
          ),
        ],
      ),
      body: BlocBuilder<WarehouseBloc, WarehouseState>(
        builder: (context, state) {
          if (state is WarehouseLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            return _buildContent(context, state);
          }

          if (state is WarehouseError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WarehouseBloc>().add(LoadDashboard());
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Загрузка...'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardLoaded state) {
    final stats = state.stats;
    final alerts = state.alerts;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<WarehouseBloc>().add(LoadDashboard());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Grid
            _buildActionCard(
              context,
              title: 'Приёмка',
              subtitle: 'Сканирование поступлений',
              icon: Icons.add_circle,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiveGoodsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Сборка заказов',
              subtitle: 'Комплектация по волнам',
              icon: Icons.inventory_2,
              iconColor: Colors.white,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PickingScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Списание',
              subtitle: 'С фото-фиксацией',
              icon: Icons.delete_forever,
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WriteOffScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Инвентаризация',
              subtitle: 'Учёт остатков',
              icon: Icons.fact_check,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            const Text(
              'Статистика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Позиций',
                  (stats['totalItems'] ?? 0).toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Мало',
                  (stats['lowStock'] ?? 0).toString(),
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Истекает',
                  (stats['expiringSoon'] ?? 0).toString(),
                  Colors.yellow.shade700,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Просрочено',
                  (stats['expired'] ?? 0).toString(),
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Alerts
            if (alerts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Уведомления',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${alerts.length}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts.take(5).map((alert) => _buildAlertCard(alert)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final type = alert['type'] as String;
    final icon = type == 'expired'
        ? Icons.error
        : type == 'expiring'
            ? Icons.warning
            : Icons.info;
    final color = type == 'expired'
        ? Colors.red
        : type == 'expiring'
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.05),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(alert['productName'] ?? 'Товар'),
        subtitle: Text(alert['message'] ?? ''),
        dense: true,
      ),
    );
  }
}
