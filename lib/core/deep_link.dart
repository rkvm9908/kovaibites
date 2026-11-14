import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/app_notification.dart';
import '../providers/admin_providers.dart';

/// Admin tab names, in the same order as the AdminShell tabs.
const adminTabNames = ['dashboard', 'orders', 'menu', 'partners', 'profile'];

/// Route that opens a given admin tab, e.g. '/admin?tab=orders'.
String adminTabRoute(String tab) => '/admin?tab=$tab';

/// Decides where a notification should lead. Uses the stored route, and falls
/// back to the title for notifications created before routes existed.
String routeForNotification(AppNotification n, {required bool isAdmin}) {
  if (n.route.isNotEmpty) return n.route;
  final t = n.title.toLowerCase();

  if (isAdmin) {
    if (t.contains('delivery partner')) return '/admin/delivery-requests';
    if (t.contains('order')) return adminTabRoute('orders');
    return adminTabRoute('dashboard');
  }
  if (t.contains('order')) return '/orders';
  if (t.contains('approved')) return '/delivery';
  if (t.contains('application') || t.contains('delivery')) return '/settings';
  return '';
}

/// Opens an in-app route. Admin tab links ('/admin?tab=orders') select the
/// tab first, because the admin shell keeps its tab in a provider.
void openRoute(BuildContext context, WidgetRef ref, String route) {
  if (route.isEmpty) return;
  final uri = Uri.parse(route);

  if (uri.path == '/admin') {
    final tab = uri.queryParameters['tab'] ?? 'dashboard';
    final i = adminTabNames.indexOf(tab);
    if (tab == 'orders') {
      ref.read(adminOrderFilterProvider.notifier).select('active');
    }
    ref.read(adminTabProvider.notifier).select(i < 0 ? 0 : i);
    context.go('/admin');
    return;
  }
  context.push(route);
}