import 'package:flutter/material.dart';

/// Couleurs et icônes marketing par catégorie principale (fallback déterministe).
class CategoryVisuals {
  static const Map<String, (Color bg, Color accent, IconData icon)> _presets = {
    'Alimentaire': (Color(0xFFE8F5E9), Color(0xFF2E7D32), Icons.restaurant_rounded),
    'Fruits & Légumes': (Color(0xFFF1F8E9), Color(0xFF558B2F), Icons.eco_rounded),
    'Boissons': (Color(0xFFE3F2FD), Color(0xFF1565C0), Icons.local_drink_rounded),
    'Épicerie': (Color(0xFFFFF8E1), Color(0xFFF9A825), Icons.breakfast_dining_rounded),
    'Conserve': (Color(0xFFFFEBEE), Color(0xFFC62828), Icons.inventory_2_rounded),
    'Hygiène': (Color(0xFFF3E5F5), Color(0xFF6A1B9A), Icons.clean_hands_rounded),
  };

  static (Color bg, Color accent, IconData icon) forName(String name) {
    final hit = _presets[name];
    if (hit != null) return hit;
    final h = name.hashCode.abs();
    final accents = [
      const Color(0xFF1B8F4B),
      const Color(0xFF0D47A1),
      const Color(0xFFBF360C),
      const Color(0xFF4A148C),
    ];
    final bgs = [
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5),
    ];
    return (bgs[h % bgs.length], accents[h % accents.length], Icons.category_rounded);
  }
}
