import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/cart.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/qty_stepper.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/veg_badge.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final lines = cart.lines.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton.icon(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(Sp.md),
                  children: [
                    // Restaurant header
                    AppCard(
                      child: Row(children: [
                        const IconBadge(Icons.storefront_rounded),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ordering from',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                              Text(cart.restaurantName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: Sp.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
                      child: Text('Swipe an item left to remove it',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline)),
                    ),
                    for (var i = 0; i < lines.length; i++)
                      _LineTile(lines[i], i),
                    const SectionTitle('Bill details'),
                    _Bill(cart)
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: Sp.md),
                    Row(children: [
                      Icon(Icons.payments_outlined,
                          size: 18, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 6),
                      Text('Pay with cash when your order arrives',
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Row(children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('To pay',
                                style: Theme.of(context).textTheme.bodySmall),
                            CountUp(cart.total,
                                prefix: '₹',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(width: Sp.lg),
                        Expanded(
                          child: GradientButton(
                            label: 'Checkout',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => context.push('/checkout'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 72)).animate().scaleXY(
                begin: 0.4, end: 1, duration: 700.ms, curve: Curves.elasticOut),
            const SizedBox(height: Sp.md),
            Text('Your cart is empty',
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.xs),
            Text('Add something tasty from a restaurant',
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.outline)),
            const SizedBox(height: Sp.lg),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse restaurants'),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

/// One cart row. Swipe left to remove the whole line.
class _LineTile extends ConsumerWidget {
  final CartLine line;
  final int index;
  const _LineTile(this.line, this.index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final notifier = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Dismissible(
        key: ValueKey(line.item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) {
          for (var k = 0; k < line.qty; k++) {
            notifier.remove(line.item.id);
          }
        },
        child: AppCard(
          child: Row(children: [
            VegBadge(isVeg: line.item.isVeg),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('₹${line.item.price.toStringAsFixed(0)} each',
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.outline)),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            QtyStepper(
              width: 92,
              qty: line.qty,
              onAdd: () => notifier.increment(line.item.id),
              onRemove: () => notifier.remove(line.item.id),
            ),
            SizedBox(
              width: 64,
              child: Text('₹${(line.item.price * line.qty).toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    )
        .animate(delay: (50 * index.clamp(0, 8)).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Bill extends StatelessWidget {
  final CartState cart;
  const _Bill(this.cart);

  Widget _row(String label, double amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('₹${amount.toStringAsFixed(0)}')],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        _row('Item total', cart.subtotal),
        _row('Delivery fee', CartState.deliveryFee),
        const Divider(height: Sp.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('To pay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            CountUp(cart.total,
                prefix: '₹',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ]),
    );
  }
}