import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool read;

  /// In-app route to open when the notification is tapped (may be empty).
  final String route;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    this.route = '',
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        read: m['read'] ?? false,
        route: m['route'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}