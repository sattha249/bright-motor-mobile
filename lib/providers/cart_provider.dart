import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/product_model.dart';

final cartProvider = StateNotifierProvider.autoDispose<CartProvider, List<Product>>((ref) {
  return CartProvider([]);
});


final cartWithQuantityProvider = Provider.autoDispose<Map<Product, int>>((ref) {
  //get items from cartProvider
  final items = ref.watch(cartProvider);
  return items.fold<Map<Product, int>>({}, (map, product) {
    map[product] = (map[product] ?? 0) + 1;
    return map;
  });
});

final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  final carts = ref.watch(cartProvider);
  return carts.length;
});

final cartTotalAmountProvider = Provider.autoDispose<double>((ref) {
  final carts = ref.watch(cartProvider);
  return carts.fold(0.0, (total, product) {
    return total + double.parse(product.sellPrice);
  });
});

class CartProvider extends StateNotifier<List<Product>> {
  final Map<Product, int> _items = {};

  CartProvider(super.state);

  void addItem(Product product) {
    state = [...state, product];
  }

  void removeItem(Product product) {
    state = [...state]..remove(product);
  }

  void clear() {
    state = [];
  }
} 