import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'auth_providers.dart';

final notificationServiceProvider = Provider((_) => NotificationService());

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  final to = user.role == 'admin' ? 'admin' : user.uid;
  return ref.watch(notificationServiceProvider).stream(to);
});

final unreadCountProvider = Provider<int>((ref) =>
    ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0);