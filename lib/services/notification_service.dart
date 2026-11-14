import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  /// [toUid] is a user id, or 'admin' for every admin.
  /// [route] is the in-app page to open when the notification is tapped.
  Future<void> send(
    String toUid,
    String title,
    String body, {
    String route = '',
  }) =>
      _db.collection('notifications').add({
        'toUid': toUid,
        'title': title,
        'body': body,
        'route': route,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Streams a user's notifications, newest first (sorted on the client).
  Stream<List<AppNotification>> stream(String toUid) => _db
          .collection('notifications')
          .where('toUid', isEqualTo: toUid)
          .snapshots()
          .map((s) {
        final list =
            s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'read': true});
}