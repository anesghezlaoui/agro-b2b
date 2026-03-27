import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_endpoints.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/pending_validation_screen.dart';
import 'features/cart/cart_provider.dart';
import 'features/catalog/catalog_provider.dart';
import 'features/catalog/catalog_repository.dart';
import 'features/home/home_shell.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/notifications/notifications_repository.dart';
import 'features/orders/orders_provider.dart';
import 'features/orders/orders_repository.dart';

class AgroB2BApp extends StatelessWidget {
  const AgroB2BApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient(baseUrl: ApiEndpoints.baseUrl)),
        Provider(
          create: (context) => AuthRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => CatalogRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => OrdersRepository(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => NotificationsRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(context.read<AuthRepository>(), context.read<ApiClient>())
                ..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => CatalogProvider(context.read<CatalogRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (context) => OrdersProvider(context.read<OrdersRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NotificationsProvider(context.read<NotificationsRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgroB2B',
        theme: AppTheme.light,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isBootstrapped) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!auth.isAuthenticated) return const AuthScreen();
            if (!auth.isValidatedByAdmin) {
              return const PendingValidationScreen();
            }
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
