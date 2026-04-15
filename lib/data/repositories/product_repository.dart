import 'package:isar/isar.dart';
import '../../core/database/isar_database.dart';
import '../../core/sync/sync_manager.dart';
import '../entities/product_entity.dart';

/// Repository for Product operations
/// Handles offline catalog and sync
class ProductRepository {
  final _syncEngine = SyncManager();

  /// Get products (from local DB - works offline)
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    bool inStockOnly = true,
  }) async {
    final db = await IsarDatabase.getInstance();

    var query = db.collection<ProductEntity>().filter();

    if (categoryId != null) {
      query = query.categoryIdEqualTo(categoryId);
    }

    if (inStockOnly) {
      query = query.inStockEqualTo(true);
    }

    return await query
        .isActiveEqualTo(true)
        .sortBySortOrder()
        .thenByName()
        .findAll();
  }

  /// Get product by ID
  Future<ProductEntity?> getProductById(String productId) async {
    final db = await IsarDatabase.getInstance();

    // Try by server ID
    var product =
        await db.collection<ProductEntity>().filter().serverIdEqualTo(productId).findFirst();

    // Try by local ID
    if (product == null && int.tryParse(productId) != null) {
      product = await db.collection<ProductEntity>().get(int.parse(productId));
    }

    return product;
  }

  /// Search products
  Future<List<ProductEntity>> searchProducts(String query) async {
    final db = await IsarDatabase.getInstance();

    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return await db.collection<ProductEntity>()
        .filter()
        .nameContains(lowerQuery, caseSensitive: false)
        .or()
        .skuContains(lowerQuery, caseSensitive: false)
        .and()
        .isActiveEqualTo(true)
        .findAll();
  }

  /// Get all categories
  Future<List<ProductCategory>> getCategories() async {
    final db = await IsarDatabase.getInstance();
    return await db.productCategorys
        .where()
        .sortByIsActive()
        .thenBySortOrder()
        .findAll();
  }

  /// Get category by ID
  Future<ProductCategory?> getCategoryById(String categoryId) async {
    final db = await IsarDatabase.getInstance();
    return await db.productCategorys
        .filter()
        .serverIdEqualTo(categoryId)
        .findFirst();
  }

  /// Save products from server (after sync)
  Future<void> saveProductsFromServer(List<ProductEntity> products) async {
    final db = await IsarDatabase.getInstance();

    await db.writeTxn(() async {
      for (final product in products) {
        // Check if exists
        final existing = await db.collection<ProductEntity>()
            .filter()
            .serverIdEqualTo(product.serverId)
            .findFirst();

        if (existing != null) {
          // Update if newer
          final serverUpdated = product.serverUpdatedAt;
          final localUpdated = existing.serverUpdatedAt;

          if (serverUpdated != null &&
              (localUpdated == null || serverUpdated.isAfter(localUpdated))) {
            product.id = existing.id;
            // product.syncStatus = SyncStatus.syncing;
            await db.collection<ProductEntity>().put(product);
          }
        } else {
          // New product
          // product.syncStatus = SyncStatus.syncing;
          await db.collection<ProductEntity>().put(product);
        }
      }
    });
  }

  /// Sync products with server
  /// Call when online to get latest catalog
  Future<void> syncProducts() async {
    // TODO: Implement actual API call
    // For now, this is a placeholder
    
    // 1. Get last sync timestamp
    // 2. Call API: GET /products?updated_after={timestamp}
    // 3. Save returned products
    // 4. Update last sync timestamp
  }

  /// Get featured/popular products
  Future<List<ProductEntity>> getFeaturedProducts({int limit = 10}) async {
    final db = await IsarDatabase.getInstance();

    // For now, return first active products
    // In production, use actual popularity metrics
    return await db.collection<ProductEntity>()
        .where()
        .sortByIsActive()
        .limit(limit)
        .findAll();
  }

  /// Get products with discount
  Future<List<ProductEntity>> getDiscountedProducts() async {
    final db = await IsarDatabase.getInstance();

    return await db.collection<ProductEntity>()
        .filter()
        .discountedPriceIsNotNull()
        .and()
        .isActiveEqualTo(true)
        .and()
        .inStockEqualTo(true)
        .findAll();
  }

  /// Update product (admin only)
  Future<void> updateProduct(ProductEntity product) async {
    final db = await IsarDatabase.getInstance();

    await db.writeTxn(() async {
      product.updatedAt = DateTime.now();
      product.syncStatus!.hasPendingChanges = true;
      await db.collection<ProductEntity>().put(product);
    });

    _syncEngine.syncAll();
  }

  /// Get total product count
  Future<int> getProductCount() async {
    final db = await IsarDatabase.getInstance();
    return await db.collection<ProductEntity>().where().count();
  }

  /// Get catalog last updated timestamp
  Future<DateTime?> getLastCatalogUpdate() async {
    final db = await IsarDatabase.getInstance();

    final products = await db.collection<ProductEntity>()
        .where()
        .sortByServerUpdatedAtDesc()
        .limit(1)
        .findAll();

    return products.isNotEmpty ? products.first.serverUpdatedAt : null;
  }
}
