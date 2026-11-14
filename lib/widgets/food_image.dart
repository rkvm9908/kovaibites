import 'package:flutter/material.dart';
import '../core/design.dart';

/// Serves a smaller, optimised image for Cloudinary URLs.
String _optimized(String u) => u.contains('res.cloudinary.com')
    ? u.replaceFirst('/upload/', '/upload/f_auto,q_auto,w_600/')
    : u;

/// Network image with a branded placeholder and a smooth fade-in.
class FoodImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const FoodImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE4D9), Color(0xFFFFF1EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_menu_rounded,
            size: 36, color: Brand.primary.withOpacity(0.35)),
      ),
    );

    if (url.isEmpty) return placeholder;

    return Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        Image.network(
          _optimized(url),
          fit: fit,
          frameBuilder: (context, child, frame, wasSyncLoaded) {
            if (wasSyncLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ],
    );
  }
}