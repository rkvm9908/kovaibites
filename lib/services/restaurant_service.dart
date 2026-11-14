import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class RestaurantService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Restaurant>> restaurants() =>
      _db.collection('restaurants').snapshots().map((s) =>
          s.docs.map((d) => Restaurant.fromMap(d.id, d.data())).toList());

  Stream<Restaurant?> restaurant(String id) =>
      _db.collection('restaurants').doc(id).snapshots().map(
          (d) => d.exists ? Restaurant.fromMap(d.id, d.data()!) : null);

  Stream<List<MenuItem>> menu(String restaurantId) => _db
      .collection('restaurants')
      .doc(restaurantId)
      .collection('menu')
      .snapshots()
      .map((s) => s.docs.map((d) => MenuItem.fromMap(d.id, d.data())).toList());

  /// Dev only: sample data add panna
  Future<void> seedDemoData() async {
    final data = [
      {
        'name': 'Annapoorna Meals',
        'cuisine': 'South Indian · Meals',
        'rating': 4.5,
        'deliveryMins': 25,
        'priceForTwo': 250,
        'isOpen': true,
        'menu': [
          {'name': 'Full Meals', 'price': 120, 'category': 'Meals', 'isVeg': true, 'description': 'Rice, sambar, rasam, kootu, poriyal, curd, payasam'},
          {'name': 'Ghee Pongal', 'price': 70, 'category': 'Tiffin', 'isVeg': true, 'description': 'Creamy pongal with vadai and chutney'},
          {'name': 'Ghee Roast Dosa', 'price': 80, 'category': 'Tiffin', 'isVeg': true, 'description': 'Crispy dosa with sambar and 2 chutneys'},
        ],
      },
      {
        'name': 'Kongu Biriyani House',
        'cuisine': 'Biriyani · Kongu',
        'rating': 4.3,
        'deliveryMins': 35,
        'priceForTwo': 450,
        'isOpen': true,
        'menu': [
          {'name': 'Chicken Biriyani', 'price': 180, 'category': 'Biriyani', 'isVeg': false, 'description': 'Seeraga samba rice, chicken, raita'},
          {'name': 'Mutton Biriyani', 'price': 260, 'category': 'Biriyani', 'isVeg': false, 'description': 'Slow-cooked mutton, seeraga samba'},
          {'name': 'Chicken 65', 'price': 140, 'category': 'Starters', 'isVeg': false, 'description': 'Spicy deep-fried chicken'},
          {'name': 'Veg Biriyani', 'price': 130, 'category': 'Biriyani', 'isVeg': true, 'description': 'Mixed veg, raita'},
        ],
      },
      {
        'name': 'Sweet Kadai',
        'cuisine': 'Sweets · Snacks',
        'rating': 4.1,
        'deliveryMins': 20,
        'priceForTwo': 200,
        'isOpen': false,
        'menu': [
          {'name': 'Mysore Pak (250g)', 'price': 150, 'category': 'Sweets', 'isVeg': true, 'description': 'Ghee-rich traditional sweet'},
        ],
      },
    ];

    for (final r in data) {
      final menu = r.remove('menu') as List;
      final ref = await _db.collection('restaurants').add(r);
      for (final m in menu) {
        await ref.collection('menu').add({...(m as Map<String, dynamic>), 'available': true});
      }
    }
  }
}