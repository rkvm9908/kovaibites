import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/menu_item.dart';
import '../../providers/admin_providers.dart';
import '../../providers/restaurant_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/food_image.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/veg_badge.dart';
import 'admin_dialogs.dart';

// =============================================================================
// Manage tab: restaurant selector + Menu / Restaurant sub-tabs
// =============================================================================
class ManageTab extends ConsumerWidget {
  const ManageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(restaurantsProvider);
    final selected = ref.watch(selectedRestaurantProvider);

    return restaurants.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(e),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const EmptyState(
                  icon: Icons.storefront, title: 'No restaurants yet'),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add restaurant'),
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const RestaurantDialog()),
              ),
            ]),
          );
        }

        final id = list.any((r) => r.id == selected) ? selected! : list.first.id;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: DefaultTabController(
              length: 2,
              child: Column(children: [
                // Restaurant chips
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.md, vertical: Sp.sm + 2),
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.only(right: Sp.sm),
                          child: ChoiceChip(
                            label: Text(r.name),
                            selected: r.id == id,
                            showCheckmark: false,
                            avatar: Icon(
                                r.isOpen ? Icons.circle : Icons.circle_outlined,
                                size: 10,
                                color: r.isOpen ? Brand.success : Colors.grey),
                            onSelected: (_) => ref
                                .read(selectedRestaurantProvider.notifier)
                                .select(r.id),
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const RestaurantDialog()),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: Brand.primary,
                  labelColor: Brand.primary,
                  tabs: [
                    Tab(icon: Icon(Icons.menu_book), text: 'Menu'),
                    Tab(icon: Icon(Icons.storefront), text: 'Restaurant'),
                  ],
                ),
                Expanded(
                  child: TabBarView(children: [
                    MenuTab(id),
                    RestaurantTab(id),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Menu tab
// =============================================================================
class MenuTab extends ConsumerStatefulWidget {
  final String restaurantId;
  const MenuTab(this.restaurantId, {super.key});

  @override
  ConsumerState<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends ConsumerState<MenuTab> {
  String _q = '';

  Future<void> _delete(MenuItem m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${m.name}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(adminServiceProvider)
          .deleteMenuItem(widget.restaurantId, m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuProvider(widget.restaurantId));
    final admin = ref.read(adminServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Brand.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => MenuItemDialog(restaurantId: widget.restaurantId),
        ),
      ),
      body: menu.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(e),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
                icon: Icons.menu_book,
                title: 'Menu is empty',
                subtitle: 'Tap "Add item" to create the first dish');
          }

          final q = _q.toLowerCase();
          final filtered = items
              .where((m) =>
                  q.isEmpty ||
                  m.name.toLowerCase().contains(q) ||
                  m.category.toLowerCase().contains(q))
              .toList();

          final grouped = <String, List<MenuItem>>{};
          for (final m in filtered) {
            grouped.putIfAbsent(m.category, () => []).add(m);
          }

          final children = <Widget>[];
          var index = 0;
          for (final e in grouped.entries) {
            children.add(SectionTitle('${e.key}  (${e.value.length})'));
            for (final m in e.value) {
              children.add(Padding(
                padding: const EdgeInsets.only(bottom: Sp.sm + 2),
                child: _MenuRow(
                  m,
                  onToggle: (v) =>
                      admin.setItemAvailable(widget.restaurantId, m.id, v),
                  onEdit: () => showDialog(
                    context: context,
                    builder: (_) => MenuItemDialog(
                        restaurantId: widget.restaurantId, item: m),
                  ),
                  onDelete: () => _delete(m),
                )
                    .animate(delay: (30 * (index++).clamp(0, 10)).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.06, end: 0),
              ));
            }
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, 0),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search dishes or categories',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off, title: 'No dishes match')
                  : ListView(
                      padding:
                          const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, 96),
                      children: children,
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final MenuItem m;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MenuRow(this.m,
      {required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return AppCard(
      child: Column(children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: SizedBox(width: 64, height: 64, child: FoodImage(m.imageUrl)),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  VegBadge(isVeg: m.isVeg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('₹${m.price.toStringAsFixed(0)}  ·  ${m.images.length} photo${m.images.length == 1 ? '' : 's'}',
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.outline)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: Sp.sm),
        Row(children: [
          Switch(value: m.available, onChanged: onToggle),
          Text(m.available ? 'In stock' : 'Out of stock',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: m.available ? Brand.success : Colors.red.shade700)),
          const Spacer(),
          IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit),
          IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              onPressed: onDelete),
        ]),
      ]),
    );
  }
}

// =============================================================================
// Restaurant tab
// =============================================================================
class RestaurantTab extends ConsumerWidget {
  final String restaurantId;
  const RestaurantTab(this.restaurantId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(restaurantProvider(restaurantId));
    final admin = ref.read(adminServiceProvider);
    final t = Theme.of(context);

    return r.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(e),
      data: (rest) {
        if (rest == null) {
          return const EmptyState(icon: Icons.storefront, title: 'Not found');
        }

        Widget chip(IconData i, String s, {Color? c}) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (c ?? Brand.ink).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(i, size: 14, color: c ?? Brand.ink),
                const SizedBox(width: 5),
                Text(s,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c ?? Brand.ink)),
              ]),
            );

        final sections = <Widget>[
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.xl),
            child: ImageCarousel(urls: rest.images, aspectRatio: 16 / 7),
          ),
          const SizedBox(height: Sp.md),

          // Open / closed card
          AnimatedContainer(
            duration: AppMotion.normal,
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: rest.isOpen ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(
                  color: rest.isOpen
                      ? Colors.green.shade200
                      : Colors.red.shade200),
            ),
            child: Row(children: [
              IconBadge(rest.isOpen ? Icons.storefront : Icons.lock_outline,
                  color: rest.isOpen ? Brand.success : Colors.red.shade700),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rest.isOpen ? 'Accepting orders' : 'Orders paused',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        rest.isOpen
                            ? 'Customers can order right now'
                            : 'Customers see this restaurant as closed',
                        style: t.textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: rest.isOpen,
                onChanged: (v) => admin.setRestaurantOpen(rest.id, v),
              ),
            ]),
          ),
          const SizedBox(height: Sp.md),

          // Details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rest.name,
                    style: t.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(rest.cuisine,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: t.colorScheme.outline)),
                const SizedBox(height: Sp.md),
                Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
                  chip(Icons.star_rounded, rest.rating.toStringAsFixed(1),
                      c: Brand.success),
                  chip(Icons.timer_outlined, '${rest.deliveryMins} min'),
                  chip(Icons.currency_rupee, '${rest.priceForTwo} for two'),
                  chip(
                      rest.hasLocation
                          ? Icons.place
                          : Icons.location_off_outlined,
                      rest.hasLocation ? 'Pinned on map' : 'No map pin',
                      c: rest.hasLocation ? Colors.blue.shade700 : Colors.grey),
                  chip(Icons.photo_library_outlined,
                      '${rest.images.length} photo${rest.images.length == 1 ? '' : 's'}'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit details'),
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => RestaurantDialog(restaurant: rest)),
              ),
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('New restaurant'),
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const RestaurantDialog()),
              ),
            ),
          ]),
        ];

        return ListView(
          padding: const EdgeInsets.all(Sp.md),
          children: [
            for (var i = 0; i < sections.length; i++)
              sections[i]
                  .animate(delay: (50 * i).ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
          ],
        );
      },
    );
  }
}