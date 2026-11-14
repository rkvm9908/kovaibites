import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import '../services/order_service.dart';
import 'auth_providers.dart';

final orderServiceProvider = Provider((_) => OrderService());

final myOrdersProvider = StreamProvider<List<AppOrder>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(orderServiceProvider).userOrders(user.uid);
});