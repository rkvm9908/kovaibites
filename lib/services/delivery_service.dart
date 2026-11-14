import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_order.dart';
import '../models/delivery_application.dart';
import 'notification_service.dart';

class DeliveryService {
  final _db = FirebaseFirestore.instance;
  final _notify = NotificationService();

  // ---------------------------------------------------------------------------
  // Applications
  // ---------------------------------------------------------------------------

  /// Streams the current user's application. Emits null if none exists.
  Stream<DeliveryApplication?> myApplication(String uid) => _db
      .collection('deliveryApplications')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? DeliveryApplication.fromMap(d.id, d.data()!) : null);

  /// Submits (or resubmits) an application and notifies the admin.
  /// The document id equals the user id, so each user has at most one.
  Future<void> apply(String uid, Map<String, dynamic> data) async {
    await _db.collection('deliveryApplications').doc(uid).set({
      ...data,
      'status': 'pending',
      'rejectReason': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _notify.send(
      'admin',
      'New delivery partner request',
      '${data['name']} has applied to become a delivery partner.',
      route: '/admin/delivery-requests',
    );
  }

  /// Streams all applications waiting for admin review.
  Stream<List<DeliveryApplication>> pending() => _db
      .collection('deliveryApplications')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DeliveryApplication.fromMap(d.id, d.data())).toList());

  /// Approves an application and grants delivery access (atomic batch).
  Future<void> approve(DeliveryApplication a) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('deliveryApplications').doc(a.uid),
      {'status': 'approved', 'rejectReason': ''},
    );
    batch.update(_db.collection('users').doc(a.uid), {'isDelivery': true});
    await batch.commit();

    await _notify.send(
      a.uid,
      'Application approved',
      'You are now a Kovai Bites delivery partner. Tap to open your dashboard.',
      route: '/delivery',
    );
  }

  /// Rejects an application and sends the reason to the applicant.
  Future<void> reject(DeliveryApplication a, String reason) async {
    await _db
        .collection('deliveryApplications')
        .doc(a.uid)
        .update({'status': 'rejected', 'rejectReason': reason});
    await _notify.send(
      a.uid,
      'Application rejected',
      'Reason: $reason',
      route: '/delivery/apply',
    );
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  /// Streams accepted/preparing orders that have no delivery partner yet.
  /// Status filtering is done on the client to avoid a composite index.
  Stream<List<AppOrder>> availableOrders() => _db
          .collection('orders')
          .where('deliveryBoyId', isNull: true)
          .snapshots()
          .map((s) {
        const eligible = ['accepted', 'preparing'];
        final list = s.docs
            .map((d) => AppOrder.fromMap(d.id, d.data()))
            .where((o) => eligible.contains(o.status))
            .toList();
        // Oldest orders first
        list.sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));
        return list;
      });

  /// Streams the orders assigned to this partner (active ones first).
  Stream<List<AppOrder>> myDeliveries(String uid) => _db
          .collection('orders')
          .where('deliveryBoyId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final list = s.docs.map((d) => AppOrder.fromMap(d.id, d.data())).toList();
        const finished = ['delivered', 'cancelled'];
        list.sort((a, b) {
          final aDone = finished.contains(a.status);
          final bDone = finished.contains(b.status);
          if (aDone != bDone) return aDone ? 1 : -1;
          return (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now());
        });
        return list;
      });

  /// Assigns an order to a partner. A transaction prevents two partners
  /// from claiming the same order at the same time.
  Future<void> claim(String orderId, String uid, String name) =>
      _db.runTransaction((tx) async {
        final ref = _db.collection('orders').doc(orderId);
        final snap = await tx.get(ref);
        if (snap.data()?['deliveryBoyId'] != null) {
          throw Exception('This order has already been taken by another partner.');
        }
        tx.update(ref, {'deliveryBoyId': uid, 'deliveryBoyName': name});
      });

  /// Updates the delivery status and notifies the customer.
  Future<void> setStatus(AppOrder o, String status) async {
    await _db.collection('orders').doc(o.id).update({'status': status});
    final message = status == 'out_for_delivery'
        ? 'Your order is on the way.'
        : 'Your order has been delivered. Enjoy your meal!';
    await _notify.send(o.userId, 'Order update', message, route: '/orders');
  }
}