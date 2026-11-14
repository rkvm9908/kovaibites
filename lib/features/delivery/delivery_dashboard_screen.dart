import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design.dart';
import '../../models/app_order.dart';
import '../../providers/auth_providers.dart';
import '../../providers/delivery_providers.dart';
import '../../providers/restaurant_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/online_toggle_bar.dart';
import '../../widgets/ui_kit.dart';

class DeliveryDashboardScreen extends ConsumerWidget {
  const DeliveryDashboardScreen({super.key});

  Widget _tab(String label, int count) => Tab(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: Brand.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableOrdersProvider).value?.length ?? 0;
    final mine = ref.watch(myDeliveriesProvider).value ?? [];
    final active = mine
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delivery'),
          actions: [
            const NotificationBell(),
            IconButton(
              tooltip: 'Customer app',
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.go('/'),
            ),
          ],
          bottom: TabBar(tabs: [
            _tab('Available', available),
            _tab('My deliveries', active),
          ]),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(children: [
              const OnlineToggleBar(),
              _TodayStrip(mine),
              const Expanded(
                child: TabBarView(children: [
                  _OrderList(mine: false),
                  _OrderList(mine: true),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Today's delivered count and cash to hand over.
class _TodayStrip extends StatelessWidget {
  final List<AppOrder> mine;
  const _TodayStrip(this.mine);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final done = mine.where((o) =>
        o.status == 'delivered' &&
        o.createdAt != null &&
        o.createdAt!.isAfter(start));
    final cash = done.fold<double>(0, (s, o) => s + o.total);

    Widget stat(IconData i, Color c, Widget value, String label) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(Sp.md - 4),
            child: Row(children: [
              IconBadge(i, color: c, size: 36),
              const SizedBox(width: Sp.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  value,
                  Text(label, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ]),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md),
      child: Row(children: [
        stat(
            Icons.check_circle_outline,
            Brand.success,
            CountUp(done.length,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            'Delivered today'),
        const SizedBox(width: Sp.sm),
        stat(
            Icons.payments_outlined,
            Brand.primary,
            CountUp(cash,
                prefix: '₹',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            'Cash collected'),
      ]),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final bool mine;
  const _OrderList({required this.mine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders =
        ref.watch(mine ? myDeliveriesProvider : availableOrdersProvider);

    return orders.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(e),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.delivery_dining,
            title: mine ? 'No deliveries yet' : 'No orders available',
            subtitle: mine ? '' : 'Orders accepted by the restaurant show up here live',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Sp.md),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (_, i) => _DeliveryCard(list[i], mine: mine),
        );
      },
    );
  }
}

class _DeliveryCard extends ConsumerWidget {
  final AppOrder o;
  final bool mine;
  const _DeliveryCard(this.o, {required this.mine});

  Future<void> _run(BuildContext context, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final svc = ref.read(deliveryServiceProvider);
    final user = ref.watch(currentUserProvider).value;
    final rest = ref.watch(restaurantProvider(o.restaurantId)).value;

    final custLoc =
        (o.lat != null && o.lng != null) ? LatLng(o.lat!, o.lng!) : null;
    final restLoc = rest?.latLng;
    final km = (custLoc != null && restLoc != null)
        ? Distance(roundResult: false).as(LengthUnit.Kilometer, restLoc, custLoc)
        : null;

    // The single main action for the current state.
    Widget? action;
    if (!mine) {
      action = GradientButton(
        label: 'Accept delivery',
        icon: Icons.check_rounded,
        onPressed: user == null
            ? null
            : () => _run(context, () => svc.claim(o.id, user.uid, user.name)),
      );
    } else if (o.status == 'accepted' || o.status == 'preparing') {
      action = GradientButton(
        label: 'Picked up',
        icon: Icons.shopping_bag_outlined,
        onPressed: () =>
            _run(context, () => svc.setStatus(o, 'out_for_delivery')),
      );
    } else if (o.status == 'out_for_delivery') {
      action = GradientButton(
        label: 'Mark delivered',
        icon: Icons.done_all_rounded,
        onPressed: () => _run(context, () => svc.setStatus(o, 'delivered')),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(o.restaurantName,
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            StatusChip(o.statusLabel, statusColor(o.status)),
          ]),
          const SizedBox(height: 2),
          Text(o.items.map((i) => '${i['qty']} x ${i['name']}').join(', '),
              style: t.textTheme.bodySmall
                  ?.copyWith(color: t.colorScheme.outline)),
          const SizedBox(height: Sp.md),

          // Pickup to drop-off route
          _Route(
            pickup: o.restaurantName,
            drop: o.address,
            customer: o.userName,
            km: km,
          ),

          if (mine && o.phone.isNotEmpty) ...[
            const SizedBox(height: Sp.sm),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 16),
              const SizedBox(width: 6),
              SelectableText(o.phone),
            ]),
          ],
          const SizedBox(height: Sp.sm),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            if (restLoc != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('To restaurant'),
                onPressed: () => openDirections(restLoc),
              ),
            if (custLoc != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('To customer'),
                onPressed: () => openDirections(custLoc),
              ),
            if (mine && o.phone.isNotEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Call'),
                onPressed: () => launchUrl(Uri.parse('tel:${o.phone}')),
              ),
          ]),
          const SizedBox(height: Sp.md),
          Container(
            padding: const EdgeInsets.all(Sp.md - 4),
            decoration: BoxDecoration(
              color: Brand.cream,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(children: [
              const Icon(Icons.payments_outlined, size: 18),
              const SizedBox(width: Sp.sm),
              const Expanded(child: Text('Collect (Cash on Delivery)')),
              Text('₹${o.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
          if (action != null) ...[
            const SizedBox(height: Sp.md),
            action,
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Two-stop timeline: restaurant (pickup) to customer (drop-off).
class _Route extends StatelessWidget {
  final String pickup;
  final String drop;
  final String customer;
  final double? km;
  const _Route({
    required this.pickup,
    required this.drop,
    required this.customer,
    this.km,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          const Icon(Icons.circle, size: 14, color: Brand.primary),
          Container(width: 2, height: 38, color: Colors.grey.shade300),
          const Icon(Icons.location_on, size: 18, color: Colors.red),
        ]),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PICKUP', style: muted),
              Text(pickup, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: Sp.md),
              Text('DROP${customer.isEmpty ? '' : '  ·  $customer'}',
                  style: muted),
              Text(drop, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (km != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${km!.toStringAsFixed(1)} km',
                style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
      ],
    );
  }
}