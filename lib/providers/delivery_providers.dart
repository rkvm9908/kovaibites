import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import '../models/delivery_application.dart';
import '../services/delivery_service.dart';
import 'auth_providers.dart';

final deliveryServiceProvider = Provider((_) => DeliveryService());

final myApplicationProvider = StreamProvider<DeliveryApplication?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(deliveryServiceProvider).myApplication(user.uid);
});

final pendingApplicationsProvider = StreamProvider<List<DeliveryApplication>>(
    (ref) => ref.watch(deliveryServiceProvider).pending());

final availableOrdersProvider = StreamProvider<List<AppOrder>>(
    (ref) => ref.watch(deliveryServiceProvider).availableOrders());

final myDeliveriesProvider = StreamProvider<List<AppOrder>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(deliveryServiceProvider).myDeliveries(user.uid);
});