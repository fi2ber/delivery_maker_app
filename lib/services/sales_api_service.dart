import 'package:dio/dio.dart';
import 'api_service.dart';

/// Sales API Service
/// Handles catalog, orders, and customer management for sales reps
class SalesApiService {
  final ApiService _api;

  SalesApiService(this._api);

  // ==================== Catalog ====================
  
  /// Get product catalog
  Future<List<Product>> getCatalog({String? categoryId}) async {
    final response = await _api.get('/products', queryParameters: {
      if (categoryId != null) 'category': categoryId,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> products = data['data'] ?? [];
      return products.map((p) => Product.fromJson(p)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load catalog');
  }

  /// Get product categories
  Future<List<Category>> getCategories() async {
    final response = await _api.get('/catalog/categories');
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> categories = data['data'] ?? [];
      return categories.map((c) => Category.fromJson(c)).toList();
    }
    return [];
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) async {
    final response = await _api.get('/products/search', queryParameters: {
      'q': query,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> products = data['data'] ?? [];
      return products.map((p) => Product.fromJson(p)).toList();
    }
    return [];
  }

  // ==================== Customers ====================
  
  /// Get customers list
  Future<List<Customer>> getCustomers({String? search}) async {
    final response = await _api.get('/customers', queryParameters: {
      if (search != null) 'search': search,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> customers = data['data'] ?? [];
      return customers.map((c) => Customer.fromJson(c)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load customers');
  }

  /// Register new customer
  Future<Customer> registerCustomer({
    required String firstName,
    String? lastName,
    required String phone,
    String? address,
    String? telegramId,
  }) async {
    final response = await _api.post('/customers', {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'telegramId': telegramId,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      return Customer.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to register customer');
  }

  /// Search customers by phone or name
  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _api.get('/customers/search', queryParameters: {
      'q': query,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> customers = data['data'] ?? [];
      return customers.map((c) => Customer.fromJson(c)).toList();
    }
    return [];
  }

  // ==================== Orders ====================
  
  /// Create new order
  Future<Order> createOrder({
    required String customerId,
    required List<OrderItem> items,
    String? deliveryAddress,
    String? comment,
  }) async {
    final response = await _api.post('/sales/orders', {
      'customerId': customerId,
      'items': items.map((i) => i.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'comment': comment,
    });
    
    final data = response.data;
    if (data['success'] == true) {
      return Order.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create order');
  }

  /// Get my orders (for sales rep)
  Future<List<Order>> getMyOrders() async {
    final response = await _api.get('/sales/orders/my');
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> orders = data['data'] ?? [];
      return orders.map((o) => Order.fromJson(o)).toList();
    }
    return [];
  }

  // ==================== Dashboard ====================

  /// Get sales rep dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/sales-rep/my-stats');
    return response.data;
  }

  /// Get my top products
  Future<List<dynamic>> getTopProducts({int limit = 5}) async {
    final response = await _api.get('/sales-rep/top-products', queryParameters: {
      'limit': limit.toString(),
    });
    return response.data is List ? response.data : [];
  }

  /// Get my top customers
  Future<List<dynamic>> getTopCustomers({int limit = 5}) async {
    final response = await _api.get('/sales-rep/top-customers', queryParameters: {
      'limit': limit.toString(),
    });
    return response.data is List ? response.data : [];
  }

  // ==================== My Customers (Sales Rep) ====================

  /// Get my customers with pagination
  Future<Map<String, dynamic>> getMyCustomers({int page = 1, int limit = 20}) async {
    final response = await _api.get('/sales-rep/my-customers', queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  // ==================== My Orders (Sales Rep) ====================

  /// Get my orders with pagination and optional status filter
  Future<Map<String, dynamic>> getMyOrdersPaginated({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _api.get('/sales-rep/my-orders', queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    });
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  /// Create quick order
  Future<Map<String, dynamic>> createQuickOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    String? deliveryAddress,
    String? deliveryDate,
    String? notes,
  }) async {
    final response = await _api.post('/sales-rep/quick-order', {
      'customerId': customerId,
      'items': items,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryDate != null) 'deliveryDate': deliveryDate,
      if (notes != null) 'notes': notes,
    });
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  // ==================== Van Stock ====================
  
  /// Get current van stock
  Future<List<StockItem>> getVanStock() async {
    final response = await _api.get('/sales/van-stock');
    
    final data = response.data;
    if (data['success'] == true) {
      final List<dynamic> stock = data['data'] ?? [];
      return stock.map((s) => StockItem.fromJson(s)).toList();
    }
    return [];
  }
}

// ==================== Models ====================

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final String? unit;
  final Category? category;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.unit,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    price: (json['price'] ?? 0).toDouble(),
    image: json['image'],
    unit: json['unit'] ?? 'шт',
    category: json['category'] != null 
      ? Category.fromJson(json['category']) 
      : null,
  );
}

class Category {
  final String id;
  final String name;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'],
  );
}

class Customer {
  final String id;
  final String firstName;
  final String? lastName;
  final String phone;
  final String? address;
  final String? telegramId;

  Customer({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.phone,
    this.address,
    this.telegramId,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'],
    phone: json['phone'] ?? '',
    address: json['address'],
    telegramId: json['telegramId'],
  );
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    quantity: json['quantity'] ?? 0,
    price: (json['price'] ?? 0).toDouble(),
  );
}

class Order {
  final String id;
  final String customerName;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.customerName,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? '',
    customerName: json['customer']?['firstName'] ?? 'Unknown',
    status: json['status'] ?? 'pending',
    totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    items: (json['items'] as List? ?? [])
      .map((i) => OrderItem.fromJson(i))
      .toList(),
  );
}

class StockItem {
  final String productId;
  final String productName;
  final int quantity;
  final String? unit;

  StockItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    quantity: json['quantity'] ?? 0,
    unit: json['unit'],
  );
}
