import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    this.conditionnement,
  });

  final Product product;
  int quantity;
  final ConditionnementOption? conditionnement;

  double get unitPrice => conditionnement?.prix ?? product.price;
  String get unitLabel => conditionnement?.label ?? product.unitType.name;

  String get key => '${product.id}-${conditionnement?.id ?? 0}';

  double get total => quantity * unitPrice;
}
