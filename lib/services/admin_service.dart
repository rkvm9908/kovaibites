import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_order.dart';
import '../models/delivery_application.dart';
import 'notification_service.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;
  final _notify = NotificationService();

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  /// Customer-facing message sent for each status change.
  static const _statusMsg = {
    'accepted': 'Your order has been accepted by the restaurant.',
    'preparing': 'Your meal is being prepared.',
    'out_for_delivery': 'Your order is on its way to you.',
    'delivered': 'Your order has been delivered. Enjoy your meal!',
    'cancelled': 'We are sorry, your order has been cancelled.',
  };

  /// Updates the order status and notifies the customer.
  Future<void> setStatus(AppOrder o, String status) async {
    await _db.collection('orders').doc(o.id).update({'status': status});
    final message = _statusMsg[status];
    if (message != null && o.userId.isNotEmpty) {
      await _notify.send(o.userId, 'Order update', message, route: '/orders');
    }
  }

  /// Streams the latest 200 orders across all restaurants (newest first).
  Stream<List<AppOrder>> allOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map((d) => AppOrder.fromMap(d.id, d.data())).toList());

  /// Streams orders for one restaurant (sorted on the client, no index needed).
  Stream<List<AppOrder>> ordersFor(String restaurantId) => _db
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots()
          .map((s) {
        final list =
            s.docs.map((d) => AppOrder.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  // ---------------------------------------------------------------------------
  // Delivery partners
  // ---------------------------------------------------------------------------

  /// Streams all approved delivery partners.
  Stream<List<DeliveryApplication>> partners() => _db
      .collection('deliveryApplications')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((s) => s.docs
          .map((d) => DeliveryApplication.fromMap(d.id, d.data()))
          .toList());

  /// Updates a partner's details and notifies them.
  Future<void> updatePartner(String uid, Map<String, dynamic> data) async {
    await _db.collection('deliveryApplications').doc(uid).update(data);
    await _notify.send(
      uid,
      'Profile updated',
      'An admin has updated your delivery partner details.',
      route: '/delivery',
    );
  }

  /// Revokes delivery access in one batch: the user flag, the application
  /// status and the online presence record.
  Future<void> removePartner(String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {'isDelivery': false});
    batch.update(_db.collection('deliveryApplications').doc(uid), {
      'status': 'rejected',
      'rejectReason': 'Delivery access was removed by an admin.',
    });
    batch.delete(_db.collection('onlineDelivery').doc(uid));
    await batch.commit();

    await _notify.send(
      uid,
      'Delivery access removed',
      'Please contact the admin for more details.',
      route: '/settings',
    );
  }

  // ---------------------------------------------------------------------------
  // Restaurants and menu
  // ---------------------------------------------------------------------------

  Future<void> setRestaurantOpen(String id, bool open) =>
      _db.collection('restaurants').doc(id).update({'isOpen': open});

  /// Creates a restaurant when [id] is null, otherwise updates it.
  Future<void> saveRestaurant(String? id, Map<String, dynamic> data) {
    final col = _db.collection('restaurants');
    return id == null
        ? col.add({...data, 'isOpen': true})
        : col.doc(id).update(data);
  }

  /// Creates a menu item when [itemId] is null, otherwise updates it.
  Future<void> saveMenuItem(
      String restaurantId, String? itemId, Map<String, dynamic> data) {
    final col =
        _db.collection('restaurants').doc(restaurantId).collection('menu');
    return itemId == null ? col.add(data) : col.doc(itemId).update(data);
  }

  Future<void> setItemAvailable(String restaurantId, String itemId, bool v) =>
      _db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .update({'available': v});

  Future<void> deleteMenuItem(String restaurantId, String itemId) => _db
      .collection('restaurants')
      .doc(restaurantId)
      .collection('menu')
      .doc(itemId)
      .delete();
}