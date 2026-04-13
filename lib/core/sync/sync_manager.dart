import 'dart:async';
import 'package:isar/isar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../database/isar_database.dart';
import '../../services/api_service.dart';
import 'sync_entity.dart';

/// Background sync task name
const String syncTaskName = 'background-sync-task';

/// Callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTaskName) {
      await IsarDatabase.initialize();
      final syncManager = SyncManager();
      await syncManager.syncAll();
    }
    return Future.value(true);
  });
}

/// Central sync manager for offline-first functionality
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ApiService _apiService = ApiService();
  final _connectivity = Connectivity();
  
  /// Stream controller for sync status
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  /// Is currently syncing
  bool get isSyncing => _currentStatus == SyncStatus.syncing;

  /// Initialize sync manager
  Future<void> initialize() async {
    await IsarDatabase.initialize();
    
    // Initialize WorkManager for background sync
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Schedule periodic background sync (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      'periodic-sync',
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none && !isSyncing) {
      // Auto-sync when connection restored
      syncAll();
    }
  }

  /// Sync all pending items
  Future<SyncResult> syncAll() async {
    if (isSyncing) {
      return SyncResult.alreadySyncing();
    }

    _updateStatus(SyncStatus.syncing);
    
    try {
      final db = await IsarDatabase.getInstance();
      final pendingItems = await db.getPendingSyncItems();

      if (pendingItems.isEmpty) {
        _updateStatus(SyncStatus.idle);
        return SyncResult.success(processed: 0);
      }

      int successCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      // Process items in order (respecting priority)
      for (final item in pendingItems) {
        try {
          await _syncItem(db, item);
          successCount++;
        } catch (e) {
          failedCount++;
          errors.add('${item.entityType}:${item.entityId} - $e');
          
          // Mark as failed
          await db.markSyncFailed(item.id, e.toString());
          
          // If max retries reached, move to dead letter queue
          if ((item.retryCount ?? 0) >= 5) {
            await _moveToDeadLetter(db, item, e.toString());
          }
        }
      }

      // Clean up old completed items
      await db.clearOldSyncItems();

      final result = SyncResult(
        success: failedCount == 0,
        processed: pendingItems.length,
        successCount: successCount,
        failedCount: failedCount,
        errors: errors,
      );

      _updateStatus(failedCount > 0 ? SyncStatus.hasErrors : SyncStatus.idle);
      return result;

    } catch (e) {
      _updateStatus(SyncStatus.error);
      return SyncResult.failure([e.toString()]);
    }
  }

  /// Sync single item
  Future<void> _syncItem(Isar db, SyncQueueEntity item) async {
    // Update status to syncing
    item.status = 'syncing';
    item.lastAttemptAt = DateTime.now();
    await db.writeTxn(() => db.collection<SyncQueueEntity>().put(item));

    // Perform sync based on entity type and operation
    switch (item.entityType) {
      case 'order':
        await _syncOrder(item);
        break;
      case 'delivery':
        await _syncDelivery(item);
        break;
      case 'customer':
        await _syncCustomer(item);
        break;
      case 'product':
        await _syncProduct(item);
        break;
      default:
        // Generic API call
        await _genericSync(item);
    }

    // Mark as completed
    await db.markSyncCompleted(item.id);
  }

  /// Sync order to server
  Future<void> _syncOrder(SyncQueueEntity item) async {
    final payload = item.payload;
    
    switch (item.operation) {
      case 'create':
        await _apiService.post('/orders', payload);
        break;
      case 'update':
        await _apiService.put('/orders/${item.entityId}', payload);
        break;
      case 'delete':
        await _apiService.delete('/orders/${item.entityId}');
        break;
    }
  }

  /// Sync delivery completion to server
  Future<void> _syncDelivery(SyncQueueEntity item) async {
    final payload = item.payload;
    
    // Upload photos first if any
    List<String> uploadedUrls = [];
    final photoPaths = payload['photoPaths'] as List<String>? ?? [];
    
    for (final path in photoPaths) {
      try {
        final url = await _uploadPhoto(path);
        uploadedUrls.add(url);
      } catch (e) {
        // Continue with other photos
        print('Failed to upload photo: $e');
      }
    }

    // Update payload with uploaded URLs
    payload['photoUrls'] = uploadedUrls;
    
    // Send delivery completion
    await _apiService.post('/deliveries/${item.entityId}/complete', payload);
  }

  /// Sync customer to server
  Future<void> _syncCustomer(SyncQueueEntity item) async {
    final payload = item.payload;
    
    switch (item.operation) {
      case 'create':
        await _apiService.post('/customers', payload);
        break;
      case 'update':
        await _apiService.put('/customers/${item.entityId}', payload);
        break;
    }
  }

  /// Sync product changes
  Future<void> _syncProduct(SyncQueueEntity item) async {
    // Products are usually server-authoritative
    // This might be for offline-created products
    await _apiService.post('/products', item.payload);
  }

  /// Generic sync for other entity types
  Future<void> _genericSync(SyncQueueEntity item) async {
    final endpoint = '/${item.entityType}s';
    
    switch (item.operation) {
      case 'create':
        await _apiService.post(endpoint, item.payload);
        break;
      case 'update':
        await _apiService.put('$endpoint/${item.entityId}', item.payload);
        break;
      case 'delete':
        await _apiService.delete('$endpoint/${item.entityId}');
        break;
    }
  }

  /// Upload photo to server
  Future<String> _uploadPhoto(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File not found: $localPath');
    }

    final url = await _apiService.uploadFile(
      file,
      fieldName: 'photo',
    );
    if (url == null) throw Exception('Upload failed');
    return url;
  }

  /// Move failed item to dead letter queue
  Future<void> _moveToDeadLetter(Isar db, SyncQueueEntity item, String error) async {
    // In production, you might want to store these separately
    // For now, we just mark them with a special status
    item.status = 'dead_letter';
    item.errorMessage = error;
    await db.writeTxn(() => db.collection<SyncQueueEntity>().put(item));
  }

  /// Queue order creation
  Future<void> queueOrderCreation(Map<String, dynamic> orderData) async {
    final db = await IsarDatabase.getInstance();
    
    // Create offline order first
    final offlineOrder = OfflineOrder()
      ..localId = 'local_${DateTime.now().millisecondsSinceEpoch}'
      ..customerName = orderData['customerName']
      ..customerPhone = orderData['customerPhone']
      ..customerAddress = orderData['customerAddress']
      ..items = List<Map<String, dynamic>>.from(orderData['items'])
      ..total = orderData['total'].toDouble()
      ..status = 'pending'
      ..syncStatus = 'pending'
      ..createdAt = DateTime.now();

    await db.writeTxn(() => db.collection<OfflineOrder>().put(offlineOrder));

    // Add to sync queue
    await db.addToSyncQueue(
      entityType: 'order',
      entityId: offlineOrder.localId,
      operation: 'create',
      payload: orderData,
      priority: 5, // High priority for orders
    );
  }

  /// Queue delivery completion
  Future<void> queueDeliveryCompletion(
    String orderId, {
    required List<String> photoPaths,
    String? signaturePath,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final db = await IsarDatabase.getInstance();

    // Save offline delivery
    final offlineDelivery = OfflineDelivery()
      ..orderId = orderId
      ..photoPaths = photoPaths
      ..signaturePath = signaturePath
      ..notes = notes
      ..latitude = latitude
      ..longitude = longitude
      ..completedAt = DateTime.now()
      ..syncStatus = 'pending';

    await db.writeTxn(() => db.collection<OfflineDelivery>().put(offlineDelivery));

    // Add to sync queue with high priority
    await db.addToSyncQueue(
      entityType: 'delivery',
      entityId: orderId,
      operation: 'update',
      payload: {
        'orderId': orderId,
        'photoPaths': photoPaths,
        'signaturePath': signaturePath,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
        'completedAt': DateTime.now().toIso8601String(),
      },
      priority: 10, // Highest priority
    );
  }

  /// Cache products for offline use
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await IsarDatabase.getInstance();

    await db.writeTxn(() async {
      for (final productData in products) {
        final cached = CachedProduct()
          ..productId = productData['id']
          ..name = productData['name']
          ..sku = productData['sku']
          ..description = productData['description']
          ..basePrice = productData['basePrice']?.toDouble()
          ..unit = productData['unit']
          ..categoryId = productData['categoryId']
          ..categoryName = productData['categoryName']
          ..images = List<String>.from(productData['images'] ?? [])
          ..stockQuantity = productData['stockQuantity']
          ..cachedAt = DateTime.now()
          ..lastUpdatedAt = DateTime.now()
          ..barcode = productData['barcode'];

        await db.collection<CachedProduct>().put(cached);
      }
    });
  }

  /// Get cached products
  Future<List<CachedProduct>> getCachedProducts({String? categoryId}) async {
    final db = await IsarDatabase.getInstance();

    if (categoryId != null) {
      return await db.collection<CachedProduct>()
          .filter()
          .categoryIdEqualTo(categoryId)
          .findAll();
    }

    return await db.collection<CachedProduct>().where().findAll();
  }

  /// Search cached products
  Future<List<CachedProduct>> searchCachedProducts(String query) async {
    final db = await IsarDatabase.getInstance();

    return await db.collection<CachedProduct>()
        .filter()
        .nameContains(query, caseSensitive: false)
        .or()
        .skuContains(query, caseSensitive: false)
        .or()
        .barcodeContains(query)
        .findAll();
  }

  /// Cache customers
  Future<void> cacheCustomers(List<Map<String, dynamic>> customers) async {
    final db = await IsarDatabase.getInstance();

    await db.writeTxn(() async {
      for (final customerData in customers) {
        final cached = CachedCustomer()
          ..customerId = customerData['id']
          ..name = customerData['name']
          ..phone = customerData['phone']
          ..email = customerData['email']
          ..address = customerData['address']
          ..companyName = customerData['companyName']
          ..inn = customerData['inn']
          ..totalOrders = customerData['totalOrders'] ?? 0
          ..totalRevenue = customerData['totalRevenue']?.toDouble() ?? 0
          ..cachedAt = DateTime.now()
          ..lastUpdatedAt = DateTime.now()
          ..assignedTo = customerData['assignedTo']
          ..notes = customerData['notes']
          ..isVerified = customerData['isVerified'] ?? false;

        final existing = await db.collection<CachedCustomer>().filter().customerIdEqualTo(cached.customerId).findFirst();
        if (existing != null) {
          cached.id = existing.id;
        }
        await db.collection<CachedCustomer>().put(cached);
      }
    });
  }

  /// Get sync statistics
  Future<SyncStatistics> getStatistics() async {
    final db = await IsarDatabase.getInstance();

    final pendingCount = await db.getPendingSyncCount();
    final totalQueue = await db.collection<SyncQueueEntity>().count();
    final offlineOrdersCount = await db.collection<OfflineOrder>().count();
    final offlineDeliveriesCount = await db.collection<OfflineDelivery>().count();
    final cachedProductsCount = await db.collection<CachedProduct>().count();
    final cachedCustomersCount = await db.collection<CachedCustomer>().count();

    return SyncStatistics(
      pendingSyncItems: pendingCount,
      totalQueueItems: totalQueue,
      offlineOrders: offlineOrdersCount,
      offlineDeliveries: offlineDeliveriesCount,
      cachedProducts: cachedProductsCount,
      cachedCustomers: cachedCustomersCount,
    );
  }

  /// Update status and notify listeners
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  hasErrors,
  error,
}

/// Sync result
class SyncResult {
  final bool success;
  final int processed;
  final int successCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.processed,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  factory SyncResult.success({required int processed}) => SyncResult(
        success: true,
        processed: processed,
        successCount: processed,
        failedCount: 0,
        errors: [],
      );

  factory SyncResult.failure(List<String> errors) => SyncResult(
        success: false,
        processed: 0,
        successCount: 0,
        failedCount: errors.length,
        errors: errors,
      );

  factory SyncResult.alreadySyncing() => SyncResult(
        success: false,
        processed: 0,
        successCount: 0,
        failedCount: 0,
        errors: ['Already syncing'],
      );
}

/// Sync statistics
class SyncStatistics {
  final int pendingSyncItems;
  final int totalQueueItems;
  final int offlineOrders;
  final int offlineDeliveries;
  final int cachedProducts;
  final int cachedCustomers;

  SyncStatistics({
    required this.pendingSyncItems,
    required this.totalQueueItems,
    required this.offlineOrders,
    required this.offlineDeliveries,
    required this.cachedProducts,
    required this.cachedCustomers,
  });

  bool get hasPendingItems => pendingSyncItems > 0;
}
