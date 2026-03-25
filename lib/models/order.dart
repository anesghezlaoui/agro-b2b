import 'cart_item.dart';
import 'product.dart';

enum OrderStatus { pending, preparing, delivering, delivered }
enum DeliveryType { livraison, retrait }

class Order {
  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.deliveryType,
  });

  final int id;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DeliveryType deliveryType;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? <dynamic>[];
    final items = rawItems.whereType<Map<String, dynamic>>().map((item) {
      final productJson = (item['produit'] ?? item['product']) as Map<String, dynamic>? ??
          <String, dynamic>{
            'id': item['product_id'] ?? 0,
            'name': item['product_name'] ?? 'Produit',
            'price': item['prix'] ?? item['price'] ?? 0,
            'stock': 0,
            'image': '',
            'category_path': <String>[],
          };
      return CartItem(
        product: Product.fromJson(productJson),
        quantity: _asInt(item['quantite'] ?? item['quantity']),
      );
    }).toList();

    return Order(
      id: _asInt(json['id']),
      items: items,
      total: _asDouble(json['total']),
      status: _parseStatus(json['statut'] ?? json['status']),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? json['date'] ?? '').toString()) ??
              DateTime.now(),
      deliveryType:
          _parseDeliveryType(json['delivery_type'] ?? json['type_livraison']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total': total,
      'status': status.name,
      'delivery_type': deliveryType.name,
      'items': items
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList(),
    };
  }

  static OrderStatus _parseStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase() ?? '';
    if (value.contains('prep')) return OrderStatus.preparing;
    if (value.contains('livr') && !value.contains('livree')) {
      return OrderStatus.delivering;
    }
    if (value.contains('deliv') || value.contains('livree') || value.contains('livré')) {
      return OrderStatus.delivered;
    }
    return OrderStatus.pending;
  }

  static DeliveryType _parseDeliveryType(dynamic raw) {
    final value = raw?.toString().toLowerCase() ?? '';
    return value.contains('retrait') ? DeliveryType.retrait : DeliveryType.livraison;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
