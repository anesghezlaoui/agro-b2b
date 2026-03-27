enum UnitType { piece, carton }

class ConditionnementOption {
  ConditionnementOption({
    required this.id,
    required this.type,
    required this.unite,
    required this.prix,
    this.stock = 0,
    this.isDefault = false,
    this.ordre = 0,
  });

  final int id;
  final String type;
  final int unite;
  final double prix;
  final int stock;
  final bool isDefault;
  final int ordre;

  double get prixUnitaire => unite <= 0 ? 0 : prix / unite;

  String get label => '$type ($unite pcs)';

  factory ConditionnementOption.fromJson(Map<String, dynamic> json) {
    return ConditionnementOption(
      id: _asInt(json['id']),
      type: (json['type'] ?? '').toString(),
      unite: _asInt(json['unite'] ?? json['unite_par_conditionnement']),
      prix: _asDouble(json['prix']),
      stock: _asInt(json['stock']),
      isDefault: (json['is_default'] ?? false) == true,
      ordre: _asInt(json['ordre']),
    );
  }
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.categoryPath,
    required this.price,
    required this.stock,
    required this.imageUrl,
    this.unitType = UnitType.piece,
    this.isPromo = false,
    this.isTopSeller = false,
    this.isNew = false,
    this.variantLabel,
    this.showConditionnement = true,
    this.conditionnements = const [],
  });

  final int id;
  final String name;
  final List<String> categoryPath;
  final double price;
  final int stock;
  final String imageUrl;
  final UnitType unitType;
  final bool isPromo;
  final bool isTopSeller;
  final bool isNew;
  final String? variantLabel;
  final bool showConditionnement;
  final List<ConditionnementOption> conditionnements;

  ConditionnementOption? get defaultConditionnement {
    for (final c in conditionnements) {
      if (c.isDefault) return c;
    }
    return conditionnements.isNotEmpty ? conditionnements.first : null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final unitRaw =
        (json['unite'] ?? json['unit'] ?? 'piece').toString().toLowerCase();
    final parsedConditionnements = ((json['conditionnements'] ?? []) as List)
        .whereType<Map<String, dynamic>>()
        .map(ConditionnementOption.fromJson)
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    return Product(
      id: _asInt(json['id']),
      name: (json['nom'] ?? json['name'] ?? '').toString(),
      categoryPath: _parseCategoryPath(json),
      price: _asDouble(json['prix'] ?? json['price']),
      stock: _asInt(json['stock']),
      imageUrl: (json['image'] ?? json['image_url'] ?? '').toString(),
      unitType: unitRaw == 'carton' ? UnitType.carton : UnitType.piece,
      isPromo: (json['is_promo'] ?? json['isPromo'] ?? false) == true,
      isTopSeller:
          (json['is_top_seller'] ?? json['isTopSeller'] ?? false) == true,
      isNew: (json['is_new'] ?? json['isNew'] ?? false) == true,
      variantLabel: (json['variante'] ?? json['variant_label'])?.toString(),
      showConditionnement: (json['show_conditionnement'] ??
              json['showConditionnement'] ??
              true) ==
          true,
      conditionnements: parsedConditionnements,
    );
  }

  static List<String> _parseCategoryPath(Map<String, dynamic> json) {
    final direct = json['category_path'];
    if (direct is List) {
      return direct.map((e) => e.toString()).toList();
    }
    final cat = json['categorie'] ?? json['category'];
    if (cat is Map<String, dynamic>) {
      final parent = (cat['parent_name'] ?? cat['parent'])?.toString();
      final name = (cat['nom'] ?? cat['name'])?.toString();
      return [
        if (parent != null && parent.isNotEmpty) parent,
        if (name != null) name
      ];
    }
    final value = cat?.toString();
    return [if (value != null && value.isNotEmpty) value];
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
