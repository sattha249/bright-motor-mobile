import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((product, quantity) {
      total += double.parse(product.sellPrice) * quantity;
    });
    return total;
  }

  void addItem(Product product) {
    if (_items.containsKey(product)) {
      _items[product] = (_items[product] ?? 0) + 1;
    } else {
      _items[product] = 1;
    }
    notifyListeners();
  }

  void removeItem(Product product) {
    if (!_items.containsKey(product)) {
      return;
    }
    if (_items[product]! > 1) {
      _items[product] = _items[product]! - 1;
    } else {
      _items.remove(product);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
} 