import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/dish.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_providers.dart';
import '../../providers/order_providers.dart';
import '../../providers/restaurant_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/dish_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/pressable.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _vegOnly = false, _topRated = false, _fast = false, _openNow = false;

  static const _cats = [
    ('Biriyani', '🍛'),
    ('Meals', '🍱'),
    ('Tiffin', '🥞'),
    ('Dosa', '🫓'),
    ('Sweets', '🍬'),
    ('Snacks', '🍟'),
    ('Starters', '🍗'),
    ('Juice', '🥤'),
  ];

  /// Sets the search text and query together.
  void _setQuery(String v) {
    final q = v.trim();
    _search.value = TextEditingValue(
        text: q, selection: TextSelection.collapsed(offset: q.length));
    setState(() => _query = q.toLowerCase());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider);
    final dishes = ref.watch(allDishesProvider);

    return Scaffold(
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const _ActiveOrderBanner(),
        const CartBar(),
        NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (i) {
            if (i == 1) context.push('/map');
            if (i == 2) context.push('/orders');
            if (i == 3) context.push('/settings');
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined), label: 'Map'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ]),
      body: LayoutBuilder(builder: (context, c) {
        // Keep content within 1100px on wide screens.
        final side = c.maxWidth > 1132 ? (c.maxWidth - 1100) / 2 : Sp.md;
        final pad = EdgeInsets.symmetric(horizontal: side);

        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header(context, side)),
          ...restaurants.when<List<Widget>>(
            loading: () => [
              SliverPadding(
                padding: pad.copyWith(top: Sp.lg),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: Sp.md,
                    crossAxisSpacing: Sp.md,
                    mainAxisExtent: 276,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const RestaurantCardSkeleton(),
                    childCount: 6,
                  ),
                ),
              ),
            ],
            error: (e, _) => [SliverToBoxAdapter(child: ErrorState(e))],
            data: (all) => _slivers(
                context, pad, all, dishes.value ?? const [], dishes.isLoading),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Sp.xl)),
        ]);
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Gradient hero header with location, greeting and search
  // ---------------------------------------------------------------------------
  Widget _header(BuildContext context, double side) {
    final user = ref.watch(currentUserProvider).value;
    final cartCount = ref.watch(cartProvider.select((c) => c.count));
    final top = MediaQuery.of(context).padding.top;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Decorative floating emoji behind the content.
          Positioned(
            right: 24,
            top: top + 64,
            child: Opacity(
              opacity: 0.22,
              child: const Text('🍛', style: TextStyle(fontSize: 84)),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: -6,
                    end: 6,
                    duration: 2.seconds,
                    curve: Curves.easeInOut),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(side, top + Sp.sm, side, Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 6),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deliver to',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('Coimbatore',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cart',
                    color: Colors.white,
                    icon: Badge(
                      label: Text('$cartCount'),
                      isLabelVisible: cartCount > 0,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    onPressed: () => context.push('/cart'),
                  ),
                  IconButtonTheme(
                    data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                            foregroundColor: Colors.white)),
                    child: const NotificationBell(),
                  ),
                ]),
                const SizedBox(height: Sp.md),
                Text(
                  firstName.isEmpty ? 'Hello!' : 'Hello, $firstName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 2),
                const Text('What are you craving today?',
                    style: TextStyle(color: Colors.white70))
                    .animate()
                    .fadeIn(delay: 150.ms),
                const SizedBox(height: Sp.md),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 20,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search biriyani, dosa, restaurants...',
                      prefixIcon:
                          const Icon(Icons.search, color: Brand.primary),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _setQuery('')),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content slivers: categories, filters, dishes, restaurants
  // ---------------------------------------------------------------------------
  List<Widget> _slivers(BuildContext context, EdgeInsets pad,
      List<Restaurant> all, List<Dish> allDishes, bool dishesLoading) {
    final t = Theme.of(context);
    final byId = {for (final r in all) r.id: r};
    final q = _query;

    bool restOk(Restaurant r) =>
        (!_topRated || r.rating >= 4.0) &&
        (!_fast || r.deliveryMins <= 30) &&
        (!_openNow || r.isOpen);

    final rests = all
        .where((r) =>
            restOk(r) &&
            (q.isEmpty ||
                r.name.toLowerCase().contains(q) ||
                r.cuisine.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });

    // Dish search: name, category, description or the restaurant cuisine.
    final matched = q.isEmpty
        ? <Dish>[]
        : (allDishes.where((d) {
            final r = byId[d.rid];
            if (r == null || !restOk(r)) return false;
            if (_vegOnly && !d.item.isVeg) return false;
            final hay =
                '${d.item.name} ${d.item.category} ${d.item.description} ${r.cuisine}'
                    .toLowerCase();
            return hay.contains(q);
          }).toList()
            ..sort((a, b) {
              final ra = byId[a.rid]!, rb = byId[b.rid]!;
              final sa = (ra.isOpen && a.item.available) ? 0 : 1;
              final sb = (rb.isOpen && b.item.available) ? 0 : 1;
              return sa != sb ? sa.compareTo(sb) : rb.rating.compareTo(ra.rating);
            }));

    final popular = q.isNotEmpty
        ? <Dish>[]
        : (allDishes.where((d) {
            final r = byId[d.rid];
            return r != null &&
                r.isOpen &&
                d.item.available &&
                (!_vegOnly || d.item.isVeg);
          }).toList()
              ..sort((a, b) =>
                  byId[b.rid]!.rating.compareTo(byId[a.rid]!.rating)))
            .take(12)
            .toList();

    Widget title(String s) => SliverPadding(
          padding: pad.copyWith(top: Sp.lg, bottom: Sp.sm),
          sliver: SliverToBoxAdapter(
            child: Text(s,
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
        );

    final filters = [
      ('Veg only', _vegOnly, () => setState(() => _vegOnly = !_vegOnly)),
      ('Rating 4.0+', _topRated, () => setState(() => _topRated = !_topRated)),
      ('Under 30 min', _fast, () => setState(() => _fast = !_fast)),
      ('Open now', _openNow, () => setState(() => _openNow = !_openNow)),
    ];

    return [
      title("What's on your mind?"),

      // Category bubbles (tap to search, tap again to clear).
      SliverToBoxAdapter(
        child: SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: pad,
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
            itemBuilder: (_, i) {
              final selected = _query == _cats[i].$1.toLowerCase();
              return Pressable(
                onTap: () => _setQuery(selected ? '' : _cats[i].$1),
                child: SizedBox(
                  width: 72,
                  child: Column(children: [
                    AnimatedContainer(
                      duration: AppMotion.normal,
                      curve: Curves.easeOutCubic,
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Brand.primary : Colors.white,
                        boxShadow: Brand.softShadow,
                      ),
                      child: AnimatedScale(
                        scale: selected ? 1.2 : 1,
                        duration: AppMotion.normal,
                        child: Text(_cats[i].$2,
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_cats[i].$1,
                        style: t.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected ? Brand.primary : null)),
                  ]),
                ),
              )
                  .animate(delay: (40 * i).ms)
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
            },
          ),
        ),
      ),

      // Filter chips.
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: pad.copyWith(top: Sp.sm),
          child: Row(children: [
            for (final f in filters)
              Padding(
                padding: const EdgeInsets.only(right: Sp.sm),
                child: FilterChip(
                  label: Text(f.$1),
                  selected: f.$2,
                  showCheckmark: false,
                  onSelected: (_) => f.$3(),
                ),
              ),
          ]),
        ),
      ),

      // Popular dishes (home view only).
      if (q.isEmpty && popular.isNotEmpty) ...[
        title('Popular dishes'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: pad.copyWith(bottom: Sp.sm),
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
              itemBuilder: (_, i) =>
                  DishCardSmall(byId[popular[i].rid]!, popular[i].item, index: i),
            ),
          ),
        ),
      ],

      // Search results: dishes first.
      if (q.isNotEmpty) ...[
        title('Dishes (${matched.length})'),
        if (dishesLoading)
          SliverPadding(
            padding: pad,
            sliver: const SliverToBoxAdapter(child: LinearProgressIndicator()),
          ),
        if (matched.isEmpty && !dishesLoading)
          SliverPadding(
            padding: pad,
            sliver: const SliverToBoxAdapter(
              child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No dishes found',
                  subtitle: 'Try a different name'),
            ),
          )
        else
          SliverPadding(
            padding: pad,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                mainAxisSpacing: Sp.md,
                crossAxisSpacing: Sp.md,
                mainAxisExtent: 188,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => DishResultTile(
                    byId[matched[i].rid]!, matched[i].item,
                    index: i),
                childCount: matched.length,
              ),
            ),
          ),
      ],

      // Restaurants.
      title(q.isEmpty
          ? 'Restaurants near you (${rests.length})'
          : 'Restaurants (${rests.length})'),
      if (rests.isEmpty)
        SliverPadding(
          padding: pad,
          sliver: const SliverToBoxAdapter(
            child: EmptyState(
                icon: Icons.storefront_outlined,
                title: 'No restaurants found',
                subtitle: 'Try removing a filter'),
          ),
        )
      else
        SliverPadding(
          padding: pad,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisSpacing: Sp.md,
              crossAxisSpacing: Sp.md,
              mainAxisExtent: 276,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => RestaurantCard(rests[i], index: i),
              childCount: rests.length,
            ),
          ),
        ),
    ];
  }
}

/// Dark strip above the nav bar showing the customer's active order.
class _ActiveOrderBanner extends ConsumerWidget {
  const _ActiveOrderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider).value ?? [];
    final active = orders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final o = active.first;

    return Material(
      color: Brand.ink,
      child: InkWell(
        onTap: () => context.push('/orders'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Sp.md, vertical: Sp.sm + 2),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.greenAccent, shape: BoxShape.circle),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.8, end: 1.4, duration: 700.ms),
            const SizedBox(width: Sp.sm + 2),
            const Icon(Icons.delivery_dining, color: Colors.white),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Text(
                '${o.restaurantName} · ${o.statusLabel}'
                '${active.length > 1 ? '  (+${active.length - 1} more)' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: Brand.primary,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Track',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}