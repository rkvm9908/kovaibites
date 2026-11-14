import 'menu_item.dart';
import 'restaurant.dart';

class CartLine {
  final MenuItem item;
  final int qty;
  const CartLine(this.item, this.qty);
}

class CartState {
  static const deliveryFee = 30.0;

  final String? restaurantId;
  final String restaurantName;
  final Map<String, CartLine> lines;

  const CartState({
    this.restaurantId,
    this.restaurantName = '',
    this.lines = const {},
  });

  bool get isEmpty => lines.isEmpty;
  int get count => lines.values.fold<int>(0, (s, l) => s + l.qty);
  double get subtotal =>
      lines.values.fold<double>(0, (s, l) => s + l.item.price * l.qty);
  double get total => isEmpty ? 0 : subtotal + deliveryFee;
  int qtyOf(String itemId) => lines[itemId]?.qty ?? 0;

  CartState copyWith(Restaurant r, Map<String, CartLine> newLines) => CartState(
        restaurantId: r.id,
        restaurantName: r.name,
        lines: newLines,
      );
}