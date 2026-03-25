import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import 'orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        if (ordersProvider.isLoading && ordersProvider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = ordersProvider.orders;
        if (orders.isEmpty) {
          return const Center(child: Text('Aucune commande pour le moment'));
        }
        return Column(
          children: [
            if (ordersProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ordersProvider.errorMessage!)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text('Commande #${order.id}'),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)} • ${order.total.toStringAsFixed(0)} DA',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_statusLabel(order.status)),
                          TextButton(
                            onPressed: () =>
                                context.read<OrdersProvider>().reorder(order),
                            child: const Text('Recommander'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
    }
  }
}
