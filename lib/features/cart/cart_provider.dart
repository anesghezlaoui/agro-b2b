import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemsCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0.0, (sum, item) => sum + item.total);

  void addProduct(Product product) {
    final existing = _items.where((item) => item.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void increment(int productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    item.quantity += 1;
    notifyListeners();
  }

  void decrement(int productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
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
