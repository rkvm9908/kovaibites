import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  bool canAdd(String restaurantId) =>
      state.isEmpty || state.restaurantId == restaurantId;

  void add(Restaurant r, MenuItem item) {
    if (!canAdd(r.id)) return;
    final lines = {...state.lines};
    lines[item.id] = CartLine(item, state.qtyOf(item.id) + 1);
    state = state.copyWith(r, lines);
  }

  void remove(String itemId) {
    final cur = state.lines[itemId];
    if (cur == null) return;
    final lines = {...state.lines};
    if (cur.qty <= 1) {
      lines.remove(itemId);
    } else {
      lines[itemId] = CartLine(cur.item, cur.qty - 1);
    }
    state = lines.isEmpty
        ? const CartState()
        : CartState(
            restaurantId: state.restaurantId,
            restaurantName: state.restaurantName,
            lines: lines,
          );
  }

  void increment(String itemId) {
    final cur = state.lines[itemId];
    if (cur == null) return;
    final lines = {...state.lines};
    lines[itemId] = CartLine(cur.item, cur.qty + 1);
    state = CartState(
        restaurantId: state.restaurantId,
        restaurantName: state.restaurantName,
        lines: lines,
    );
    }

  void clear() => state = const CartState();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);