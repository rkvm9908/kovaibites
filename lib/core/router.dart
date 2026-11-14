import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/delivery_requests_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/delivery/delivery_apply_screen.dart';
import '../features/delivery/delivery_dashboard_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/restaurants_map_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/restaurant/restaurant_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(currentUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted =
            prefs.getBool('onboarding_completed') ?? false;
        final loc = state.matchedLocation;
        // First-time users must complete onboarding.
        if (!onboardingCompleted) {
            if (loc == '/onboarding') return null;
            return '/onboarding';
        }
        final auth = ref.read(authStateProvider);
        if (auth.isLoading) return null;
        final loggedIn = auth.value != null;
        if (!loggedIn) {
            return loc == '/login' ? null : '/login';
        }
        final profile = ref.read(currentUserProvider);
        if (profile.isLoading) return null;
        final isAdmin = profile.value?.role == 'admin';
        final isDelivery = profile.value?.isDelivery ?? false;
        if (loc == '/login' || loc == '/onboarding') {
            return isAdmin ? '/admin' : '/';
        }
        if (loc.startsWith('/admin') && !isAdmin) return '/';
        if (loc == '/delivery' && !isDelivery) return '/';
        return null;
        },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
      GoRoute(
          path: '/admin/delivery-requests',
          builder: (_, __) => const DeliveryRequestsScreen()),
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, s) => RestaurantDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/map', builder: (_, __) => const RestaurantsMapScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/delivery',
          builder: (_, __) => const DeliveryDashboardScreen()),
      GoRoute(
          path: '/delivery/apply',
          builder: (_, __) => const DeliveryApplyScreen()),
      GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreens(),
            ),
    ],
  );
});