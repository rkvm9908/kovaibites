import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_order.dart';
import '../models/cart.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<String> placeOrder({
    required String userId,
    required String userName,
    required CartState cart,
    required String address,
    required String phone,
    String note = '',
    double? lat,
    double? lng,
  }) async {
    final doc = await _db.collection('orders').add({
      'userId': userId,
      'userName': userName,
      'restaurantId': cart.restaurantId,
      'restaurantName': cart.restaurantName,
      'items': cart.lines.values
          .map((l) => {
                'itemId': l.item.id,
                'name': l.item.name,
                'price': l.item.price,
                'qty': l.qty,
              })
          .toList(),
      'subtotal': cart.subtotal,
      'deliveryFee': CartState.deliveryFee,
      'total': cart.total,
      'status': 'placed',
      'paymentMethod': 'cod',
      'paymentStatus': 'pending',
      'address': address,
      'lat': lat,
      'lng': lng,
      'deliveryBoyId': null,
      'deliveryBoyName': '',
      'phone': phone,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

/// true = naama accept pannom (race-ah avoid panna transaction)
    Future<bool> autoAccept(String orderId) => _db.runTransaction((tx) async {
        final ref = _db.collection('orders').doc(orderId);
        final s = await tx.get(ref);
        if (s.data()?['status'] != 'placed') return false;
        tx.update(ref, {'status': 'accepted', 'autoAccepted': true});
        return true;
        });

  /// Composite index avoid panna, sorting client-side
  Stream<List<AppOrder>> userOrders(String uid) => _db
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final list =
            s.docs.map((d) => AppOrder.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });
}