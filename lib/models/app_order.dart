import 'package:cloud_firestore/cloud_firestore.dart';

class AppOrder {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String userName;
  final String phone;
  final String note;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final String address;
  final double? lat;
  final double? lng;
  final String? deliveryBoyId;
  final String deliveryBoyName;
  final DateTime? createdAt;

  const AppOrder({
    required this.id,
    this.userId = '',
    this.restaurantId = '',
    required this.restaurantName,
    this.userName = '',
    this.phone = '',
    this.note = '',
    required this.items,
    required this.total,
    required this.status,
    required this.address,
    this.lat,
    this.lng,
    this.deliveryBoyId,
    this.deliveryBoyName = '',
    this.createdAt,
  });

  factory AppOrder.fromMap(String id, Map<String, dynamic> m) => AppOrder(
        id: id,
        userId: m['userId'] ?? '',
        restaurantId: m['restaurantId'] ?? '',
        restaurantName: m['restaurantName'] ?? '',
        userName: m['userName'] ?? '',
        phone: m['phone'] ?? '',
        note: m['note'] ?? '',
        items: List<Map<String, dynamic>>.from(
            (m['items'] ?? []).map((e) => Map<String, dynamic>.from(e))),
        total: (m['total'] ?? 0).toDouble(),
        status: m['status'] ?? 'placed',
        address: m['address'] ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        deliveryBoyId: m['deliveryBoyId'],
        deliveryBoyName: m['deliveryBoyName'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  static const statusLabels = {
    'placed': 'Order placed',
    'accepted': 'Accepted',
    'preparing': 'Preparing',
    'out_for_delivery': 'Out for delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  String get statusLabel => statusLabels[status] ?? status;
}