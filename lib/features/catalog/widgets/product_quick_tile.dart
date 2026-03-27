import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart/cart_provider.dart';
import '../../../models/product.dart';

/// Tuile compacte pour listes horizontales (ajout rapide B2B).
class ProductQuickTile extends StatefulWidget {
  const ProductQuickTile({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<ProductQuickTile> createState() => _ProductQuickTileState();
}

class _ProductQuickTileState extends State<ProductQuickTile> {
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
    final selected = _selected;
    final displayPrice = selected?.prix ?? product.price;
    final displayUnite = selected?.unite ?? 1;
    final displayUnitPrice = selected?.prixUnitaire ?? product.price;
    final showSelect =
        product.showConditionnement && product.conditionnements.isNotEmpty;
    final bestId = product.conditionnements.isEmpty
        ? null
        : (product.conditionnements.toList()
              ..sort((a, b) => a.prixUnitaire.compareTo(b.prixUnitaire)))
            .first
            .id;
    final isBestPrice = selected != null && selected.id == bestId;
    final price = '${displayPrice.toStringAsFixed(0)} DA';

    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        height: 72,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        placeholder: (_, __) => Container(
                          height: 72,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 72,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: theme.colorScheme.outline),
                        ),
                      ),
                    ),
                    if (product.isPromo)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Promo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (showSelect) ...[
                  const SizedBox(height: 2),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        iconSize: 0,
                        value: selected?.id,
                        style: theme.textTheme.labelSmall,
                        selectedItemBuilder: (context) {
                          return product.conditionnements
                              .map((c) => Text(
                                    '${c.type} (${c.unite})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall,
                                  ))
                              .toList();
                        },
                        items: product.conditionnements
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  '${c.type} (${c.unite})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          setState(() {
                            _selected = product.conditionnements.firstWhere(
                              (c) => c.id == id,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '$displayUnite pcs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${displayUnitPrice.toStringAsFixed(0)} DA/unité',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (isBestPrice)
                            Text(
                              'Meilleur prix',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        final qty = cart.quantityFor(
                          product,
                          conditionnement: selected,
                        );
                        if (qty <= 0) {
                          return FilledButton.tonal(
                            onPressed: () => cart.addOne(
                              product,
                              conditionnement: selected,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Icon(Icons.add, size: 20),
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                            color: theme.colorScheme.surface,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => cart.removeOne(
                                  product,
                                  conditionnement: selected,
                                ),
                                icon: const Icon(Icons.remove, size: 16),
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                '$qty',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                onPressed: () => cart.addOne(
                                  product,
                                  conditionnement: selected,
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
