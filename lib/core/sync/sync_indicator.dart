import 'package:flutter/material.dart';
import 'sync_manager.dart';

/// Sync status indicator widget
/// Shows sync status in app bar or as floating widget
class SyncIndicator extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncIndicator({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncManager().statusStream,
      initialData: SyncManager().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        
        switch (status) {
          case SyncStatus.syncing:
            return _buildSyncingIndicator();
          case SyncStatus.hasErrors:
            return _buildErrorIndicator();
          case SyncStatus.error:
            return _buildErrorIndicator(isCritical: true);
          case SyncStatus.idle:
          default:
            return _buildIdleIndicator();
        }
      },
    );
  }

  Widget _buildSyncingIndicator() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 8),
              Text(
                'Синхронизация...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdleIndicator() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              size: 16,
              color: Colors.green[700],
            ),
            if (showDetails) ...[
              const SizedBox(width: 8),
              Text(
                'Синхронизировано',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIndicator({bool isCritical = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isCritical ? Colors.red : Colors.orange).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCritical ? Icons.cloud_off : Icons.cloud_sync,
              size: 16,
              color: isCritical ? Colors.red[700] : Colors.orange[700],
            ),
            if (showDetails) ...[
              const SizedBox(width: 8),
              Text(
                isCritical ? 'Ошибка синхронизации' : 'Есть несинхронизированные',
                style: TextStyle(
                  fontSize: 12,
                  color: isCritical ? Colors.red[700] : Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating sync button
class FloatingSyncButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FloatingSyncButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncManager().statusStream,
      initialData: SyncManager().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        
        if (status == SyncStatus.syncing) {
          return FloatingActionButton(
            onPressed: null,
            backgroundColor: Colors.grey,
            mini: true,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          );
        }

        return FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: status == SyncStatus.idle ? Colors.green : Colors.orange,
          mini: true,
          child: Icon(
            status == SyncStatus.idle ? Icons.cloud_done : Icons.sync,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Sync status bottom sheet
class SyncStatusSheet extends StatefulWidget {
  const SyncStatusSheet({super.key});

  @override
  State<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends State<SyncStatusSheet> {
  SyncStatistics? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SyncManager().getStatistics();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _triggerSync() async {
    final result = await SyncManager().syncAll();
    await _loadStats();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Синхронизация завершена: ${result.successCount} из ${result.processed}'
                : 'Синхронизация завершена с ошибками',
          ),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Статус синхронизации',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                _buildStatRow(
                  'Ожидают синхронизации',
                  '${_stats!.pendingSyncItems}',
                  _stats!.pendingSyncItems > 0 ? Colors.orange : Colors.green,
                ),
                const Divider(height: 24),
                _buildStatRow('Заказов в очереди', '${_stats!.offlineOrders}'),
                _buildStatRow('Доставок в очереди', '${_stats!.offlineDeliveries}'),
                const Divider(height: 24),
                _buildStatRow('Кэшировано товаров', '${_stats!.cachedProducts}'),
                _buildStatRow('Кэшировано клиентов', '${_stats!.cachedCustomers}'),
              ],
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _triggerSync,
              icon: const Icon(Icons.sync),
              label: const Text('Синхронизировать сейчас'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
