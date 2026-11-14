import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../providers/cart_providers.dart';
import '../../providers/restaurant_providers.dart';
import '../../providers/review_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/add_button.dart';
import '../../widgets/app_states.dart';
import '../../widgets/cart_actions.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/food_image.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/reviews_sheet.dart';
import '../../widgets/veg_badge.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = ref.watch(restaurantProvider(id));
    final menu = ref.watch(menuProvider(id));

    return restaurant.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingState()),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorState(e)),
      data: (r) {
        if (r == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
                icon: Icons.storefront, title: 'Restaurant not found'),
          );
        }

        return Scaffold(
          bottomNavigationBar: const CartBar(),
          body: LayoutBuilder(builder: (context, c) {
            // Keep the menu readable on wide screens.
            final side = c.maxWidth > 832 ? (c.maxWidth - 800) / 2 : Sp.md;

            return CustomScrollView(slivers: [
              _headerBar(context, r),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverToBoxAdapter(child: _Info(r)),
              ),
              ...menu.when<List<Widget>>(
                loading: () => [
                  const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(Sp.xl), child: LoadingState()),
                  ),
                ],
                error: (e, _) => [SliverToBoxAdapter(child: ErrorState(e))],
                data: (items) => [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 0, side, Sp.xl),
                    sliver: _menuSliver(items, r),
                  ),
                ],
              ),
            ]);
          }),
        );
      },
    );
  }

  /// Collapsing app bar with an auto-sliding image gallery.
  Widget _headerBar(BuildContext context, Restaurant r) {
    final top = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: Brand.ink,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleButton(
          icon: Icons.arrow_back,
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      flexibleSpace: LayoutBuilder(builder: (context, c) {
        final collapsed = c.biggest.height <= kToolbarHeight + top + 24;
        return FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          titlePadding: const EdgeInsetsDirectional.only(start: 64, bottom: 16),
          title: AnimatedOpacity(
            opacity: collapsed ? 1 : 0,
            duration: AppMotion.normal,
            child: Text(r.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ),
          background: _HeaderGallery(urls: r.images),
        );
      }),
    );
  }

  /// Menu grouped by category with staggered entrance animations.
  Widget _menuSliver(List<MenuItem> items, Restaurant r) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
            icon: Icons.menu_book, title: 'Menu coming soon'),
      );
    }

    final grouped = <String, List<MenuItem>>{};
    for (final i in items) {
      grouped.putIfAbsent(i.category, () => []).add(i);
    }

    final children = <Widget>[];
    var index = 0;
    for (final e in grouped.entries) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: Sp.lg, bottom: Sp.md),
        child: Text(e.key,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ));
      for (final item in e.value) {
        children.add(_MenuTile(item, r, index++));
      }
    }
    return SliverList(delegate: SliverChildListDelegate(children));
  }
}

// =============================================================================
// Header gallery
// =============================================================================
class _HeaderGallery extends StatefulWidget {
  final List<String> urls;
  const _HeaderGallery({required this.urls});

  @override
  State<_HeaderGallery> createState() => _HeaderGalleryState();
}

class _HeaderGalleryState extends State<_HeaderGallery> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  List<String> get _urls => widget.urls.isEmpty ? [''] : widget.urls;

  @override
  void initState() {
    super.initState();
    // Slide to the next image every 4 seconds when there is more than one.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_urls.length <= 1 || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _urls.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _urls.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: n,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => FoodImage(_urls[i]),
        ),
        // Scrims keep the back button and title readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.transparent, Colors.black26],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        if (n > 1)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < n; i++)
                  AnimatedContainer(
                    duration: AppMotion.normal,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        // Rounded top edge of the content sheet.
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 26,
            decoration: const BoxDecoration(
              color: Brand.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: 40, height: 40, child: Icon(icon, color: Brand.ink)),
        ),
      );
}

// =============================================================================
// Restaurant info block
// =============================================================================
class _Info extends StatelessWidget {
  final Restaurant r;
  const _Info(this.r);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(r.name,
            style: t.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(r.cuisine,
            style: t.textTheme.bodyMedium
                ?.copyWith(color: t.colorScheme.outline)),
        const SizedBox(height: Sp.md),
        Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
          _InfoChip(
              icon: Icons.star_rounded,
              text: r.rating.toStringAsFixed(1),
              color: Brand.success,
              filled: true),
          _InfoChip(
              icon: Icons.timer_outlined, text: '${r.deliveryMins} min'),
          _InfoChip(
              icon: Icons.currency_rupee, text: '${r.priceForTwo} for two'),
          _InfoChip(
            icon: r.isOpen ? Icons.circle : Icons.do_not_disturb_on_outlined,
            text: r.isOpen ? 'Open now' : 'Closed',
            color: r.isOpen ? Brand.success : Colors.red.shade700,
          ),
        ]),
        if (!r.isOpen) ...[
          const SizedBox(height: Sp.md),
          Container(
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.red.shade700),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                    'This restaurant is closed right now. Ordering is paused.',
                    style: TextStyle(color: Colors.red.shade800)),
              ),
            ]),
          ),
        ],
        if (r.hasLocation) ...[
          const SizedBox(height: Sp.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
            onPressed: () => openDirections(r.latLng!),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool filled;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Brand.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? c : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: filled ? null : Brand.softShadow,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: filled ? Colors.white : c),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : Brand.ink)),
      ]),
    );
  }
}

// =============================================================================
// Menu tile (Zomato-style: details on the left, image + ADD on the right)
// =============================================================================
class _MenuTile extends ConsumerWidget {
  final MenuItem item;
  final Restaurant restaurant;
  final int index;
  const _MenuTile(this.item, this.restaurant, this.index);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final qty = ref.watch(cartProvider.select((c) => c.qtyOf(item.id)));
    final reviews = ref
            .watch(reviewsProvider((rid: restaurant.id, itemId: item.id)))
            .value ??
        [];
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
    final canOrder = restaurant.isOpen && item.available;

    return Container(
      margin: const EdgeInsets.only(bottom: Sp.md),
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
            child: Opacity(
              opacity: item.available ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VegBadge(isVeg: item.isVeg),
                  const SizedBox(height: Sp.xs),
                  Text(item.name,
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () =>
                        showReviewsSheet(context, restaurant.id, item),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: Brand.star),
                      const SizedBox(width: 2),
                      Text(
                          reviews.isEmpty
                              ? 'Rate this'
                              : '${avg.toStringAsFixed(1)} (${reviews.length})',
                          style: t.textTheme.bodySmall),
                      const Icon(Icons.chevron_right, size: 16),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text('₹${item.price.toStringAsFixed(0)}',
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.outline)),
                  ],
                  if (!item.available)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Out of stock',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Sp.md),
          SizedBox(
            width: 116,
            height: 128,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 108,
                  child: GestureDetector(
                    onTap: item.images.isEmpty
                        ? null
                        : () => showGallery(context, item.images),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.md),
                      child: Stack(fit: StackFit.expand, children: [
                        FoodImage(item.imageUrl),
                        if (item.images.length > 1)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('+${item.images.length - 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
                // ADD button overlaps the bottom edge of the image.
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: AddButton(
                    qty: qty,
                    enabled: canOrder,
                    onAdd: () => addToCart(context, ref, restaurant, item),
                    onIncrement: () =>
                        ref.read(cartProvider.notifier).increment(item.id),
                    onRemove: () =>
                        ref.read(cartProvider.notifier).remove(item.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: (40 * index.clamp(0, 10)).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}