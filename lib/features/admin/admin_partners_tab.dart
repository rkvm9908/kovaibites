import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../models/delivery_application.dart';
import '../../providers/admin_providers.dart';
import '../../providers/presence_providers.dart';
import '../../widgets/app_states.dart';
import '../../widgets/image_preview.dart';
import '../../widgets/ui_kit.dart';

class PartnersTab extends ConsumerWidget {
  const PartnersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(partnersProvider);
    final online = ref.watch(onlineDeliveryProvider).value ?? {};

    return list.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(e),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
              icon: Icons.delivery_dining,
              title: 'No approved partners yet',
              subtitle: 'Approved applicants will appear here');
        }
        final onlineCount = items
            .where((a) => online[a.uid] != null && isFresh(online[a.uid]!))
            .length;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(Sp.md),
              children: [
                // Summary strip
                AppCard(
                  child: Row(children: [
                    const IconBadge(Icons.two_wheeler, color: Colors.indigo),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${items.length} partners',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('$onlineCount online right now',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ]),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: Sp.md),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.md),
                    child: _PartnerCard(
                      items[i],
                      online[items[i].uid] != null &&
                          isFresh(online[items[i].uid]!),
                    )
                        .animate(delay: (60 * i.clamp(0, 6)).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, end: 0),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PartnerCard extends ConsumerWidget {
  final DeliveryApplication a;
  final bool online;
  const _PartnerCard(this.a, this.online);

  Widget _fact(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Brand.cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 5),
          Text(t, style: const TextStyle(fontSize: 12)),
        ]),
      );

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${a.name}?'),
        content: const Text(
            'Delivery access will be revoked and the partner will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await ref.read(adminServiceProvider).removePartner(a.uid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final done = ref.watch(deliveredCountProvider(a.uid)).value;
    final initial = a.name.isEmpty ? '?' : a.name[0].toUpperCase();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Avatar with a pulsing dot while the partner is online.
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: t.colorScheme.primaryContainer,
                child: Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Brand.primary)),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: online ? Brand.success : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                )
                    .animate(
                        key: ValueKey(online),
                        onPlay: (c) => online ? c.repeat(reverse: true) : c.stop())
                    .scaleXY(begin: 0.85, end: 1.2, duration: 800.ms),
              ),
            ]),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(a.area,
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.outline)),
                ],
              ),
            ),
            StatusChip(online ? 'Online' : 'Offline',
                online ? Brand.success : Colors.grey),
          ]),
          const SizedBox(height: Sp.md),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            _fact(Icons.phone_outlined, a.phone),
            _fact(Icons.two_wheeler, '${a.vehicleType} · ${a.vehicleNumber}'),
            _fact(Icons.badge_outlined, a.licenseNumber),
          ]),
          const SizedBox(height: Sp.md),
          Row(children: [
            const Icon(Icons.check_circle_outline,
                size: 18, color: Brand.success),
            const SizedBox(width: 6),
            Text('Deliveries completed: ',
                style: t.textTheme.bodyMedium),
            if (done == null)
              const Text('...')
            else
              CountUp(done,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: Sp.md),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: const Text('Licence'),
              onPressed: () => showImagePreview(context, a.idProofUrl),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              onPressed: () => showDialog(
                  context: context, builder: (_) => _EditPartnerDialog(a)),
            ),
            TextButton.icon(
              onPressed: () => _remove(context, ref),
              icon: Icon(Icons.person_remove_outlined,
                  size: 18, color: Colors.red.shade700),
              label: Text('Remove',
                  style: TextStyle(color: Colors.red.shade700)),
            ),
          ]),
        ],
      ),
    );
  }
}

// =============================================================================
// Edit partner dialog
// =============================================================================
class _EditPartnerDialog extends ConsumerStatefulWidget {
  final DeliveryApplication a;
  const _EditPartnerDialog(this.a);

  @override
  ConsumerState<_EditPartnerDialog> createState() => _EditState();
}

class _EditState extends ConsumerState<_EditPartnerDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.a.name);
  late final _phone = TextEditingController(text: widget.a.phone);
  late final _vno = TextEditingController(text: widget.a.vehicleNumber);
  late final _lic = TextEditingController(text: widget.a.licenseNumber);
  late final _area = TextEditingController(text: widget.a.area);
  late String _vehicle =
      ['Bike', 'Scooter', 'Cycle'].contains(widget.a.vehicleType)
          ? widget.a.vehicleType
          : 'Bike';
  bool _busy = false;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vno.dispose();
    _lic.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminServiceProvider).updatePartner(widget.a.uid, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicleType': _vehicle,
        'vehicleNumber': _vno.text.trim().toUpperCase(),
        'licenseNumber': _lic.text.trim().toUpperCase(),
        'area': _area.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit partner'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _req),
              const SizedBox(height: Sp.md),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) =>
                    RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                        ? null
                        : '10 digits',
              ),
              const SizedBox(height: Sp.md),
              DropdownButtonFormField<String>(
                value: _vehicle,
                decoration: const InputDecoration(labelText: 'Vehicle type'),
                items: const [
                  DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'Scooter', child: Text('Scooter')),
                  DropdownMenuItem(value: 'Cycle', child: Text('Cycle')),
                ],
                onChanged: (v) => setState(() => _vehicle = v!),
              ),
              const SizedBox(height: Sp.md),
              TextFormField(
                  controller: _vno,
                  decoration: const InputDecoration(labelText: 'Vehicle number'),
                  validator: _req),
              const SizedBox(height: Sp.md),
              TextFormField(
                  controller: _lic,
                  decoration:
                      const InputDecoration(labelText: 'Licence number'),
                  validator: _req),
              const SizedBox(height: Sp.md),
              TextFormField(
                  controller: _area,
                  decoration: const InputDecoration(labelText: 'Work area'),
                  validator: _req),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}