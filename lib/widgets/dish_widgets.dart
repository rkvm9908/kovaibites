import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../providers/cart_providers.dart';
import 'add_button.dart';
import 'cart_actions.dart';
import 'food_image.dart';
import 'pressable.dart';
import 'veg_badge.dart';

/// Horizontal "Popular dishes" card.
class DishCardSmall extends StatelessWidget {
  final Restaurant r;
  final MenuItem item;
  final int index;

  const DishCardSmall(this.r, this.item, {super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Pressable(
      onTap: () => context.push('/restaurant/${r.id}'),
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: Brand.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  FoodImage(item.imageUrl),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6)),
                      child: VegBadge(isVeg: item.isVeg),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.outline)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('₹${item.price.toStringAsFixed(0)}',
                          style: t.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const Icon(Icons.star_rounded,
                          size: 14, color: Brand.star),
                      const SizedBox(width: 2),
                      Text(r.rating.toStringAsFixed(1),
                          style: t.textTheme.bodySmall),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (50 * index.clamp(0, 8)).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Search result: dish-first card with an inline ADD button.
class DishResultTile extends ConsumerWidget {
  final Restaurant r;
  final MenuItem item;
  final int index;

  const DishResultTile(this.r, this.item, {super.key, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final qty = ref.watch(cartProvider.select((c) => c.qtyOf(item.id)));
    final canOrder = r.isOpen && item.available;

    return Pressable(
      hoverScale: 1.01,
      onTap: () => context.push('/restaurant/${r.id}'),
      child: Container(
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: Brand.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VegBadge(isVeg: item.isVeg),
                  const SizedBox(height: Sp.xs),
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('₹${item.price.toStringAsFixed(0)}',
                      style: t.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Sp.xs),
                  Row(children: [
                    const Icon(Icons.storefront_outlined, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          '${r.name} · ${r.rating.toStringAsFixed(1)}★ · ${r.deliveryMins} min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall),
                    ),
                  ]),
                  if (item.description.isNotEmpty)
                    Text(item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.outline)),
                  if (!canOrder)
                    Text(!r.isOpen ? 'Restaurant closed' : 'Out of stock',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: Sp.md),
            Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox(
                    width: 96, height: 88, child: FoodImage(item.imageUrl)),
              ),
              const SizedBox(height: Sp.sm),
              AddButton(
                qty: qty,
                enabled: canOrder,
                onAdd: () => addToCart(context, ref, r, item),
                onIncrement: () =>
                    ref.read(cartProvider.notifier).increment(item.id),
                onRemove: () => ref.read(cartProvider.notifier).remove(item.id),
              ),
            ]),
          ],
        ),
      ),
    )
        .animate(delay: (40 * index.clamp(0, 8)).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}