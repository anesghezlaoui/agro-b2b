import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../orders/orders_provider.dart';
import 'cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canGoBack = (ModalRoute.of(context)?.canPop ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        automaticallyImplyLeading: canGoBack,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Panier vide'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        '${item.unitLabel} • ${item.unitPrice.toStringAsFixed(0)} DA',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                context.read<CartProvider>().decrement(item),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            onPressed: () =>
                                context.read<CartProvider>().increment(item),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total: ${cart.total.toStringAsFixed(0)} DA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _showCheckoutDialog(context),
                      child: const Text('Valider la commande'),
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

  void _showCheckoutDialog(BuildContext context) {
    DeliveryType selected = DeliveryType.livraison;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Type de réception'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<DeliveryType>(
                  value: DeliveryType.livraison,
                  groupValue: selected,
                  title: const Text('Livraison'),
                  onChanged: (value) => setState(() => selected = value!),
                ),
                RadioListTile<DeliveryType>(
                  value: DeliveryType.retrait,
                  groupValue: selected,
                  title: const Text('Retrait'),
                  onChanged: (value) => setState(() => selected = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final cart = context.read<CartProvider>();
                  final orders = context.read<OrdersProvider>();
                  final ok = await orders.placeOrder(
                    cartItems: cart.items,
                    total: cart.total,
                    deliveryType: selected,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (ok) {
                    cart.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Commande enregistrée sur le serveur — visible dans Gestion',
                          ),
                        ),
                      );
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          orders.errorMessage ??
                              'Échec de l’envoi de la commande au serveur.',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
        );
      },
    );
  }
}
