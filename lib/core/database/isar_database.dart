import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../sync/sync_entity.dart';

/// Isar Database singleton for offline storage
class IsarDatabase {
  static Isar? _instance;
  static final _initCompleter = Completer<Isar>();

  /// Get database instance (singleton)
  static Future<Isar> getInstance() async {
    if (_instance != null) return _instance!;
    if (!_initCompleter.isCompleted) {
      _instance = await _initCompleter.future;
      return _instance!;
    }
    await initialize();
    return _instance!;
  }

  /// Initialize database
  static Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      
      final isar = await Isar.open(
        [
          SyncQueueEntitySchema,
          OfflineOrderSchema,
          OfflineDeliverySchema,
          CachedProductSchema,
          CachedCustomerSchema,
        ],
        directory: dir.path,
        name: 'delivery_app_db',
      );

      _instance = isar;
      _initCompleter.complete(isar);
    } catch (e, stack) {
      _initCompleter.completeError(e, stack);
      rethrow;
    }
  }

  /// Close database
  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}

/// Extension methods for sync operations
extension IsarSyncExtension on Isar {
  /// Get sync queue collection
  IsarCollection<SyncQueueEntity> get syncQueue => this.collection<SyncQueueEntity>();
  
  /// Get offline orders collection
  IsarCollection<OfflineOrder> get offlineOrders => this.collection<OfflineOrder>();
  
  /// Get offline deliveries collection
  IsarCollection<OfflineDelivery> get offlineDeliveries => this.collection<OfflineDelivery>();
  
  /// Get cached products collection
  IsarCollection<CachedProduct> get cachedProducts => this.collection<CachedProduct>();
  
  /// Get cached customers collection
  IsarCollection<CachedCustomer> get cachedCustomers => this.collection<CachedCustomer>();
}

/// Extension for write operations with sync queue
extension IsarWriteExtension on Isar {
  /// Add operation to sync queue
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String operation, // create, update, delete
    required Map<String, dynamic> payload,
    int priority = 0,
  }) async {
    final queueItem = SyncQueueEntity()
      ..entityType = entityType
      ..entityId = entityId
      ..operation = operation
      ..payload = payload
      ..priority = priority
      ..createdAt = DateTime.now()
      ..status = 'pending'
      ..retryCount = 0;

    await writeTxn(() async {
      await syncQueue.put(queueItem);
    });
  }

  /// Mark sync item as completed
  Future<void> markSyncCompleted(int id) async {
    await writeTxn(() async {
      final item = await syncQueue.get(id);
      if (item != null) {
        item.status = 'completed';
        item.syncedAt = DateTime.now();
        await syncQueue.put(item);
      }
    });
  }

  /// Mark sync item as failed
  Future<void> markSyncFailed(int id, String error) async {
    await writeTxn(() async {
      final item = await syncQueue.get(id);
      if (item != null) {
        item.status = 'failed';
        item.errorMessage = error;
        item.retryCount = (item.retryCount ?? 0) + 1;
        await syncQueue.put(item);
      }
    });
  }

  /// Get pending sync items ordered by priority and creation time
  Future<List<SyncQueueEntity>> getPendingSyncItems() async {
    return await syncQueue
        .filter()
        .statusEqualTo('pending')
        .or()
        .statusEqualTo('failed')
        .and()
        .retryCountLessThan(5)
        .sortByPriorityDesc()
        .thenByCreatedAt()
        .findAll();
  }

  /// Get pending items count
  Future<int> getPendingSyncCount() async {
    return await syncQueue
        .filter()
        .statusEqualTo('pending')
        .or()
        .statusEqualTo('failed')
        .count();
  }

  /// Clear old completed sync items
  Future<int> clearOldSyncItems({Duration olderThan = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(olderThan);
    
    return await writeTxn(() async {
      final oldItems = await syncQueue
          .filter()
          .statusEqualTo('completed')
          .and()
          .createdAtLessThan(cutoff)
          .findAll();
      
      await syncQueue.deleteAll(oldItems.map((e) => e.id).toList());
      return oldItems.length;
    });
  }
}
