import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/design.dart';

/// Adds a hover lift (web/desktop) and a press-scale effect to any widget.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.97 : (_hover ? widget.hoverScale : 1.0);
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}