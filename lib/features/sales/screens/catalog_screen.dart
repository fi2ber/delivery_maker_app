import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../services/sales_api_service.dart' hide Product;
import '../../../core/di/service_locator.dart';
import '../bloc/catalog_bloc.dart';
import '../widgets/product_card.dart';

/// Product catalog screen with API integration
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatalogBloc(getIt<SalesApiService>())..add(LoadCatalog()),
      child: const _CatalogScreenContent(),
    );
  }
}

class _CatalogScreenContent extends StatelessWidget {
  const _CatalogScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: IOSTheme.labelPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Каталог',
                      style: IOSTheme.title1,
                    ),
                  ),
                  // Cart button
                  BlocBuilder<CatalogBloc, CatalogState>(
                    builder: (context, state) {
                      final itemCount = state.cartItems.length;
                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shopping_cart_outlined,
                              color: IOSTheme.labelPrimary,
                            ),
                            onPressed: () => _showCart(context),
                          ),
                          if (itemCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: IOSTheme.systemRed,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  itemCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: IOSTheme.radiusLg,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск продуктов...',
                    hintStyle: TextStyle(color: IOSTheme.labelTertiary),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: IOSTheme.labelSecondary),
                  ),
                  onChanged: (query) {
                    context.read<CatalogBloc>().add(SearchProducts(query));
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categories
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                if (state.categories.isEmpty) return const SizedBox.shrink();
                
                return SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      final isSelected = state.selectedCategory?.id == category.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (_) {
                            context.read<CatalogBloc>().add(
                              SelectCategory(category),
                            );
                          },
                          selectedColor: IOSTheme.systemBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : IOSTheme.labelPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Products grid
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return _ErrorState(
                      error: state.error!,
                      onRetry: () {
                        context.read<CatalogBloc>().add(LoadCatalog());
                      },
                    );
                  }

                  if (state.products.isEmpty) {
                    return const Center(
                      child: Text('Нет продуктов'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final inCart = state.cartItems.any(
                        (i) => i.productId == product.id,
                      );
                      
                      return ProductCard(
                        product: product,
                        quantity: inCart ? 1.0 : 0.0,
                        onAdd: () {
                          context.read<CatalogBloc>().add(
                            AddToCart(product),
                          );
                          IOSTheme.success();
                        },
                        onRemove: () {
                          context.read<CatalogBloc>().add(
                            RemoveFromCart(product.id),
                          );
                        },
                        onUpdateQuantity: (qty) {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailsSheet(product: product),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<CatalogBloc>(),
        child: const _CartSheet(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: IOSTheme.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: IOSTheme.headline,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: IOSTheme.bodyMedium.copyWith(
              color: IOSTheme.labelSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          IOSButton(
            onPressed: onRetry,
            text: 'Повторить',
          ),
        ],
      ),
    );
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final Product product;

  const _ProductDetailsSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: IOSTheme.bgPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: IOSTheme.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Image
          if (product.image != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(product.image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: IOSTheme.title1),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: IOSTheme.bodyMedium.copyWith(
                      color: IOSTheme.labelSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} сум',
                      style: IOSTheme.title2.copyWith(
                        color: IOSTheme.systemBlue,
                      ),
                    ),
                    Text(
                      'за ${product.unit}',
                      style: IOSTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Add to cart button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.read<CatalogBloc>().add(AddToCart(product));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: IOSTheme.systemBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Добавить в корзину'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: IOSTheme.bgPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final items = state.cartItems;
          final total = items.fold<double>(
            0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: IOSTheme.separator),
                  ),
                ),
                child: Row(
                  children: [
                    Text('Корзина', style: IOSTheme.title1),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<CatalogBloc>().add(ClearCart());
                      },
                      child: Text(
                        'Очистить',
                        style: TextStyle(color: IOSTheme.systemRed),
                      ),
                    ),
                  ],
                ),
              ),

              // Items
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Корзина пуста',
                          style: IOSTheme.bodyMedium.copyWith(
                            color: IOSTheme.labelSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.productName),
                            subtitle: Text('${item.quantity} x ${item.price}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(item.quantity * item.price).toStringAsFixed(0)} сум',
                                  style: IOSTheme.headline,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: IOSTheme.systemRed,
                                  ),
                                  onPressed: () {
                                    context.read<CatalogBloc>().add(
                                      RemoveFromCart(item.productId),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Total and checkout
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: IOSTheme.separator),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Итого:', style: IOSTheme.headline),
                        Text(
                          '${total.toStringAsFixed(0)} сум',
                          style: IOSTheme.title1.copyWith(
                            color: IOSTheme.systemBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: items.isEmpty
                            ? null
                            : () => _checkout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IOSTheme.systemBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Оформить заказ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _checkout(BuildContext context) {
    // Navigate to customer selection for order
    Navigator.pop(context);
    // TODO: Navigate to order confirmation screen
  }
}
