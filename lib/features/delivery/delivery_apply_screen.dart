import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../providers/auth_providers.dart';
import '../../providers/delivery_providers.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ui_kit.dart';

class DeliveryApplyScreen extends ConsumerStatefulWidget {
  const DeliveryApplyScreen({super.key});

  @override
  ConsumerState<DeliveryApplyScreen> createState() => _State();
}

class _State extends ConsumerState<DeliveryApplyScreen> {
  final _form = GlobalKey<FormState>();

  // Pre-fill the name from the user's profile; the rest is entered manually.
  late final _name = TextEditingController(
      text: ref.read(currentUserProvider).value?.name ?? '');
  final _phone = TextEditingController();
  final _vehicleNo = TextEditingController();
  final _license = TextEditingController();
  final _area = TextEditingController();

  String _vehicle = 'Bike';
  String _idUrl = '';
  bool _busy = false;

  static const _vehicles = [
    ('Bike', Icons.two_wheeler),
    ('Scooter', Icons.electric_scooter),
    ('Cycle', Icons.pedal_bike),
  ];

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicleNo.dispose();
    _license.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    // The licence photo is mandatory so the admin can verify the applicant.
    if (_idUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload your driving licence photo')));
      return;
    }
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(deliveryServiceProvider).apply(uid, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicleType': _vehicle,
        'vehicleNumber': _vehicleNo.text.trim().toUpperCase(),
        'licenseNumber': _license.text.trim().toUpperCase(),
        'area': _area.text.trim(),
        'idProofUrl': _idUrl,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application sent! An admin will review it soon.')));
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Widget _intro() {
    Widget perk(IconData i, String t) => Expanded(
          child: Column(children: [
            Icon(i, color: Colors.white),
            const SizedBox(height: 4),
            Text(t,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        );

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
      child: Column(children: [
        const Text('🛵', style: TextStyle(fontSize: 44))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -6, end: 6, duration: 900.ms, curve: Curves.easeInOut),
        const SizedBox(height: Sp.sm),
        const Text('Ride with Kovai Bites',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Deliver meals around Coimbatore',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: Sp.md),
        Row(children: [
          perk(Icons.schedule, 'Flexible\nhours'),
          perk(Icons.near_me_outlined, 'Deliver in\nyour area'),
          perk(Icons.bolt, 'Live order\nalerts'),
        ]),
      ]),
    );
  }

  Widget _vehiclePicker() {
    return Row(children: [
      for (final v in _vehicles)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Pressable(
              onTap: () => setState(() => _vehicle = v.$1),
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: Sp.md),
                decoration: BoxDecoration(
                  color: _vehicle == v.$1
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: _vehicle == v.$1
                        ? Brand.primary
                        : Colors.grey.shade300,
                    width: _vehicle == v.$1 ? 2 : 1,
                  ),
                ),
                child: Column(children: [
                  Icon(v.$2,
                      color: _vehicle == v.$1 ? Brand.primary : Colors.grey),
                  const SizedBox(height: 4),
                  Text(v.$1,
                      style: TextStyle(
                          fontWeight: _vehicle == v.$1
                              ? FontWeight.w800
                              : FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _intro(),
      const SectionTitle('Personal details'),
      AppCard(
        child: Column(children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
            validator: _req,
          ),
          const SizedBox(height: Sp.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone',
                prefixText: '+91 ',
                prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Enter a valid 10-digit number',
          ),
          const SizedBox(height: Sp.md),
          TextFormField(
            controller: _area,
            decoration: const InputDecoration(
                labelText: 'Work area (Gandhipuram, RS Puram...)',
                prefixIcon: Icon(Icons.location_city_outlined)),
            validator: _req,
          ),
        ]),
      ),
      const SectionTitle('Vehicle'),
      AppCard(
        child: Column(children: [
          _vehiclePicker(),
          const SizedBox(height: Sp.md),
          TextFormField(
            controller: _vehicleNo,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Vehicle number (TN 66 AB 1234)',
                prefixIcon: Icon(Icons.pin_outlined)),
            validator: _req,
          ),
          const SizedBox(height: Sp.md),
          TextFormField(
            controller: _license,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Driving licence number',
                prefixIcon: Icon(Icons.badge_outlined)),
            validator: _req,
          ),
        ]),
      ),
      const SectionTitle('Driving licence photo'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageUploadField(
              initialUrl: '',
              folder: 'delivery',
              onChanged: (u) => setState(() => _idUrl = u),
            ),
            const SizedBox(height: Sp.sm),
            AnimatedSwitcher(
              duration: AppMotion.normal,
              child: _idUrl.isEmpty
                  ? Text('Upload a clear photo of the front side',
                      key: const ValueKey('hint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline))
                  : const Row(key: ValueKey('ok'), children: [
                      Icon(Icons.check_circle, color: Brand.success, size: 18),
                      SizedBox(width: 6),
                      Text('Photo uploaded',
                          style: TextStyle(
                              color: Brand.success,
                              fontWeight: FontWeight.w600)),
                    ]),
            ),
          ],
        ),
      ),
      const SizedBox(height: Sp.lg),
      GradientButton(
        label: 'Submit for approval',
        icon: Icons.send_rounded,
        loading: _busy,
        onPressed: _submit,
      ),
      const SizedBox(height: Sp.xl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery partner')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(Sp.md),
              children: [
                for (var i = 0; i < sections.length; i++)
                  sections[i]
                      .animate(delay: (45 * i.clamp(0, 8)).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}