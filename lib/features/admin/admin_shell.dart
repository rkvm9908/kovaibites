import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../providers/admin_providers.dart';
import '../../providers/delivery_providers.dart';
import '../../widgets/notification_bell.dart';
import 'admin_dashboard_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_partners_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _titles = ['Dashboard', 'Orders', 'Menu', 'Partners', 'Profile'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.restaurant_menu,
    Icons.delivery_dining,
    Icons.person_outline,
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const AdminDashboardTab();
      case 1:
        return const AdminOrdersTab();
      case 2:
        return const ManageTab();
      case 3:
        return const PartnersTab();
      default:
        return const AdminProfileTab();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The tab lives in a provider so dashboard cards and notifications
    // can switch it from anywhere.
    final i = ref.watch(adminTabProvider);
    void select(int v) => ref.read(adminTabProvider.notifier).select(v);

    final newOrders = ref
            .watch(allOrdersProvider)
            .value
            ?.where((o) => o.status == 'placed')
            .length ??
        0;
    final requests = ref.watch(pendingApplicationsProvider).value?.length ?? 0;

    Widget icon(int n) => n == 1
        ? Badge(
            label: Text('$newOrders'),
            isLabelVisible: newOrders > 0,
            child: Icon(_icons[n]))
        : Icon(_icons[n]);

    // Cross-fades between tabs.
    final body = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(key: ValueKey(i), child: _page(i)),
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 800;

      return Scaffold(
        appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  gradient: Brand.gradient,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: Sp.sm + 2),
            Text('Kovai Bites  ·  ${_titles[i]}'),
          ]),
          actions: [
            IconButton(
              tooltip: 'Delivery requests',
              icon: Badge(
                label: Text('$requests'),
                isLabelVisible: requests > 0,
                child: const Icon(Icons.how_to_reg_outlined),
              ),
              onPressed: () => context.push('/admin/delivery-requests'),
            ),
            const NotificationBell(),
          ],
        ),
        body: wide
            ? Row(children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: i,
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                  onDestinationSelected: select,
                  destinations: [
                    for (var n = 0; n < 5; n++)
                      NavigationRailDestination(
                          icon: icon(n), label: Text(_titles[n])),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ])
            : body,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: i,
                onDestinationSelected: select,
                destinations: [
                  for (var n = 0; n < 5; n++)
                    NavigationDestination(icon: icon(n), label: _titles[n]),
                ],
              ),
      );
    });
  }
}