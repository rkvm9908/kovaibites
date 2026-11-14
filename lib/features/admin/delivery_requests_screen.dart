import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../core/format.dart';
import '../../models/delivery_application.dart';
import '../../providers/delivery_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/food_image.dart';
import '../../widgets/image_preview.dart';
import '../../widgets/ui_kit.dart';

class DeliveryRequestsScreen extends ConsumerWidget {
  const DeliveryRequestsScreen({super.key});

  void _toast(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _approve(
      BuildContext context, WidgetRef ref, DeliveryApplication a) async {
    try {
      await ref.read(deliveryServiceProvider).approve(a);
      if (context.mounted) _toast(context, '${a.name} approved');
    } catch (e) {
      if (context.mounted) _toast(context, 'Failed: $e');
    }
  }

  /// Asks for a reason; the reason is sent to the applicant as a notification.
  Future<void> _reject(
      BuildContext context, WidgetRef ref, DeliveryApplication a) async {
    final ctrl = TextEditingController();
    const quick = [
      'Licence photo is not clear',
      'Details do not match the licence',
      'We do not serve this area yet',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject application'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick reasons'),
              const SizedBox(height: Sp.sm),
              Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
                for (final q in quick)
                  ActionChip(label: Text(q), onPressed: () => ctrl.text = q),
              ]),
              const SizedBox(height: Sp.md),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Reason (the applicant will see this)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await ref.read(deliveryServiceProvider).reject(a, reason);
        if (context.mounted) _toast(context, 'Application rejected');
      } catch (e) {
        if (context.mounted) _toast(context, 'Failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pendingApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery requests')),
      body: list.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(e),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No pending requests',
                subtitle: 'New applications show up here live');
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(Sp.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
                itemBuilder: (_, i) => _RequestCard(
                  items[i],
                  onApprove: () => _approve(context, ref, items[i]),
                  onReject: () => _reject(context, ref, items[i]),
                )
                    .animate(delay: (60 * i.clamp(0, 6)).ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DeliveryApplication a;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _RequestCard(this.a, {required this.onApprove, required this.onReject});

  Widget _fact(IconData i, String t, {bool selectable = false}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Icon(i, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: Sp.sm),
          Expanded(child: selectable ? SelectableText(t) : Text(t)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final initial = a.name.isEmpty ? '?' : a.name[0].toUpperCase();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: t.colorScheme.primaryContainer,
              child: Text(initial,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Brand.primary)),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Applied ${timeAgo(a.createdAt)}',
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.outline)),
                ],
              ),
            ),
            const StatusChip('Pending', Colors.orange),
          ]),
          const Divider(height: Sp.lg),
          _fact(Icons.phone_outlined, a.phone, selectable: true),
          _fact(Icons.two_wheeler, '${a.vehicleType}  ·  ${a.vehicleNumber}'),
          _fact(Icons.badge_outlined, 'Licence: ${a.licenseNumber}'),
          _fact(Icons.location_city_outlined, a.area),
          const SizedBox(height: Sp.md),
          GestureDetector(
            onTap: () => showImagePreview(context, a.idProofUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  FoodImage(a.idProofUrl),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Tap to zoom',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(backgroundColor: Brand.success),
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approve'),
              ),
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300, width: 1.4),
                ),
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}