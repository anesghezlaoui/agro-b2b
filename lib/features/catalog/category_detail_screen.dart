import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../models/product.dart';
import 'catalog_provider.dart';
import 'widgets/product_quick_tile.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.mainCategory});

  final String mainCategory;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  String _search = '';
  bool _promoOnly = false;
  bool _newOnly = false;
  int _priceSort = 0; // 0 none, 1 asc, 2 desc

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureKeys(Iterable<String> subs) {
    for (final s in subs) {
      _sectionKeys.putIfAbsent(s, GlobalKey.new);
    }
  }

  void _scrollToSub(String sub) {
    final key = _sectionKeys[sub];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  List<Product> _applyFilters(List<Product> list) {
    var out = List<Product>.from(list);
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.categoryPath.any((c) => c.toLowerCase().contains(q)),
          )
          .toList();
    }
    if (_promoOnly) out = out.where((p) => p.isPromo).toList();
    if (_newOnly) out = out.where((p) => p.isNew).toList();
    if (_priceSort == 1) {
      out.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 2) {
      out.sort((a, b) => b.price.compareTo(a.price));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = context.watch<CatalogProvider>();
    final rawGroups = catalog.productsBySubcategoryInMain(widget.mainCategory);
    _ensureKeys(rawGroups.keys);

    final groups = <String, List<Product>>{};
    for (final e in rawGroups.entries) {
      final filtered = _applyFilters(e.value);
      if (filtered.isNotEmpty) groups[e.key] = filtered;
    }
    final subs = groups.keys.toList();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 168,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.mainCategory,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (context, cart, _) => IconButton(
                  tooltip: 'Panier',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CartScreen(),
                    ),
                  ),
                  icon: cart.itemsCount > 0
                      ? Badge.count(
                          count: cart.itemsCount,
                          child: const Icon(Icons.shopping_cart_outlined),
                        )
                      : const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.65),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.fromLTRB(12, 88, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        hintText: 'Dans ${widget.mainCategory}…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(104),
              child: Material(
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Promo'),
                            selected: _promoOnly,
                            avatar: const Text('🔥'),
                            onSelected: (v) => setState(() => _promoOnly = v),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Nouveaux'),
                            selected: _newOnly,
                            avatar: const Text('✨'),
                            onSelected: (v) => setState(() => _newOnly = v),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              _priceSort == 0
                                  ? 'Prix'
                                  : _priceSort == 1
                                      ? 'Prix ↑'
                                      : 'Prix ↓',
                            ),
                            selected: _priceSort != 0,
                            avatar: const Icon(Icons.sort_rounded, size: 18),
                            onSelected: (_) {
                              setState(() {
                                _priceSort = (_priceSort + 1) % 3;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (subs.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: Row(
                          children: [
                            for (final s in subs) ...[
                              ActionChip(
                                label: Text(s),
                                onPressed: () => _scrollToSub(s),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (catalog.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catalog.errorMessage!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (subs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun produit dans cette catégorie pour le moment.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            )
          else
            ...subs.expand((sub) {
              final products = groups[sub] ?? [];
              return [
                SliverToBoxAdapter(
                  key: _sectionKeys[sub],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sub,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${products.length} art.',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 310,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        return ProductQuickTile(
                          product: p,
                        );
                      },
                    ),
                  ),
                ),
              ];
            }),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
