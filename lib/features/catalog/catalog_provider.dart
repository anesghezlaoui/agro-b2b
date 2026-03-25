import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'catalog_repository.dart';

/// Suggestions de recherche (catégories + aperçu produits distinct).
@immutable
class SearchSuggestionBundle {
  const SearchSuggestionBundle({
    required this.categories,
    required this.productPreviewIds,
  });

  final List<String> categories;
  final List<int> productPreviewIds;
}

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repository);
  final CatalogRepository _repository;

  final List<Product> _products = [
    Product(
      id: 1,
      name: 'Huile tournesol 5L',
      categoryPath: ['Alimentaire', 'Huiles'],
      price: 2450,
      stock: 120,
      imageUrl: 'https://picsum.photos/seed/huile5l/400/300',
      unitType: UnitType.carton,
      variantLabel: 'Tournesol',
      isPromo: true,
      isTopSeller: true,
    ),
    Product(
      id: 2,
      name: 'Sucre cristal 1kg',
      categoryPath: ['Épicerie', 'Sucres'],
      price: 130,
      stock: 320,
      imageUrl: 'https://picsum.photos/seed/sucre1kg/400/300',
      unitType: UnitType.piece,
      isTopSeller: true,
    ),
    Product(
      id: 3,
      name: 'Tomate concentrée 400g',
      categoryPath: ['Conserve', 'Tomate'],
      price: 95,
      stock: 560,
      imageUrl: 'https://picsum.photos/seed/tomate400/400/300',
      unitType: UnitType.piece,
      isNew: true,
    ),
    Product(
      id: 4,
      name: 'Eau minérale 1.5L (pack)',
      categoryPath: ['Boissons', 'Eau'],
      price: 180,
      stock: 800,
      imageUrl: 'https://picsum.photos/seed/eau15/400/300',
      unitType: UnitType.carton,
      isTopSeller: true,
    ),
    Product(
      id: 5,
      name: 'Jus d\'orange 1L',
      categoryPath: ['Boissons', 'Jus'],
      price: 220,
      stock: 200,
      imageUrl: 'https://picsum.photos/seed/jusorange/400/300',
      unitType: UnitType.piece,
      isPromo: true,
    ),
    Product(
      id: 6,
      name: 'Soda cola 33cl (pack)',
      categoryPath: ['Boissons', 'Soda'],
      price: 420,
      stock: 150,
      imageUrl: 'https://picsum.photos/seed/cola/400/300',
      unitType: UnitType.carton,
    ),
    Product(
      id: 7,
      name: 'Pommes Golden (caisse)',
      categoryPath: ['Fruits & Légumes', 'Fruits'],
      price: 3500,
      stock: 45,
      imageUrl: 'https://picsum.photos/seed/pommes/400/300',
      unitType: UnitType.carton,
      isTopSeller: true,
    ),
    Product(
      id: 8,
      name: 'Tomates rondes (caisse)',
      categoryPath: ['Fruits & Légumes', 'Légumes'],
      price: 1800,
      stock: 60,
      imageUrl: 'https://picsum.photos/seed/tomates/400/300',
      unitType: UnitType.carton,
      isNew: true,
    ),
    Product(
      id: 9,
      name: 'Lait UHT 1L',
      categoryPath: ['Boissons', 'Lait'],
      price: 145,
      stock: 400,
      imageUrl: 'https://picsum.photos/seed/laituht/400/300',
      unitType: UnitType.piece,
    ),
    Product(
      id: 10,
      name: 'Riz parfumé 5kg',
      categoryPath: ['Épicerie', 'Riz & pâtes'],
      price: 890,
      stock: 90,
      imageUrl: 'https://picsum.photos/seed/riz5/400/300',
      unitType: UnitType.piece,
      isPromo: true,
    ),
    Product(
      id: 11,
      name: 'Papier hygiénique (pack)',
      categoryPath: ['Hygiène', 'Papier'],
      price: 320,
      stock: 200,
      imageUrl: 'https://picsum.photos/seed/papier/400/300',
      unitType: UnitType.carton,
    ),
    Product(
      id: 12,
      name: 'Haricots verts 400g',
      categoryPath: ['Conserve', 'Légumes'],
      price: 110,
      stock: 300,
      imageUrl: 'https://picsum.photos/seed/haricots/400/300',
      unitType: UnitType.piece,
    ),
  ];

  String _query = '';
  String _categoryFilter = 'Tous';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Product> get products {
    return _products.where((p) {
      final matchQuery = p.name.toLowerCase().contains(_query.toLowerCase());
      final matchCategory = _categoryFilter == 'Tous' ||
          p.categoryPath.any((c) => c == _categoryFilter);
      return matchQuery && matchCategory;
    }).toList();
  }

  List<Product> get promotions => _products.where((p) => p.isPromo).toList();

  List<String> get categories {
    final set = <String>{'Tous'};
    for (final p in _products) {
      set.addAll(p.categoryPath);
    }
    return set.toList();
  }

  /// Catégories principales (niveau 1), triées par nombre de produits décroissant.
  List<String> get mainCategories {
    final counts = <String, int>{};
    for (final p in _products) {
      final m = p.categoryPath.isNotEmpty ? p.categoryPath.first : 'Autres';
      counts[m] = (counts[m] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return keys;
  }

  int productCountInMain(String main) {
    return _products
        .where((p) => p.categoryPath.isNotEmpty && p.categoryPath.first == main)
        .length;
  }

  bool mainHasPromo(String main) {
    return _products.any(
      (p) =>
          p.isPromo &&
          p.categoryPath.isNotEmpty &&
          p.categoryPath.first == main,
    );
  }

  bool mainHasTopSeller(String main) {
    return _products.any(
      (p) =>
          p.isTopSeller &&
          p.categoryPath.isNotEmpty &&
          p.categoryPath.first == main,
    );
  }

  String? representativeImageForMain(String main) {
    for (final p in _products) {
      if (p.categoryPath.isNotEmpty &&
          p.categoryPath.first == main &&
          p.imageUrl.isNotEmpty) {
        return p.imageUrl;
      }
    }
    return null;
  }

  List<String> subcategoriesForMain(String main) {
    final subs = <String>{};
    for (final p in _products) {
      if (p.categoryPath.isEmpty || p.categoryPath.first != main) continue;
      if (p.categoryPath.length >= 2) {
        subs.add(p.categoryPath[1]);
      } else {
        subs.add('Autres');
      }
    }
    final list = subs.toList()..sort();
    return list;
  }

  List<Product> productsInMain(String main) {
    return _products
        .where((p) => p.categoryPath.isNotEmpty && p.categoryPath.first == main)
        .toList();
  }

  /// Regroupe les produits d’une catégorie principale par sous-catégorie (niveau 2).
  Map<String, List<Product>> productsBySubcategoryInMain(String main) {
    final map = <String, List<Product>>{};
    for (final p in productsInMain(main)) {
      final sub = p.categoryPath.length >= 2 ? p.categoryPath[1] : 'Autres';
      map.putIfAbsent(sub, () => []).add(p);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  SearchSuggestionBundle searchSuggestions(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) {
      return const SearchSuggestionBundle(
        categories: [],
        productPreviewIds: [],
      );
    }
    final cats = <String>{};
    for (final p in _products) {
      for (final c in p.categoryPath) {
        if (c.toLowerCase().contains(q)) cats.add(c);
      }
    }
    final mainHits = mainCategories.where((m) => m.toLowerCase().contains(q));
    cats.addAll(mainHits);

    final previewIds = <int>[];
    for (final p in _products) {
      if (p.name.toLowerCase().contains(q)) previewIds.add(p.id);
      if (previewIds.length >= 12) break;
    }
    final sortedCats = cats.toList()..sort();
    return SearchSuggestionBundle(
      categories: sortedCats.take(12).toList(),
      productPreviewIds: previewIds,
    );
  }

  /// Pour la recherche : si l’utilisateur tape un libellé de sous-catégorie, on ouvre le rayon principal.
  String? resolveMainForSearchSelection(String tapped) {
    if (tapped.isEmpty) return null;
    if (mainCategories.contains(tapped)) return tapped;
    for (final p in _products) {
      if (p.categoryPath.contains(tapped)) {
        return p.categoryPath.isNotEmpty ? p.categoryPath.first : null;
      }
    }
    return null;
  }

  List<Product> productsMatchingQuery(String raw, {int limit = 100}) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return [];
    final out = _products.where((p) {
      if (p.name.toLowerCase().contains(q)) return true;
      return p.categoryPath.any((c) => c.toLowerCase().contains(q));
    }).toList();
    out.sort((a, b) => a.name.compareTo(b.name));
    if (out.length > limit) return out.sublist(0, limit);
    return out;
  }

  List<Product> get frequentProducts => _products.take(2).toList();

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final remoteProducts = await _repository.fetchProducts();
      if (remoteProducts.isNotEmpty) {
        _products
          ..clear()
          ..addAll(remoteProducts);
      }
    } catch (_) {
      _errorMessage = 'Catalogue hors ligne, données locales affichées.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
