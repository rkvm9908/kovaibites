import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? 'Customer',
        rating: (m['rating'] ?? 0).toInt(),
        comment: m['comment'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}