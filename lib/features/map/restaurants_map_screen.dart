import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/design.dart';
import '../../models/restaurant.dart';
import '../../providers/restaurant_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/food_image.dart';
import '../../widgets/osm.dart';
import '../../widgets/ui_kit.dart';

class RestaurantsMapScreen extends ConsumerStatefulWidget {
  const RestaurantsMapScreen({super.key});

  @override
  ConsumerState<RestaurantsMapScreen> createState() => _State();
}

class _State extends ConsumerState<RestaurantsMapScreen> {
  final _map = MapController();
  String? _selId;
  LatLng? _me;
  bool _locating = false;

  void _select(Restaurant r) {
    setState(() => _selId = r.id);
    final zoom = _map.camera.zoom;
    _map.move(r.latLng!, zoom < 14 ? 14 : zoom);
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final p = await getCurrentLatLng();
      if (!mounted) return;
      setState(() => _me = p);
      _map.move(p, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants near you')),
      body: restaurants.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(e),
        data: (list) {
          final withLoc = list.where((r) => r.hasLocation).toList();
          if (withLoc.isEmpty) {
            return const EmptyState(
                icon: Icons.map_outlined,
                title: 'No restaurants on the map yet',
                subtitle: 'Pins appear once an admin sets a location');
          }

          final pts = [for (final r in withLoc) r.latLng!];
          final sel = withLoc.where((r) => r.id == _selId).toList();
          final selected = sel.isEmpty ? null : sel.first;

          return Stack(children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: pts.first,
                initialZoom: 13,
                // Fit every pin on screen when there is more than one.
                initialCameraFit: pts.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(pts),
                        padding: const EdgeInsets.all(64),
                        maxZoom: 15)
                    : null,
                onTap: (_, __) => setState(() => _selId = null),
              ),
              children: [
                osmTiles(),
                MarkerLayer(markers: [
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.9, end: 1.15, duration: 900.ms),
                    ),
                  for (final r in withLoc)
                    Marker(
                      point: r.latLng!,
                      width: 150,
                      height: 90,
                      alignment: Alignment.topCenter,
                      child: _Pin(
                        r: r,
                        selected: r.id == _selId,
                        onTap: () => _select(r),
                      ),
                    ),
                ]),
                osmAttribution(),
              ],
            ),

            // Count chip
            Positioned(
              left: Sp.md,
              top: Sp.md,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Brand.softShadow,
                ),
                child: Text('${withLoc.length} restaurants',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),

            // My location button (moves up when the card is visible)
            AnimatedPositioned(
              duration: AppMotion.normal,
              curve: Curves.easeOutCubic,
              right: Sp.md,
              bottom: selected != null ? 190 : Sp.lg,
              child: Material(
                color: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _locating ? null : _locateMe,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Icon(Icons.my_location, color: Brand.primary),
                  ),
                ),
              ),
            ),

            // Selected restaurant card
            Positioned(
              left: Sp.md,
              right: Sp.md,
              bottom: Sp.md,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.4), end: Offset.zero)
                          .animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: selected == null
                        ? const SizedBox.shrink(key: ValueKey('none'))
                        : _SheetCard(
                            key: ValueKey(selected.id),
                            r: selected,
                            onMenu: () =>
                                context.push('/restaurant/${selected.id}'),
                          ),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Map pin. The selected pin grows and shows the restaurant name.
class _Pin extends StatelessWidget {
  final Restaurant r;
  final bool selected;
  final VoidCallback onTap;
  const _Pin({required this.r, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = r.isOpen ? Brand.primary : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: AppMotion.normal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: Brand.softShadow,
              ),
              child: Text(r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          AnimatedScale(
            scale: selected ? 1.25 : 1,
            alignment: Alignment.bottomCenter,
            duration: AppMotion.normal,
            curve: Curves.easeOutBack,
            child: Icon(Icons.location_on, size: 46, color: color),
          ),
        ],
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final Restaurant r;
  final VoidCallback onMenu;
  const _SheetCard({super.key, required this.r, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: SizedBox(width: 72, height: 72, child: FoodImage(r.imageUrl)),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(r.cuisine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.outline)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 16, color: Brand.star),
                  Text(' ${r.rating.toStringAsFixed(1)}   ',
                      style: t.textTheme.bodySmall),
                  const Icon(Icons.timer_outlined, size: 14),
                  Text(' ${r.deliveryMins} min   ',
                      style: t.textTheme.bodySmall),
                  StatusChip(r.isOpen ? 'Open' : 'Closed',
                      r.isOpen ? Brand.success : Colors.red.shade700),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: Sp.md),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Directions'),
              onPressed: () => openDirections(r.latLng!),
            ),
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text('View menu'),
              onPressed: onMenu,
            ),
          ),
        ]),
      ]),
    );
  }
}