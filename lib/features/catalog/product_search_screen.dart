import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_provider.dart';
import 'catalog_provider.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  late final TextEditingController _controller;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _q = widget.initialQuery.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          decoration: const InputDecoration(
            hintText: 'Produit, catégorie…',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _q = v.trim()),
          onSubmitted: (_) => setState(() {}),
        ),
      ),
      body: Consumer<CatalogProvider>(
        builder: (context, catalog, _) {
          final q = _q.toLowerCase();
          final suggestions = catalog.searchSuggestions(q);
          final products = catalog.productsMatchingQuery(q, limit: 80);

          if (q.isEmpty) {
            return Center(
              child: Text(
                'Tapez pour voir catégories et produits',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (suggestions.categories.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Catégories',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ...suggestions.categories.map(
                  (c) => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(c),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final main =
                          catalog.resolveMainForSearchSelection(c) ?? c;
                      Navigator.pop(context, main);
                    },
                  ),
                ),
              ],
              if (suggestions.categories.isNotEmpty && products.isNotEmpty)
                const Divider(height: 24),
              if (products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Produits',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ...products.map(
                (p) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: p.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.price.toStringAsFixed(0)} DA • ${p.categoryPath.join(' › ')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        context.read<CartProvider>().addProduct(p),
                  ),
                ),
              ),
              if (suggestions.categories.isEmpty && products.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun résultat pour « $_q »',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
