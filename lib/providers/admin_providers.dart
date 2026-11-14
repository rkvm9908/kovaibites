import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import '../models/delivery_application.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider((_) => AdminService());

/// Orders for one restaurant (family keyed by restaurant id).
final adminOrdersProvider = StreamProvider.family<List<AppOrder>, String>(
    (ref, rid) => ref.watch(adminServiceProvider).ordersFor(rid));

/// Latest orders across all restaurants (dashboard and orders tab).
final allOrdersProvider = StreamProvider<List<AppOrder>>(
    (ref) => ref.watch(adminServiceProvider).allOrders());

/// Approved delivery partners.
final partnersProvider = StreamProvider<List<DeliveryApplication>>(
    (ref) => ref.watch(adminServiceProvider).partners());

/// Delivered order count for a partner (server-side count aggregation).
final deliveredCountProvider =
    FutureProvider.family<int, String>((ref, uid) async {
  final s = await FirebaseFirestore.instance
      .collection('orders')
      .where('deliveryBoyId', isEqualTo: uid)
      .where('status', isEqualTo: 'delivered')
      .count()
      .get();
  return s.count ?? 0;
});

/// The restaurant selected in the admin Manage tab.
class SelectedRestaurant extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedRestaurantProvider =
    NotifierProvider<SelectedRestaurant, String?>(SelectedRestaurant.new);

/// Selected tab in the admin shell: 0 Dashboard, 1 Orders, 2 Menu,
/// 3 Partners, 4 Profile. Dashboard cards and notifications change it.
class AdminTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int i) => state = i;
}

final adminTabProvider = NotifierProvider<AdminTab, int>(AdminTab.new);

/// Filter used by the admin Orders tab: 'active', 'done', 'all',
/// or a single order status such as 'placed' or 'preparing'.
class AdminOrderFilter extends Notifier<String> {
  @override
  String build() => 'active';

  void select(String f) => state = f;
}

final adminOrderFilterProvider =
    NotifierProvider<AdminOrderFilter, String>(AdminOrderFilter.new);