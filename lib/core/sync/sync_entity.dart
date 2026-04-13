import 'package:isar/isar.dart';
import 'dart:convert';

part 'sync_entity.g.dart';

/// Sync queue entity - stores pending operations
@Collection()
class SyncQueueEntity {
  Id id = Isar.autoIncrement;
  
  /// Entity type (order, delivery, customer, etc.)
  late String entityType;
  
  /// Entity ID (local or remote)
  late String entityId;
  
  /// Operation type: create, update, delete
  late String operation;
  
  /// JSON payload stored as String for Isar
  String payloadJson = '{}';

  @ignore
  Map<String, dynamic> get payload => jsonDecode(payloadJson);
  set payload(Map<String, dynamic> value) => payloadJson = jsonEncode(value);
  
  /// Priority (higher = more important)
  int priority = 0;
  
  /// Status: pending, syncing, completed, failed
  late String status;
  
  /// Creation timestamp
  late DateTime createdAt;
  
  /// Last sync attempt timestamp
  DateTime? lastAttemptAt;
  
  /// Sync completion timestamp
  DateTime? syncedAt;
  
  /// Retry count
  int retryCount = 0;
  
  /// Error message if failed
  String? errorMessage;
}

/// Offline order entity
@Collection()
class OfflineOrder {
  Id id = Isar.autoIncrement;
  
  /// Local ID (until synced)
  late String localId;
  
  /// Remote ID (after sync)
  String? remoteId;
  
  /// Customer info
  late String customerName;
  late String customerPhone;
  String? customerAddress;
  
  /// Order items as JSON
  String itemsJson = '[]';

  @ignore
  List<Map<String, dynamic>> get items {
    final list = jsonDecode(itemsJson) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
  set items(List<Map<String, dynamic>> value) => itemsJson = jsonEncode(value);
  
  /// Order total
  late double total;
  
  /// Order status
  late String status; // draft, pending, confirmed, etc.
  
  /// Sync status
  late String syncStatus; // pending, synced, error
  
  /// Timestamps
  late DateTime createdAt;
  DateTime? syncedAt;
  
  /// Error info
  String? errorMessage;
}

/// Offline delivery completion entity
@Collection()
class OfflineDelivery {
  Id id = Isar.autoIncrement;
  
  /// Delivery/order ID
  late String orderId;
  
  /// Photo paths (local storage)
  late List<String> photoPaths;
  
  /// Signature data (base64 or path)
  String? signaturePath;
  
  /// Notes
  String? notes;
  
  /// GPS coordinates
  double? latitude;
  double? longitude;
  
  /// Completion timestamp
  late DateTime completedAt;
  
  /// Sync status
  late String syncStatus;
  
  /// Uploaded photo URLs (after sync)
  List<String>? uploadedPhotoUrls;
}

/// Cached product for offline catalog
@Collection()
class CachedProduct {
  Id id = Isar.autoIncrement;
  
  /// Remote product ID
  late String productId;
  
  /// Product data
  late String name;
  late String sku;
  String? description;
  double? basePrice;
  String? unit;
  
  /// Category
  String? categoryId;
  String? categoryName;
  
  /// Images (local paths or URLs)
  List<String>? images;
  String? localImagePath;
  
  /// Stock info
  int? stockQuantity;
  
  /// Cache metadata
  late DateTime cachedAt;
  DateTime? lastUpdatedAt;
  
  /// Is favorite/bookmarked
  bool isFavorite = false;
  
  /// Custom attributes
  String? attributesJson;
  
  @ignore
  Map<String, dynamic>? get attributes {
    if (attributesJson == null) return null;
    return jsonDecode(attributesJson!) as Map<String, dynamic>;
  }
  set attributes(Map<String, dynamic>? value) {
    attributesJson = value == null ? null : jsonEncode(value);
  }
  
  /// Index for faster queries
  @Index()
  String? barcode;
}

/// Cached customer for offline access
@Collection()
class CachedCustomer {
  Id id = Isar.autoIncrement;
  
  /// Remote customer ID
  late String customerId;
  
  /// Customer data
  late String name;
  late String phone;
  String? email;
  String? address;
  double? latitude;
  double? longitude;
  
  /// Business info
  String? companyName;
  String? inn;
  
  /// Order history summary
  int totalOrders = 0;
  double totalRevenue = 0;
  DateTime? lastOrderAt;
  
  /// Cache metadata
  late DateTime cachedAt;
  DateTime? lastUpdatedAt;
  
  /// Assigned sales rep
  String? assignedTo;
  
  /// Notes
  String? notes;
  
  /// Is verified
  bool isVerified = false;
}
