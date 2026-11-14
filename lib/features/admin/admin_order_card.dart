import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/app_order.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/ui_kit.dart';

class AdminOrderCard extends ConsumerWidget {
  final AppOrder o;
  const AdminOrderCard(this.o, {super.key});

  /// status -> [next status, button label]
  static const _next = {
    'placed': ['accepted', 'Accept'],
    'accepted': ['preparing', 'Start preparing'],
    'preparing': ['out_for_delivery', 'Out for delivery'],
    'out_for_delivery': ['delivered', 'Mark delivered'],
  };
  static const _cancellable = ['placed', 'accepted', 'preparing'];

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('The customer will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(adminServiceProvider).setStatus(o, 'cancelled');
    }
  }

  Widget _info(IconData icon, String text, {bool selectable = false}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: Sp.sm),
          Expanded(child: selectable ? SelectableText(text) : Text(text)),
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final next = _next[o.status];
    final isNew = o.status == 'placed';
    final d = o.createdAt;

    return AppCard(
      border: isNew ? Border.all(color: Brand.primary, width: 2) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (isNew) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Brand.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('NEW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.55, end: 1, duration: 700.ms),
              const SizedBox(width: Sp.sm),
            ],
            Expanded(
              child: Text(
                '${o.restaurantName}  ·  ${o.userName.isEmpty ? 'Customer' : o.userName}',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            StatusChip(o.statusLabel, statusColor(o.status)),
          ]),
          if (d != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.outline),
              ),
            ),
          const SizedBox(height: Sp.sm),
          for (final i in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${i['qty']} x ${i['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          const Divider(height: Sp.lg),
          _info(Icons.location_on_outlined, o.address),
          _info(Icons.phone_outlined, o.phone, selectable: true),
          if (o.deliveryBoyName.isNotEmpty)
            _info(Icons.two_wheeler, 'Rider: ${o.deliveryBoyName}'),
          if (o.note.isNotEmpty) _info(Icons.sticky_note_2_outlined, o.note),
          const SizedBox(height: Sp.sm),
          Text('Total ₹${o.total.toStringAsFixed(0)}  ·  Cash on Delivery',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (next != null || _cancellable.contains(o.status)) ...[
            const SizedBox(height: Sp.md),
            Row(children: [
              if (next != null)
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(adminServiceProvider).setStatus(o, next[0]),
                    child: Text(next[1]),
                  ),
                ),
              if (next != null && _cancellable.contains(o.status))
                const SizedBox(width: Sp.sm),
              if (_cancellable.contains(o.status))
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: Text(isNew ? 'Reject' : 'Cancel',
                      style: TextStyle(color: Colors.red.shade700)),
                ),
            ]),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}
/// Opens one order in a bottom sheet. The sheet stays live, so a status
/// change made from it shows up immediately.
void showAdminOrderSheet(BuildContext context, String orderId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Brand.cream,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => Consumer(builder: (context, ref, _) {
      final matches = (ref.watch(allOrdersProvider).value ?? const <AppOrder>[])
          .where((x) => x.id == orderId)
          .toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
        child: matches.isEmpty
            ? const SizedBox(
                height: 120, child: Center(child: Text('Order not found')))
            : SingleChildScrollView(child: AdminOrderCard(matches.first)),
      );
    }),
  );
}