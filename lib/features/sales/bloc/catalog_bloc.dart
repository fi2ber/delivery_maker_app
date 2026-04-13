import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/sales_api_service.dart';

// Events
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCatalog extends CatalogEvent {}

class SearchProducts extends CatalogEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCategory extends CatalogEvent {
  final Category? category;
  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class AddToCart extends CatalogEvent {
  final Product product;
  const AddToCart(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCart extends CatalogEvent {
  final String productId;
  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ClearCart extends CatalogEvent {}

class UpdateQuantity extends CatalogEvent {
  final String productId;
  final int quantity;
  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

// States
class CatalogState extends Equatable {
  final bool isLoading;
  final List<Product> products;
  final List<Product> allProducts;
  final List<Category> categories;
  final Category? selectedCategory;
  final List<CartItem> cartItems;
  final String? error;

  const CatalogState({
    this.isLoading = false,
    this.products = const [],
    this.allProducts = const [],
    this.categories = const [],
    this.selectedCategory,
    this.cartItems = const [],
    this.error,
  });

  CatalogState copyWith({
    bool? isLoading,
    List<Product>? products,
    List<Product>? allProducts,
    List<Category>? categories,
    Category? selectedCategory,
    List<CartItem>? cartItems,
    String? error,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      allProducts: allProducts ?? this.allProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      cartItems: cartItems ?? this.cartItems,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    products,
    allProducts,
    categories,
    selectedCategory,
    cartItems,
    error,
  ];
}

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final String? image;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.image,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [productId, productName, price, quantity];
}

// Models
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final String unit;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.unit = 'шт',
  });

  factory Product.fromApi(dynamic p) => Product(
    id: p['id'] ?? '',
    name: p['name'] ?? '',
    description: p['description'],
    price: (p['price'] ?? 0).toDouble(),
    image: p['image'],
    unit: p['unit'] ?? 'шт',
  );
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromApi(dynamic c) => Category(
    id: c['id'] ?? '',
    name: c['name'] ?? '',
  );
}

// BLoC
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final SalesApiService _api;

  CatalogBloc(this._api) : super(const CatalogState()) {
    on<LoadCatalog>(_onLoadCatalog);
    on<SearchProducts>(_onSearchProducts);
    on<SelectCategory>(_onSelectCategory);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<UpdateQuantity>(_onUpdateQuantity);
  }

  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Load products and categories in parallel
      final results = await Future.wait([
        _api.getCatalog().catchError((_) => <SalesApiProduct>[]),
        _api.getCategories().catchError((_) => <SalesApiCategory>[]),
      ]);

      final apiProducts = results[0] as List<SalesApiProduct>;
      final apiCategories = results[1] as List<SalesApiCategory>;

      final products = apiProducts.map(Product.fromApi).toList();
      final categories = apiCategories.map(Category.fromApi).toList();

      emit(state.copyWith(
        isLoading: false,
        products: products,
        allProducts: products,
        categories: categories,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load catalog: $e',
      ));
    }
  }

  void _onSearchProducts(
    SearchProducts event,
    Emitter<CatalogState> emit,
  ) {
    final query = event.query.toLowerCase();
    
    if (query.isEmpty) {
      emit(state.copyWith(products: state.allProducts));
      return;
    }

    final filtered = state.allProducts.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    emit(state.copyWith(products: filtered));
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<CatalogState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));

    if (event.category == null) {
      emit(state.copyWith(products: state.allProducts));
      return;
    }

    // Filter by category
    // Note: In real implementation, you'd fetch from API with category filter
    // For now, just show all (assuming API already filtered)
  }

  void _onAddToCart(
    AddToCart event,
    Emitter<CatalogState> emit,
  ) {
    final existingIndex = state.cartItems.indexWhere(
      (item) => item.productId == event.product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final updatedItems = List<CartItem>.from(state.cartItems);
      updatedItems[existingIndex].quantity++;
      emit(state.copyWith(cartItems: updatedItems));
    } else {
      // Add new item
      final newItem = CartItem(
        productId: event.product.id,
        productName: event.product.name,
        price: event.product.price,
        image: event.product.image,
      );
      emit(state.copyWith(cartItems: [...state.cartItems, newItem]));
    }
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CatalogState> emit,
  ) {
    final updatedItems = state.cartItems
        .where((item) => item.productId != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedItems));
  }

  void _onClearCart(
    ClearCart event,
    Emitter<CatalogState> emit,
  ) {
    emit(state.copyWith(cartItems: const []));
  }

  void _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<CatalogState> emit,
  ) {
    final updatedItems = state.cartItems.map((item) {
      if (item.productId == event.productId) {
        return CartItem(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          image: item.image,
          quantity: event.quantity,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(cartItems: updatedItems));
  }
}

// Type aliases for API types
typedef SalesApiProduct = dynamic;
typedef SalesApiCategory = dynamic;
