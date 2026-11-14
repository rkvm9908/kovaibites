import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish.dart';

final restaurantServiceProvider = Provider((_) => RestaurantService());

final restaurantsProvider = StreamProvider<List<Restaurant>>(
    (ref) => ref.watch(restaurantServiceProvider).restaurants());

final restaurantProvider = StreamProvider.family<Restaurant?, String>(
    (ref, id) => ref.watch(restaurantServiceProvider).restaurant(id));

final menuProvider = StreamProvider.family<List<MenuItem>, String>(
    (ref, id) => ref.watch(restaurantServiceProvider).menu(id));

final allDishesProvider = FutureProvider<List<Dish>>((ref) async {
  final s = await FirebaseFirestore.instance.collectionGroup('menu').limit(300).get();
  return s.docs
      .map((d) => Dish(d.reference.parent.parent!.id, MenuItem.fromMap(d.id, d.data())))
      .toList();
});