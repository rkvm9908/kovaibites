import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/order_providers.dart';
import '../providers/presence_providers.dart';

class AutoAcceptHost extends ConsumerStatefulWidget {
  final Widget child;
  const AutoAcceptHost({super.key, required this.child});
  @override
  ConsumerState<AutoAcceptHost> createState() => _State();
}

class _State extends ConsumerState<AutoAcceptHost> {
  Timer? _timer;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final online = ref.read(onlineDeliveryProvider).value ?? {};
    if (!online.values.any(isFresh)) return; // partner illa = manual accept

    final orders = (user.role == 'admin'
                ? ref.read(allOrdersProvider)
                : ref.read(myOrdersProvider))
            .value ??
        [];
    final now = DateTime.now();
    for (final o in orders) {
      if (o.status != 'placed' || o.createdAt == null) continue;
      // +2s buffer: server rule-la 60s mudiyaama accept aagaama irukka
      if (now.difference(o.createdAt!).inSeconds < autoAcceptSeconds + 2) continue;
      if (!_busy.add(o.id)) continue;
      try {
        final ok = await ref.read(orderServiceProvider).autoAccept(o.id);
        if (ok) {
          await ref.read(notificationServiceProvider).send(
                'admin',
                'Order auto-accepted',
                '${o.restaurantName} / ${o.userName} order was auto-accepted',
                route: '/admin?tab=orders',
            );
        }
      } catch (_) {
      } finally {
        _busy.remove(o.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // providers-a live-ah vechukka watch pannanum
    final user = ref.watch(currentUserProvider).value;
    if (user != null) {
      ref.watch(onlineDeliveryProvider);
      if (user.role == 'admin') {
        ref.watch(allOrdersProvider);
      } else {
        ref.watch(myOrdersProvider);
      }
    }
    return widget.child;
  }
}