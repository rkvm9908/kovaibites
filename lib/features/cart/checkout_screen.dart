import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/design.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_providers.dart';
import '../../providers/order_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/osm.dart';
import '../../widgets/ui_kit.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  LatLng? _loc;
  bool _locating = false;
  bool _loading = false;

  // Set once the order is saved so the empty-cart view does not flash
  // while the screen transitions away.
  bool _placed = false;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _share() async {
    setState(() => _locating = true);
    try {
      final p = await getCurrentLatLng();
      if (mounted) setState(() => _loc = p);
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final p = await pickLocation(context, initial: _loc);
    if (p != null && mounted) setState(() => _loc = p);
  }

  Future<void> _place() async {
    if (!_formKey.currentState!.validate()) return;
    if (_address.text.trim().isEmpty && _loc == null) {
      _toast('Please share your location or type an address');
      return;
    }

    final cart = ref.read(cartProvider);
    final user = ref.read(currentUserProvider).value;
    if (cart.isEmpty || user == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(orderServiceProvider).placeOrder(
            userId: user.uid,
            userName: user.name,
            cart: cart,
            address: _address.text.trim().isEmpty
                ? 'Shared location'
                : _address.text.trim(),
            phone: _phone.text.trim(),
            note: _note.text.trim(),
            lat: _loc?.latitude,
            lng: _loc?.longitude,
          );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );
      if (!mounted) return;

      _placed = true;
      ref.read(cartProvider.notifier).clear();
      context.go('/orders');
    } catch (e) {
      if (mounted) _toast('Order failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final t = Theme.of(context);

    if (cart.isEmpty && !_placed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyState(
            icon: Icons.shopping_cart_outlined, title: 'Your cart is empty'),
      );
    }

    final sections = <Widget>[
      const SectionTitle('Delivery location'),
      _locationCard(t),
      const SizedBox(height: Sp.md),
      TextFormField(
        controller: _address,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Address / landmark (optional)',
          hintText: 'Door no, street, landmark',
          prefixIcon: Icon(Icons.home_outlined),
        ),
      ),
      const SectionTitle('Contact'),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone number',
          prefixText: '+91 ',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
            ? null
            : 'Enter a valid 10-digit number',
      ),
      const SizedBox(height: Sp.md),
      TextFormField(
        controller: _note,
        decoration: const InputDecoration(
          labelText: 'Note for the restaurant (optional)',
          prefixIcon: Icon(Icons.sticky_note_2_outlined),
        ),
      ),
      const SectionTitle('Payment'),
      AppCard(
        child: Row(children: [
          const IconBadge(Icons.payments_outlined, color: Brand.success),
          const SizedBox(width: Sp.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash on Delivery',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Pay when your order arrives',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Brand.success),
        ]),
      ),
      const SectionTitle('Order summary'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cart.restaurantName,
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.sm),
            for (final l in cart.lines.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(child: Text('${l.qty} x ${l.item.name}')),
                  Text('₹${(l.item.price * l.qty).toStringAsFixed(0)}'),
                ]),
              ),
            const Divider(height: Sp.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery fee'),
                Text('₹${cart.total - cart.subtotal}'.replaceAll('.0', '')),
              ],
            ),
            const SizedBox(height: Sp.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('To pay',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('₹${cart.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: Sp.lg),
      GradientButton(
        label: 'Place order  ·  ₹${cart.total.toStringAsFixed(0)}',
        icon: Icons.check_circle_outline,
        loading: _loading,
        onPressed: _place,
      ),
      const SizedBox(height: Sp.xl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(Sp.md),
              children: [
                for (var i = 0; i < sections.length; i++)
                  sections[i]
                      .animate(delay: (35 * i.clamp(0, 10)).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Location card: shows a live map preview once a location is chosen.
  Widget _locationCard(ThemeData t) {
    final loc = _loc;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconBadge(Icons.my_location,
                color: loc == null ? Colors.grey : Brand.success),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc == null ? 'Share your exact location' : 'Location pinned',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    loc == null
                        ? 'Helps the rider find you faster'
                        : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ]),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: Curves.easeOutCubic,
            child: loc == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Sp.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.md),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          key: ValueKey('${loc.latitude},${loc.longitude}'),
                          options: MapOptions(
                            initialCenter: loc,
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none),
                          ),
                          children: [
                            osmTiles(),
                            MarkerLayer(markers: [
                              Marker(
                                point: loc,
                                width: 40,
                                height: 40,
                                alignment: Alignment.topCenter,
                                child: const Icon(Icons.location_on,
                                    color: Colors.red, size: 40),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: Sp.md),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            FilledButton.tonalIcon(
              onPressed: _locating ? null : _share,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.gps_fixed, size: 18),
              label: Text(loc == null ? 'Use current location' : 'Update'),
            ),
            OutlinedButton.icon(
              onPressed: _pickOnMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Pick on map'),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Animated "order placed" popup. Closes itself after a short delay.
class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                  color: Brand.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ).animate().scaleXY(
                begin: 0, end: 1, duration: 700.ms, curve: Curves.elasticOut),
            const SizedBox(height: Sp.lg),
            const Text('Order placed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))
                .animate()
                .fadeIn(delay: 250.ms),
            const SizedBox(height: Sp.xs),
            const Text('The restaurant will confirm it shortly',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey))
                .animate()
                .fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}