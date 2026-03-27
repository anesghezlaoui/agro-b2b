/// Métadonnées rayon synchronisées avec l’admin Django (image + icône).
class CategoryMeta {
  CategoryMeta({
    required this.id,
    required this.name,
    this.parentId,
    required this.imageUrl,
    required this.iconUrl,
    this.showIcon = true,
    this.showImage = true,
  });

  final int id;
  final String name;
  final int? parentId;
  final String imageUrl;
  final String iconUrl;
  final bool showIcon;
  final bool showImage;

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    final pid = json['parent_id'];
    return CategoryMeta(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      parentId: pid == null ? null : _asInt(pid),
      imageUrl: (json['image'] ?? '').toString(),
      iconUrl: (json['icon'] ?? '').toString(),
      showIcon: (json['show_icon'] ?? json['showIcon'] ?? true) == true,
      showImage: (json['show_image'] ?? json['showImage'] ?? true) == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
