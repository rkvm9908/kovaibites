import 'package:latlong2/latlong.dart';
import 'image_list.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final List<String> images;
  final double rating;
  final bool isOpen;
  final int deliveryMins;
  final int priceForTwo;
  final double? lat;
  final double? lng;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    this.images = const [],
    this.rating = 0,
    this.isOpen = true,
    this.deliveryMins = 30,
    this.priceForTwo = 300,
    this.lat,
    this.lng,
  });

  String get imageUrl => images.isEmpty ? '' : images.first;
  bool get hasLocation => lat != null && lng != null;
  LatLng? get latLng => hasLocation ? LatLng(lat!, lng!) : null;

  factory Restaurant.fromMap(String id, Map<String, dynamic> m) => Restaurant(
        id: id,
        name: m['name'] ?? '',
        cuisine: m['cuisine'] ?? '',
        images: imagesFromMap(m),
        rating: (m['rating'] ?? 0).toDouble(),
        isOpen: m['isOpen'] ?? true,
        deliveryMins: m['deliveryMins'] ?? 30,
        priceForTwo: m['priceForTwo'] ?? 300,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );
}