import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design.dart';
import '../providers/auth_providers.dart';
import '../providers/presence_providers.dart';
import '../services/presence_service.dart';

/// Online/offline switch for delivery partners. While online it sends a
/// heartbeat every 60 seconds so the app knows a partner is available.
class OnlineToggleBar extends ConsumerStatefulWidget {
  const OnlineToggleBar({super.key});

  @override
  ConsumerState<OnlineToggleBar> createState() => _State();
}

class _State extends ConsumerState<OnlineToggleBar> {
  bool _online = false;
  Timer? _timer;
  PresenceService? _svc;
  String? _uid;

  Future<void> _set(bool v) async {
    final u = ref.read(currentUserProvider).value;
    if (u == null) return;
    _svc = ref.read(presenceServiceProvider);
    _uid = u.uid;
    _timer?.cancel();
    setState(() => _online = v);

    if (v) {
      await _svc!.beat(u.uid, u.name);
      _timer = Timer.periodic(
          const Duration(seconds: 60), (_) => _svc!.beat(u.uid, u.name));
    } else {
      await _svc!.goOffline(u.uid);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_online && _uid != null) _svc?.goOffline(_uid!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const onColors = [Color(0xFF22C55E), Color(0xFF15803D)];
    const offColors = [Colors.white, Colors.white];

    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, Sp.sm),
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _online ? onColors : offColors),
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: Brand.softShadow,
      ),
      child: Row(children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _online ? Colors.white : Colors.grey.shade400,
          ),
        )
            .animate(
                key: ValueKey(_online),
                onPlay: (c) => _online ? c.repeat(reverse: true) : c.stop())
            .scaleXY(begin: 0.8, end: 1.3, duration: 800.ms),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_online ? "You're online" : "You're offline",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _online ? Colors.white : Brand.ink)),
              Text(
                  _online
                      ? 'Orders can auto-accept. Keep this tab open.'
                      : 'Go online to receive auto-accepted orders',
                  style: TextStyle(
                      fontSize: 12,
                      color: _online ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
        Switch(
          value: _online,
          onChanged: _set,
          activeColor: Colors.white,
          activeTrackColor: Colors.green.shade900,
        ),
      ]),
    );
  }
}