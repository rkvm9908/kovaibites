import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design.dart';
import '../models/cart.dart';
import '../providers/cart_providers.dart';
import 'pressable.dart';

/// Bottom cart summary that slides up when the cart has items.
class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: cart.isEmpty
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : _Bar(key: const ValueKey('bar'), cart: cart),
    );
  }
}

class _Bar extends StatelessWidget {
  final CartState cart;
  const _Bar({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Pressable(
              hoverScale: 1.01,
              onTap: () => context.push('/cart'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Sp.md, vertical: Sp.md - 2),
                decoration: BoxDecoration(
                  gradient: Brand.gradient,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  boxShadow: [
                    BoxShadow(
                        color: Brand.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Text('${cart.count}',
                            key: ValueKey(cart.count),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cart.restaurantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                              '₹${cart.subtotal.toStringAsFixed(0)}  ·  ${cart.count} item${cart.count > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Text('View cart',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}