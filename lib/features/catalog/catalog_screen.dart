import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  return _CatalogProductRow(product: product);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogProductRow extends StatefulWidget {
  const _CatalogProductRow({required this.product});

  final Product product;

  @override
  State<_CatalogProductRow> createState() => _CatalogProductRowState();
}

class _CatalogProductRowState extends State<_CatalogProductRow> {
  ConditionnementOption? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.product.defaultConditionnement;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final showSelect =
        product.showConditionnement && product.conditionnements.isNotEmpty;
    final displayPrice = _selected?.prix ?? product.price;
    final displayStock = _selected?.stock ?? product.stock;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  memCacheWidth: 400,
                  memCacheHeight: 400,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (showSelect) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          iconSize: 0,
                          value: _selected?.id,
                          items: product.conditionnements
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(
                                    '${c.type} (${c.unite})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            setState(() {
                              _selected = product.conditionnements
                                  .firstWhere((c) => c.id == id);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${displayPrice.toStringAsFixed(0)} DA • Stock: $displayStock',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final qty =
                    cart.quantityFor(product, conditionnement: _selected);
                if (qty <= 0) {
                  return IconButton.filledTonal(
                    onPressed: () =>
                        cart.addOne(product, conditionnement: _selected),
                    icon: const Icon(Icons.add_shopping_cart),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            cart.removeOne(product, conditionnement: _selected),
                        icon: const Icon(Icons.remove, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text('$qty', style: theme.textTheme.labelLarge),
                      IconButton(
                        onPressed: () =>
                            cart.addOne(product, conditionnement: _selected),
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
