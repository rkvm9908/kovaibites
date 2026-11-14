import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/app_order.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/app_states.dart';
import 'admin_order_card.dart';

class AdminOrdersTab extends ConsumerWidget {
  const AdminOrdersTab({super.key});

  static const _finished = ['delivered', 'cancelled'];
  static const _basic = ['active', 'done', 'all'];

  /// A filter is 'active', 'done', 'all' or one specific order status.
  bool _matches(AppOrder o, String f) {
    switch (f) {
      case 'active':
        return !_finished.contains(o.status);
      case 'done':
        return _finished.contains(o.status);
      case 'all':
        return true;
      default:
        return o.status == f;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    final filter = ref.watch(adminOrderFilterProvider);
    final notifier = ref.read(adminOrderFilterProvider.notifier);
    final isBasic = _basic.contains(filter);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Column(children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'done', label: Text('Completed')),
                  ButtonSegment(value: 'all', label: Text('All')),
                ],
                selected: isBasic ? {filter} : <String>{},
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) notifier.select(s.first);
                },
              ),
              // Shown when a dashboard card opened a single-status filter.
              AnimatedSize(
                duration: AppMotion.normal,
                child: isBasic
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Sp.sm),
                        child: InputChip(
                          avatar: const Icon(Icons.filter_alt, size: 16),
                          label: Text(
                              'Status: ${AppOrder.statusLabels[filter] ?? filter}'),
                          onDeleted: () => notifier.select('all'),
                        ),
                      ),
              ),
            ]),
          ),
          Expanded(
            child: orders.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(e),
              data: (list) {
                final f = list.where((o) => _matches(o, filter)).toList();
                if (f.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No orders here',
                      subtitle: 'New orders appear live');
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(Sp.md),
                  itemCount: f.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
                  itemBuilder: (_, i) => AdminOrderCard(f[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}