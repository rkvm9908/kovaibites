import 'package:flutter/material.dart';
import '../core/design.dart';
import 'pressable.dart';

/// Colour used for an order status across the app.
Color statusColor(String status) => switch (status) {
      'delivered' => Brand.success,
      'cancelled' => Colors.red.shade700,
      'out_for_delivery' => Colors.blue.shade700,
      _ => Brand.primary,
    };

/// White rounded card with a soft shadow. Becomes pressable when [onTap] is set.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.md),
    this.onTap,
    this.color = Colors.white,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: Brand.softShadow,
        border: border,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(hoverScale: 1.01, onTap: onTap, child: card);
  }
}

/// Bold section heading with an optional trailing widget.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Sp.md, bottom: Sp.sm),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Small coloured pill, e.g. an order status.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Icon inside a softly tinted circle.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(this.icon,
      {super.key, this.color = Brand.primary, this.size = 42});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

/// Full-width gradient button with a built-in loading state.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: (onPressed == null && !loading) ? 0.5 : 1,
      child: Pressable(
        hoverScale: 1.01,
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: Brand.gradient,
            borderRadius: BorderRadius.circular(Radii.lg),
            boxShadow: [
              BoxShadow(
                  color: Brand.primary.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: loading
                ? const SizedBox(
                    key: ValueKey('busy'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Row(
                    key: ValueKey(label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Number that counts up to [value] whenever it changes.
class CountUp extends StatelessWidget {
  final num value;
  final String prefix;
  final int decimals;
  final TextStyle? style;

  const CountUp(this.value,
      {super.key, this.prefix = '', this.decimals = 0, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) =>
          Text('$prefix${v.toStringAsFixed(decimals)}', style: style),
    );
  }
}