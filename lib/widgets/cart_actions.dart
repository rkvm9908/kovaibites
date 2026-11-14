import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../providers/cart_providers.dart';

Future<void> addToCart(
    BuildContext context, WidgetRef ref, Restaurant r, MenuItem item) async {
  final cart = ref.read(cartProvider.notifier);
  if (!cart.canAdd(r.id)) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace cart?'),
        content: const Text('Cart-la vera restaurant items irukku. Clear panni add panna?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
        ],
      ),
    );
    if (ok != true) return;
    cart.clear();
  }
  cart.add(r, item);
}