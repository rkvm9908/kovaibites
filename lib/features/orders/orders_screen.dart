import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/app_order.dart';
import '../../providers/order_providers.dart';
import '../../widgets/app_states.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'No orders yet',
              subtitle: 'Your first order is just a few taps away',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(Sp.md),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
                itemBuilder: (_, i) => _OrderCard(list[i], i),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder o;
  final int index;
  const _OrderCard(this.o, this.index);

  Color get _color => switch (o.status) {
        'delivered' => Brand.success,
        'cancelled' => Colors.red.shade700,
        _ => Brand.primary,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final d = o.createdAt;

    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: Brand.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(o.restaurantName,
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o.statusLabel,
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
          if (d != null)
            Text(
                '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.outline)),
          const SizedBox(height: Sp.sm),
          Text(o.items.map((i) => '${i['qty']} x ${i['name']}').join(', '),
              style: t.textTheme.bodyMedium),
          const SizedBox(height: Sp.md),

          if (o.status == 'cancelled')
            Container(
              padding: const EdgeInsets.all(Sp.md),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(children: [
                Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                const SizedBox(width: Sp.sm),
                Text('This order was cancelled',
                    style: TextStyle(color: Colors.red.shade800)),
              ]),
            )
          else
            _Tracker(o.status),

          if (o.deliveryBoyName.isNotEmpty &&
              o.status == 'out_for_delivery') ...[
            const SizedBox(height: Sp.md),
            Row(children: [
              const Icon(Icons.delivery_dining, color: Brand.primary),
              const SizedBox(width: Sp.sm),
              Text('${o.deliveryBoyName} is delivering your order',
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ],
          const Divider(height: Sp.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text('₹${o.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (70 * index.clamp(0, 6)).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Five-step delivery tracker with an animated progress line.
class _Tracker extends StatelessWidget {
  final String status;
  const _Tracker(this.status);

  static const _steps = [
    ('placed', Icons.receipt_long_outlined, 'Placed'),
    ('accepted', Icons.thumb_up_alt_outlined, 'Accepted'),
    ('preparing', Icons.restaurant, 'Cooking'),
    ('out_for_delivery', Icons.delivery_dining, 'On the way'),
    ('delivered', Icons.home_outlined, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexWhere((s) => s.$1 == status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _node(i, current),
          if (i < _steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: _connector(i < current),
              ),
            ),
        ],
      ],
    );
  }

  Widget _node(int i, int current) {
    final last = _steps.length - 1;
    final reached = i <= current;
    final isCurrent = i == current && i < last;
    final color = (i == last && reached) ? Brand.success : Brand.primary;

    return SizedBox(
      width: 52,
      child: Column(children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Pulsing ring on the step that is happening right now.
              if (isCurrent)
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1, end: 1.7, duration: 1200.ms)
                    .fade(begin: 0.45, end: 0, duration: 1200.ms),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? color : Colors.grey.shade200,
                ),
                child: Icon(_steps[i].$2,
                    size: 17,
                    color: reached ? Colors.white : Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(_steps[i].$3,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontWeight: reached ? FontWeight.w700 : FontWeight.w400,
                color: reached ? Brand.ink : Colors.grey)),
      ]),
    );
  }

  Widget _connector(bool filled) => Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: filled ? 1 : 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Brand.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
}