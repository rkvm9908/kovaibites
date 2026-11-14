import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../services/presence_service.dart';

final presenceServiceProvider = Provider((_) => PresenceService());

final onlineDeliveryProvider = StreamProvider<Map<String, DateTime>>(
    (ref) => ref.watch(presenceServiceProvider).stream());

bool isFresh(DateTime t) => DateTime.now().difference(t) < partnerOnlineWindow;