import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider((_) => ReviewService());

final reviewsProvider = StreamProvider.family<List<Review>, ItemKey>(
    (ref, k) => ref.watch(reviewServiceProvider).stream(k));