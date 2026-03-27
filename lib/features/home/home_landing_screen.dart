import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_provider.dart';
import '../catalog/catalog_provider.dart';
import '../catalog/category_detail_screen.dart';
import '../catalog/product_search_screen.dart';
import '../catalog/widgets/product_quick_tile.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_screen.dart';
import 'category_visuals.dart';

class HomeLandingScreen extends StatefulWidget {
  const HomeLandingScreen({super.key});

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchProducts();
    });
  }

  Future<void> _openSearch(BuildContext context) async {
    final main = await Navigator.push<String?>(
      context,
      MaterialPageRoute<String?>(
        builder: (_) => const ProductSearchScreen(),
      ),
    );
    if (!context.mounted || main == null || main.isEmpty) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(mainCategory: main),
      ),
    );
  }

  int _crossAxisCount(double width) {
    // 4 colonnes demandées ; sur très petit écran on passe à 3 pour lisibilité.
    if (width < 340) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<CatalogProvider, NotificationsProvider>(
      builder: (context, catalog, notifications, _) {
        final mains = catalog.mainCategories;

        return ColoredBox(
          color: theme.colorScheme.surface,
          child: RefreshIndicator(
            onRefresh: catalog.fetchProducts,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroBlock(
                    onSearch: () => _openSearch(context),
                    onNotifications: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ).then((_) => notifications.refresh()),
                    unreadCount: notifications.unreadCount,
                  ),
                ),
                if (catalog.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Rayons principaux',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Touchez une vignette',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxis = _crossAxisCount(constraints.maxWidth);
                      if (mains.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Text(
                            'Aucun rayon pour l’instant. Tirez vers le bas pour actualiser.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxis,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: crossAxis >= 4 ? 0.78 : 0.82,
                          ),
                          itemCount: mains.length,
                          itemBuilder: (context, index) {
                            final name = mains[index];
                            final visuals = CategoryVisuals.forName(name);
                            final meta = catalog.metaForMainCategory(name);
                            final productCount =
                                catalog.productCountInMain(name);
                            final subcategoryCount =
                                catalog.subcategoryCountInMain(name);
                            final img = catalog
                                    .representativeImageForMain(name) ??
                                'https://picsum.photos/seed/${Uri.encodeComponent(name)}/400/400';

                            return _CategoryMarketingCard(
                              title: name,
                              productCount: productCount,
                              categoryCount: subcategoryCount,
                              imageUrl: img,
                              iconUrl: meta != null &&
                                      meta.showIcon &&
                                      meta.iconUrl.isNotEmpty
                                  ? meta.iconUrl
                                  : null,
                              background: visuals.$1,
                              accent: visuals.$2,
                              icon: visuals.$3,
                              showPromo: catalog.mainHasPromo(name),
                              showTop: catalog.mainHasTopSeller(name),
                              onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CategoryDetailScreen(mainCategory: name),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (catalog.frequentProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                      child: Text(
                        'Réassort rapide',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: catalog.frequentProducts.length,
                        itemBuilder: (context, i) {
                          final p = catalog.frequentProducts[i];
                          return ProductQuickTile(product: p);
                        },
                      ),
                    ),
                  ),
                ],
                if (catalog.promotions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Promotions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: catalog.promotions.length.clamp(0, 6),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = catalog.promotions[i];
                      return ListTile(
                        leading: const Icon(Icons.local_offer_rounded),
                        title: Text(p.name),
                        subtitle: Text('${p.price.toStringAsFixed(0)} DA'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          onPressed: () =>
                              context.read<CartProvider>().addProduct(p),
                        ),
                      );
                    },
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.onSearch,
    required this.onNotifications,
    required this.unreadCount,
  });

  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: CachedNetworkImage(
                  imageUrl: 'https://picsum.photos/seed/agrohero/1200/500',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AgroB2B',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onNotifications,
                        icon: unreadCount > 0
                            ? Badge.count(
                                count: unreadCount,
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.notifications_outlined,
                                color: theme.colorScheme.onPrimary,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'وقتك غالي... ما تضيعوش',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'كلش متوفر بسهولة من غير تنقل يومي',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rechercher un produit',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMarketingCard extends StatefulWidget {
  const _CategoryMarketingCard({
    required this.title,
    required this.productCount,
    required this.categoryCount,
    required this.imageUrl,
    this.iconUrl,
    required this.background,
    required this.accent,
    required this.icon,
    required this.showPromo,
    required this.showTop,
    required this.onTap,
  });

  final String title;
  final int productCount;
  final int categoryCount;
  final String imageUrl;

  /// Icône téléversée dans l’admin (prioritaire sur [icon] Material).
  final String? iconUrl;
  final Color background;
  final Color accent;
  final IconData icon;
  final bool showPromo;
  final bool showTop;
  final VoidCallback onTap;

  @override
  State<_CategoryMarketingCard> createState() => _CategoryMarketingCardState();
}

class _CategoryMarketingCardState extends State<_CategoryMarketingCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = _hovering ? 1.03 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Material(
          color: widget.background,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        errorWidget: (_, __, ___) => Container(
                          color: widget.accent.withValues(alpha: 0.16),
                          child: Icon(
                            widget.icon,
                            size: 34,
                            color: widget.accent,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              theme.colorScheme.surface.withValues(alpha: 0.92),
                          child: widget.iconUrl != null &&
                                  widget.iconUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.iconUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Icon(
                                      widget.icon,
                                      size: 20,
                                      color: widget.accent,
                                    ),
                                  ),
                                )
                              : Icon(
                                  widget.icon,
                                  size: 20,
                                  color: widget.accent,
                                ),
                        ),
                      ),
                      if (widget.showPromo)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: _MiniBadge(
                            label: 'Promo',
                            color: theme.colorScheme.error,
                            onColor: theme.colorScheme.onError,
                          ),
                        )
                      else if (widget.showTop)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: _MiniBadge(
                            label: 'Top',
                            color: theme.colorScheme.tertiary,
                            onColor: theme.colorScheme.onTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.categoryCount} catégories • ${widget.productCount} produits',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: widget.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
