import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/design.dart';

/// Friendly empty state with a pop-in icon.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: t.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: Brand.primary),
            ).animate().scaleXY(
                begin: 0.6,
                end: 1,
                duration: 500.ms,
                curve: Curves.easeOutBack),
            const SizedBox(height: Sp.md),
            Text(title,
                textAlign: TextAlign.center,
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700))
                .animate()
                .fadeIn(delay: 150.ms),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: Sp.xs),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(color: t.colorScheme.outline))
                  .animate()
                  .fadeIn(delay: 250.ms),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object error;
  const ErrorState(this.error, {super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: '$error',
      );
}

/// Bouncing emoji loader.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍛', style: TextStyle(fontSize: 44))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -10, end: 10, duration: 600.ms, curve: Curves.easeInOut),
          const SizedBox(height: Sp.sm),
          Text('Cooking up something tasty...',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}