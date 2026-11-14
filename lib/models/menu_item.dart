import 'image_list.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final bool isVeg;
  final bool available;

  const MenuItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.images = const [],
    this.category = 'Others',
    this.isVeg = true,
    this.available = true,
  });

  String get imageUrl => images.isEmpty ? '' : images.first;

  factory MenuItem.fromMap(String id, Map<String, dynamic> m) => MenuItem(
        id: id,
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        price: (m['price'] ?? 0).toDouble(),
        images: imagesFromMap(m),
        category: m['category'] ?? 'Others',
        isVeg: m['isVeg'] ?? true,
        available: m['available'] ?? true,
      );
}