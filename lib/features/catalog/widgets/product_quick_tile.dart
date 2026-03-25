import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/product.dart';

/// Tuile compacte pour listes horizontales (ajout rapide B2B).
class ProductQuickTile extends StatelessWidget {
  const ProductQuickTile({
    super.key,
    required this.product,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = '${product.price.toStringAsFixed(0)} DA';

    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: InkWell(
          onTap: onAdd,
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
                        fit: BoxFit.cover,
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
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        price,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(Icons.add, size: 20),
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
