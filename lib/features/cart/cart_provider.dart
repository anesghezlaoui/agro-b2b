import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemsCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0.0, (sum, item) => sum + item.total);

  void addProduct(Product product, {ConditionnementOption? conditionnement}) {
    final key = '${product.id}-${conditionnement?.id ?? 0}';
    final existing = _items.where((item) => item.key == key);
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
    } else {
      _items.add(
        CartItem(
            product: product, quantity: 1, conditionnement: conditionnement),
      );
    }
    notifyListeners();
  }

  int quantityFor(Product product, {ConditionnementOption? conditionnement}) {
    final key = '${product.id}-${conditionnement?.id ?? 0}';
    for (final item in _items) {
      if (item.key == key) return item.quantity;
    }
    return 0;
  }

  void addOne(Product product, {ConditionnementOption? conditionnement}) {
    addProduct(product, conditionnement: conditionnement);
  }

  void removeOne(Product product, {ConditionnementOption? conditionnement}) {
    final key = '${product.id}-${conditionnement?.id ?? 0}';
    for (final item in _items) {
      if (item.key == key) {
        decrement(item);
        return;
      }
    }
  }

  void increment(CartItem item) {
    item.quantity += 1;
    notifyListeners();
  }

  void decrement(CartItem item) {
    if (item.quantity <= 1) {
      _items.remove(item);
    } else {
      item.quantity -= 1;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
