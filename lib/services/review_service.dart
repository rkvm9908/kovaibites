import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

typedef ItemKey = ({String rid, String itemId});

class ReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(ItemKey k) => _db
      .collection('restaurants')
      .doc(k.rid)
      .collection('menu')
      .doc(k.itemId)
      .collection('reviews');

  Stream<List<Review>> stream(ItemKey k) => _col(k).snapshots().map((s) {
        final list = s.docs.map((d) => Review.fromMap(d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  /// doc id = userId, so oru user-ku oru review (thirumba panna update)
  Future<void> submit(ItemKey k, String uid, String name, int rating, String comment) =>
      _col(k).doc(uid).set({
        'userId': uid,
        'userName': name,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(ItemKey k, String uid) => _col(k).doc(uid).delete();
}