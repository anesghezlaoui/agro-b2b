import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';
import 'home_landing_screen.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeLandingScreen(),
      CatalogScreen(),
      CartScreen(),
      OrdersScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: const Text('AgroB2B'),
              actions: [
                Consumer<NotificationsProvider>(
                  builder: (context, notifications, _) => IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ).then((_) => notifications.refresh()),
                    icon: notifications.unreadCount > 0
                        ? Badge.count(
                            count: notifications.unreadCount,
                            child: const Icon(Icons.notifications_outlined),
                          )
                        : const Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),
      body: pages[_currentIndex],
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) => NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Produits',
            ),
            NavigationDestination(
              icon: cart.itemsCount > 0
                  ? Badge.count(
                      count: cart.itemsCount,
                      child: const Icon(Icons.shopping_cart_outlined),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'Panier',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Commandes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
