import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import 'orders_repository.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this._repository);
  final OrdersRepository _repository;

  final List<Order> _orders = [];
  int _nextId = 1;
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => List.unmodifiable(_orders.reversed);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> placeOrder({
    required List<CartItem> cartItems,
    required double total,
    required DeliveryType deliveryType,
  }) async {
    if (cartItems.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createOrder(
        cartItems: cartItems,
        deliveryType: deliveryType,
      );
      if (created != null) {
        _orders.add(created);
        return true;
      }
      _errorMessage =
          'Réponse serveur incomplète. La commande n’a peut‑être pas été enregistrée.';
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage =
          'Erreur inattendue lors de la commande: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reorder(Order order) {
    _orders.add(
      Order(
        id: _nextId++,
        items: order.items
            .map(
              (e) => CartItem(
                product: e.product,
                quantity: e.quantity,
                conditionnement: e.conditionnement,
              ),
            )
            .toList(),
        total: order.total,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        deliveryType: order.deliveryType,
      ),
    );
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final remoteOrders = await _repository.fetchOrders();
      if (remoteOrders.isNotEmpty) {
        _orders
          ..clear()
          ..addAll(remoteOrders);
      }
    } catch (_) {
      _errorMessage = 'Impossible de synchroniser les commandes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
