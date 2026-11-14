import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final _col = FirebaseFirestore.instance.collection('onlineDelivery');

  Future<void> beat(String uid, String name) =>
      _col.doc(uid).set({'name': name, 'lastSeen': FieldValue.serverTimestamp()});

  Future<void> goOffline(String uid) => _col.doc(uid).delete();

  Stream<Map<String, DateTime>> stream() => _col.snapshots().map((s) => {
        for (final d in s.docs)
          d.id: (d.data()['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      });
}