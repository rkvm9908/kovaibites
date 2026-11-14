import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/design.dart';

/// A grey block with a shimmer sweep, used as a loading placeholder.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height, this.radius = Radii.md});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white);
  }
}

/// Placeholder that matches the layout of RestaurantCard.
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const Expanded(child: SkeletonBox(radius: 0)),
            Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 16),
                  SizedBox(height: Sp.sm),
                  SkeletonBox(width: 100, height: 12),
                  SizedBox(height: Sp.sm),
                  SkeletonBox(width: 130, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}