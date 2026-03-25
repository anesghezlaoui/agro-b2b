import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_provider.dart';
import 'catalog_provider.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogProvider>(
      builder: (context, catalog, _) {
        if (catalog.isLoading && catalog.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            if (catalog.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(catalog.errorMessage!)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: catalog.setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un produit',
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: catalog.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = catalog.categories[index];
                  return FilterChip(
                    label: Text(cat),
                    selected: false,
                    onSelected: (_) => catalog.setCategory(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: catalog.products.length,
                itemBuilder: (context, index) {
                  final product = catalog.products[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.price.toStringAsFixed(0)} DA • Stock: ${product.stock} • ${product.unitType.name}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () =>
                            context.read<CartProvider>().addProduct(product),
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
}
