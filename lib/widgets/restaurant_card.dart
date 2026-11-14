import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/design.dart';
import '../models/restaurant.dart';
import 'food_image.dart';
import 'pressable.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant r;

  /// Position in the grid; used to stagger the entrance animation.
  final int index;

  const RestaurantCard(this.r, {super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Pressable(
      onTap: () => context.push('/restaurant/${r.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.xl),
          boxShadow: Brand.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodImage(r.imageUrl),
                    // Dark gradient so the overlay pills stay readable.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: _Pill(
                          icon: Icons.timer_outlined,
                          text: '${r.deliveryMins} min'),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Brand.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(r.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          const SizedBox(width: 2),
                          const Icon(Icons.star_rounded,
                              size: 13, color: Colors.white),
                        ]),
                      ),
                    ),
                    if (!r.isOpen)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        alignment: Alignment.center,
                        child: const Text('CLOSED',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.md, 12, Sp.md, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(r.cuisine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.outline)),
                    const SizedBox(height: 6),
                    Text('₹${r.priceForTwo} for two',
                        style: t.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (60 * index.clamp(0, 8)).ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}