import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/design.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/ui_kit.dart';
import '../auth/forgot_password.dart';
import '../../widgets/avatar.dart';

class AdminProfileTab extends ConsumerWidget {
  const AdminProfileTab({super.key});

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String uid, String cur) async {
    final c = TextEditingController(text: cur);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
            controller: c,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(authServiceProvider).updateName(uid, name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider).value;
    if (u == null) return const SizedBox.shrink();

    Widget tile(IconData icon, String title, String sub, Color c,
            VoidCallback? onTap) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm + 2),
          child: AppCard(
            onTap: onTap,
            child: Row(children: [
              IconBadge(icon, color: c),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(sub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ]),
          ),
        );

    final items = <Widget>[
      Container(
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(Radii.xl),
          boxShadow: [
            BoxShadow(
                color: Brand.primary.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Row(children: [
          EditableAvatar(
                u,
                radius: 34,
                ring: true,
                ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                Text(u.email,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('ADMIN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editName(context, ref, u.uid, u.name),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ]),
      ),
      const SizedBox(height: Sp.md),
      tile(Icons.lock_reset, 'Reset password', 'Send a reset link to your email',
          Colors.purple.shade600, () => showForgotPasswordDialog(context, ref,
              initialEmail: u.email, lockEmail: true)),
      tile(Icons.bolt, 'Auto-accept',
          'Orders are accepted after $autoAcceptSeconds sec when a partner is online',
          Colors.orange, null),
      tile(Icons.storefront_outlined, 'Customer view',
          'See the app the way customers do', Colors.blue.shade700,
          () => context.go('/')),
      const SizedBox(height: Sp.md),
      OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        onPressed: () => ref.read(authServiceProvider).signOut(),
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(Sp.md),
          children: [
            for (var i = 0; i < items.length; i++)
              items[i]
                  .animate(delay: (50 * i).ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    );
  }
}