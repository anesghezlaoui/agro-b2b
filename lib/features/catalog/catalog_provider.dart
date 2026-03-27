import 'package:flutter/material.dart';

import '../../models/category_meta.dart';
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

  /// Catalogue chargé uniquement depuis l’API (aucun fallback mock).
  final List<Product> _products = [];
  List<CategoryMeta> _categoryMeta = [];

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

  int subcategoryCountInMain(String main) {
    final subs = <String>{};
    for (final p in _products) {
      if (p.categoryPath.isEmpty || p.categoryPath.first != main) continue;
      if (p.categoryPath.length >= 2) {
        subs.add(p.categoryPath[1]);
      }
    }
    return subs.length;
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

  /// Rayons racine renvoyés par l’API `/api/categories` (image + icône admin).
  CategoryMeta? metaForMainCategory(String main) {
    for (final c in _categoryMeta) {
      if (c.parentId == null && c.name == main) return c;
    }
    return null;
  }

  String? representativeImageForMain(String main) {
    final meta = metaForMainCategory(main);
    if (meta != null && !meta.showImage) return "";
    if (meta != null && meta.showImage && meta.imageUrl.isNotEmpty) {
      return meta.imageUrl;
    }
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
      var categories = <CategoryMeta>[];
      try {
        categories = await _repository.fetchCategories();
      } catch (_) {
        // Les catégories enrichissent l’UI ; le catalogue reste utilisable sans.
      }
      final remoteProducts = await _repository.fetchProducts();
      _categoryMeta = categories;
      _products
        ..clear()
        ..addAll(remoteProducts);
    } catch (_) {
      _products.clear();
      _categoryMeta = [];
      _errorMessage =
          'Impossible de charger le catalogue. Vérifiez la connexion et l’URL du serveur.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
