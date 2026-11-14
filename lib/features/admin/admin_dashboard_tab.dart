import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/app_order.dart';
import '../../providers/admin_providers.dart';
import '../../providers/presence_providers.dart';
import '../../providers/restaurant_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ui_kit.dart';
import 'admin_order_card.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    final partners = ref.watch(partnersProvider).value ?? [];
    final online = ref.watch(onlineDeliveryProvider).value ?? {};
    final restCount = ref.watch(restaurantsProvider).value?.length ?? 0;
    final onlineCount = online.values.where(isFresh).length;

    /// Switches the admin tab (0 Dashboard, 1 Orders, 2 Menu, 3 Partners),
    /// optionally pre-selecting an order filter.
    void goTab(int tab, {String? filter}) {
      if (filter != null) {
        ref.read(adminOrderFilterProvider.notifier).select(filter);
      }
      ref.read(adminTabProvider.notifier).select(tab);
    }

    return orders.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(e),
      data: (list) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final today = list
            .where((o) => o.createdAt != null && o.createdAt!.isAfter(start))
            .toList();
        final delivered = today.where((o) => o.status == 'delivered').toList();
        final cancelled = today.where((o) => o.status == 'cancelled').length;
        final revenue = delivered.fold<double>(0, (s, o) => s + o.total);
        final pending = list.where((o) => o.status == 'placed').length;
        final active = list
            .where((o) => ['accepted', 'preparing', 'out_for_delivery']
                .contains(o.status))
            .length;

        final counts = <String, int>{
          for (final s in AppOrder.statusLabels.keys)
            s: list.where((o) => o.status == s).length,
        };
        final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

        final stats = <_StatData>[
          _StatData(Icons.hourglass_top, 'New orders', pending, Colors.orange,
              onTap: () => goTab(1, filter: 'placed')),
          _StatData(Icons.local_fire_department, 'In progress', active,
              Colors.deepOrange,
              onTap: () => goTab(1, filter: 'active')),
          _StatData(Icons.two_wheeler, 'Partners online', onlineCount,
              Colors.indigo,
              suffix: ' / ${partners.length}', onTap: () => goTab(3)),
          _StatData(Icons.storefront, 'Restaurants', restCount, Colors.purple,
              onTap: () => goTab(2)),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(Sp.md),
              children: [
                _Hero(
                  revenue: revenue,
                  orders: today.length,
                  delivered: delivered.length,
                  cancelled: cancelled,
                  onTap: () => goTab(1, filter: 'delivered'),
                ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: Sp.md),
                if (pending > 0 && onlineCount == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.md),
                    child: AppCard(
                      color: Colors.orange.shade50,
                      onTap: () => goTab(1, filter: 'placed'),
                      child: const Row(children: [
                        IconBadge(Icons.warning_amber_rounded,
                            color: Colors.orange),
                        SizedBox(width: Sp.md),
                        Expanded(
                          child: Text(
                              'Orders are waiting but no delivery partner is online. '
                              'Auto-accept is paused. Tap to accept orders manually.'),
                        ),
                        Icon(Icons.chevron_right),
                      ]),
                    ),
                  ),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth >= 700 ? 4 : 2;
                  final w = (c.maxWidth - Sp.md * (cols - 1)) / cols;
                  return Wrap(
                    spacing: Sp.md,
                    runSpacing: Sp.md,
                    children: [
                      for (var i = 0; i < stats.length; i++)
                        SizedBox(
                          width: w,
                          child: _StatCard(stats[i])
                              .animate(delay: (80 * i).ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.15, end: 0),
                        ),
                    ],
                  );
                }),
                const SectionTitle('Orders by status'),
                AppCard(
                  child: Column(children: [
                    for (final s in AppOrder.statusLabels.keys)
                      _StatusBar(
                        label: AppOrder.statusLabels[s]!,
                        count: counts[s] ?? 0,
                        max: maxCount,
                        color: statusColor(s),
                        onTap: () => goTab(1, filter: s),
                      ),
                  ]),
                ),
                SectionTitle(
                  'Recent orders',
                  trailing: TextButton(
                    onPressed: () => goTab(1, filter: 'all'),
                    child: const Text('View all'),
                  ),
                ),
                if (list.isEmpty)
                  const EmptyState(
                      icon: Icons.inbox_outlined, title: 'No orders yet')
                else
                  for (final o in list.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.sm),
                      child: AppCard(
                        // Opens a live detail sheet with the action buttons.
                        onTap: () => showAdminOrderSheet(context, o.id),
                        child: Row(children: [
                          IconBadge(Icons.receipt_long,
                              color: statusColor(o.status)),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${o.restaurantName}  ·  ${o.userName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    o.items
                                        .map((i) => '${i['qty']} x ${i['name']}')
                                        .join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline)),
                              ],
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${o.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              StatusChip(o.statusLabel, statusColor(o.status)),
                            ],
                          ),
                        ]),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gradient summary card for today's numbers. Opens delivered orders.
class _Hero extends StatelessWidget {
  final double revenue;
  final int orders, delivered, cancelled;
  final VoidCallback onTap;

  const _Hero({
    required this.revenue,
    required this.orders,
    required this.delivered,
    required this.cancelled,
    required this.onTap,
  });

  Widget _mini(String label, int v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CountUp(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Pressable(
      hoverScale: 1.01,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(Radii.xl),
          boxShadow: [
            BoxShadow(
                color: Brand.primary.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's revenue",
                style: TextStyle(color: Colors.white70)),
            CountUp(revenue,
                prefix: '₹',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 38)),
            const SizedBox(height: Sp.md),
            Row(children: [
              _mini('Orders', orders),
              _mini('Delivered', delivered),
              _mini('Cancelled', cancelled),
            ]),
            const SizedBox(height: Sp.sm),
            const Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View delivered orders',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Icon(Icons.chevron_right, color: Colors.white70, size: 16),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String suffix;
  final VoidCallback onTap;

  const _StatData(this.icon, this.label, this.value, this.color,
      {this.suffix = '', required this.onTap});
}

class _StatCard extends StatelessWidget {
  final _StatData d;
  const _StatCard(this.d);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: d.onTap,
      child: Row(children: [
        IconBadge(d.icon, color: d.color),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CountUp(d.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                if (d.suffix.isNotEmpty)
                  Text(d.suffix, style: Theme.of(context).textTheme.bodySmall),
              ]),
              Text(d.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
      ]),
    );
  }
}

/// Horizontal bar showing a status count. Tap to list those orders.
class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;
  final VoidCallback onTap;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.max,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: max == 0 ? 0 : count / max),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
        ]),
      ),
    );
  }
}