import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_manager.dart';

/// Mixin for screens that need sync functionality
/// Automatically shows sync status and handles offline/online transitions
mixin SyncMixin<T extends StatefulWidget> on State<T> {
  SyncManager get syncManager => SyncManager();
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  /// Check initial connectivity
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(result);
  }

  /// Setup connectivity change listener
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOnline != _isOnline) {
      onConnectivityChanged(_isOnline);
      
      // Auto-sync when coming back online
      if (_isOnline && !wasOnline) {
        onConnectionRestored();
      }
    }
  }

  /// Called when connectivity changes
  @protected
  void onConnectivityChanged(bool isOnline) {}

  /// Called when connection is restored after being offline
  @protected
  void onConnectionRestored() {
    // Auto-sync pending items
    syncManager.syncAll().then((result) {
      if (result.success && result.processed > 0) {
        onSyncCompleted(result);
      }
    });
  }

  /// Called when sync completes successfully
  @protected
  void onSyncCompleted(SyncResult result) {}

  /// Show offline banner
  Widget buildOfflineBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isOnline ? 0 : 40,
      color: Colors.orange,
      child: _isOnline
          ? null
          : const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Нет подключения к интернету',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  /// Show sync indicator in app bar
  List<Widget> buildSyncActions() {
    return [
      StreamBuilder<SyncStatus>(
        stream: syncManager.statusStream,
        initialData: syncManager.currentStatus,
        builder: (context, snapshot) {
          final status = snapshot.data ?? SyncStatus.idle;
          
          IconData icon;
          Color color;
          String tooltip;
          
          switch (status) {
            case SyncStatus.syncing:
              icon = Icons.sync;
              color = Colors.blue;
              tooltip = 'Синхронизация...';
              break;
            case SyncStatus.hasErrors:
              icon = Icons.sync_problem;
              color = Colors.orange;
              tooltip = 'Есть ошибки синхронизации';
              break;
            case SyncStatus.error:
              icon = Icons.sync_disabled;
              color = Colors.red;
              tooltip = 'Ошибка синхронизации';
              break;
            case SyncStatus.idle:
            default:
              icon = Icons.cloud_done;
              color = Colors.green;
              tooltip = 'Синхронизировано';
          }

          return IconButton(
            icon: Icon(icon, color: color),
            tooltip: tooltip,
            onPressed: () => _showSyncStatus(context),
          );
        },
      ),
    ];
  }

  void _showSyncStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        child: SyncStatusBottomSheet(),
      ),
    );
  }
}

/// Sync status bottom sheet widget
class SyncStatusBottomSheet extends StatefulWidget {
  const SyncStatusBottomSheet({super.key});

  @override
  State<SyncStatusBottomSheet> createState() => _SyncStatusBottomSheetState();
}

class _SyncStatusBottomSheetState extends State<SyncStatusBottomSheet> {
  SyncStatistics? _stats;
  bool _isLoading = true;
  bool _isSyncing = false;

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
    setState(() => _isSyncing = true);
    
    final result = await SyncManager().syncAll();
    await _loadStats();
    
    setState(() => _isSyncing = false);
    
    if (mounted && result.processed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✓ Синхронизировано ${result.successCount} из ${result.processed}'
                : '⚠ Синхронизировано с ошибками',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Статус синхронизации',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildPendingItemsCard(),
            const SizedBox(height: 16),
            _buildCacheCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Синхронизация...' : 'Синхронизировать сейчас'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingItemsCard() {
    final hasPending = _stats!.pendingSyncItems > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPending ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPending ? Colors.orange[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.sync : Icons.cloud_done,
            color: hasPending ? Colors.orange : Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? '${_stats!.pendingSyncItems} элементов ожидает'
                      : 'Все данные синхронизированы',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (hasPending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Заказов: ${_stats!.offlineOrders}, Доставок: ${_stats!.offlineDeliveries}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Локальный кэш',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildCacheRow('Товары', _stats!.cachedProducts),
          _buildCacheRow('Клиенты', _stats!.cachedCustomers),
        ],
      ),
    );
  }

  Widget _buildCacheRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
