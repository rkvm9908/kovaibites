import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/deep_link.dart';
import '../../core/design.dart';
import '../../core/format.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_providers.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/ui_kit.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final svc = ref.read(notificationServiceProvider);
    final isAdmin = ref.watch(currentUserProvider).value?.role == 'admin';

    /// Marks the notification as read, then opens the page it points to.
    void open(AppNotification n) {
      if (!n.read) svc.markRead(n.id);
      openRoute(context, ref, routeForNotification(n, isAdmin: isAdmin));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () {
                for (final n in list.value ?? <AppNotification>[]) {
                  if (!n.read) svc.markRead(n.id);
                }
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: list.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(e),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: "You're all caught up",
              subtitle: 'Order and account updates will appear here',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(Sp.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.sm + 2),
                itemBuilder: (_, i) => _Tile(
                  items[i],
                  hasRoute: routeForNotification(items[i], isAdmin: isAdmin)
                      .isNotEmpty,
                  onTap: () => open(items[i]),
                )
                    .animate(delay: (40 * i.clamp(0, 8)).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Picks an icon and colour from the notification title.
(IconData, Color) _style(String title) {
  final t = title.toLowerCase();
  if (t.contains('approved')) return (Icons.verified_rounded, Brand.success);
  if (t.contains('rejected') || t.contains('removed')) {
    return (Icons.cancel_rounded, Colors.red.shade600);
  }
  if (t.contains('delivery')) return (Icons.two_wheeler, Colors.indigo);
  if (t.contains('order')) return (Icons.receipt_long_rounded, Brand.primary);
  return (Icons.notifications_rounded, Colors.blueGrey);
}

class _Tile extends StatelessWidget {
  final AppNotification n;
  final bool hasRoute;
  final VoidCallback onTap;
  const _Tile(this.n, {required this.hasRoute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (icon, color) = _style(n.title);

    return AppCard(
      onTap: onTap,
      color: n.read ? Colors.white : const Color(0xFFFFF3EC),
      border: n.read ? null : Border.all(color: Brand.primary.withOpacity(0.25)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color: color),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(n.title,
                        style: TextStyle(
                            fontWeight:
                                n.read ? FontWeight.w600 : FontWeight.w800)),
                  ),
                  if (!n.read)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          color: Brand.primary, shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(n.body, style: t.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(children: [
                  Text(timeAgo(n.createdAt),
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.outline)),
                  const Spacer(),
                  if (hasRoute) ...const [
                    Text('View',
                        style: TextStyle(
                            color: Brand.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    Icon(Icons.chevron_right, size: 16, color: Brand.primary),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}