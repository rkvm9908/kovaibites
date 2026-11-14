import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/delivery_providers.dart';
import '../../widgets/ui_kit.dart';
import '../auth/forgot_password.dart';
import '../../widgets/avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(
      BuildContext context, WidgetRef ref, AppUser user) async {
    final c = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: c,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
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
      await ref.read(authServiceProvider).updateName(user.uid, name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final app = ref.watch(myApplicationProvider).value;

    final items = <Widget>[
      if (user != null) _ProfileCard(user, () => _editName(context, ref, user)),
      const SizedBox(height: Sp.md),
      _NavTile(
        icon: Icons.receipt_long_outlined,
        title: 'My orders',
        subtitle: 'Track and review past orders',
        onTap: () => context.push('/orders'),
      ),
      _NavTile(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Order and account updates',
        color: Colors.blue.shade700,
        onTap: () => context.push('/notifications'),
      ),
      _NavTile(
        icon: Icons.lock_reset,
        title: 'Reset password',
        subtitle: 'We will email you a reset link',
        color: Colors.purple.shade600,
        onTap: () => showForgotPasswordDialog(context, ref,
            initialEmail: user?.email ?? '', lockEmail: true),
      ),
      const SectionTitle('Earn with us'),
      _deliverySection(context, user, app),
      const SizedBox(height: Sp.lg),
      OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        onPressed: () => ref.read(authServiceProvider).signOut(),
      ),
      const SizedBox(height: Sp.xl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(Sp.md),
            children: [
              for (var i = 0; i < items.length; i++)
                items[i]
                    .animate(delay: (50 * i.clamp(0, 10)).ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  /// Delivery-partner entry point; changes with the application status.
  Widget _deliverySection(
      BuildContext context, AppUser? user, dynamic app) {
    if (user?.isDelivery == true) {
      return _NavTile(
        icon: Icons.delivery_dining,
        title: 'Delivery dashboard',
        subtitle: 'You are an approved delivery partner',
        color: Brand.success,
        onTap: () => context.push('/delivery'),
      );
    }
    if (app == null) {
      return _NavTile(
        icon: Icons.two_wheeler,
        title: 'Become a delivery partner',
        subtitle: 'Fill in your details and apply',
        onTap: () => context.push('/delivery/apply'),
      );
    }
    switch (app.status) {
      case 'pending':
        return const AppCard(
          child: Row(children: [
            IconBadge(Icons.hourglass_top, color: Colors.orange),
            SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application under review',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('You will be notified once an admin responds',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ]),
        );
      case 'rejected':
        return AppCard(
          color: Colors.red.shade50,
          onTap: () => context.push('/delivery/apply'),
          child: Row(children: [
            IconBadge(Icons.cancel_outlined, color: Colors.red.shade700),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application rejected',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Reason: ${app.rejectReason}',
                      style: const TextStyle(fontSize: 12)),
                  const Text('Tap to apply again',
                      style: TextStyle(
                          fontSize: 12,
                          color: Brand.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit;
  const _ProfileCard(this.user, this.onEdit);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        EditableAvatar(user, radius: 34, ring: true),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text(user.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Tap the photo to change it',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit name',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
        ),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = Brand.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm + 2),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          IconBadge(icon, color: color),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}