import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config.dart';
import '../../core/design.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/multi_image_upload_field.dart';

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null;

// =============================================================================
// Menu item dialog (create / edit)
// =============================================================================
class MenuItemDialog extends ConsumerStatefulWidget {
  final String restaurantId;

  /// Null when creating a new item.
  final MenuItem? item;

  const MenuItemDialog({super.key, required this.restaurantId, this.item});

  @override
  ConsumerState<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends ConsumerState<MenuItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _desc = TextEditingController(text: widget.item?.description);
  late final _price = TextEditingController(
      text: widget.item == null ? '' : widget.item!.price.toStringAsFixed(0));
  late final _category =
      TextEditingController(text: widget.item?.category ?? 'Others');
  late bool _isVeg = widget.item?.isVeg ?? true;

  // Uploaded image URLs. The first one is used as the cover image.
  late List<String> _imgs = [...(widget.item?.images ?? [])];

  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminServiceProvider).saveMenuItem(
        widget.restaurantId,
        widget.item?.id,
        {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': double.parse(_price.text.trim()),
          'category': _category.text.trim(),
          'isVeg': _isVeg,
          // 'images' is the source of truth; 'imageUrl' is kept for older data.
          'images': _imgs,
          'imageUrl': _imgs.isEmpty ? '' : _imgs.first,
          if (widget.item == null) 'available': true,
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add menu item' : 'Edit menu item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MultiImageUploadField(
                  initial: _imgs,
                  max: maxFoodImages,
                  folder: 'menu',
                  onChanged: (l) => _imgs = l,
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _desc,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Price', prefixText: '₹ '),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                      labelText: 'Category (Tiffin, Biriyani...)'),
                  validator: _required,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Veg'),
                  value: _isVeg,
                  onChanged: (v) => setState(() => _isVeg = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// =============================================================================
// Restaurant dialog (create / edit)
// =============================================================================
class RestaurantDialog extends ConsumerStatefulWidget {
  /// Null when creating a new restaurant.
  final Restaurant? restaurant;

  const RestaurantDialog({super.key, this.restaurant});

  @override
  ConsumerState<RestaurantDialog> createState() => _RestaurantDialogState();
}

class _RestaurantDialogState extends ConsumerState<RestaurantDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.restaurant?.name);
  late final _cuisine = TextEditingController(text: widget.restaurant?.cuisine);
  late final _mins =
      TextEditingController(text: '${widget.restaurant?.deliveryMins ?? 30}');
  late final _price =
      TextEditingController(text: '${widget.restaurant?.priceForTwo ?? 300}');
  late final _rating =
      TextEditingController(text: '${widget.restaurant?.rating ?? 4.0}');

  // Optional map pin for the restaurant.
  late LatLng? _loc = widget.restaurant?.latLng;

  // Uploaded image URLs. The first one is used as the cover image.
  late List<String> _imgs = [...(widget.restaurant?.images ?? [])];

  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminServiceProvider).saveRestaurant(
        widget.restaurant?.id,
        {
          'name': _name.text.trim(),
          'cuisine': _cuisine.text.trim(),
          'deliveryMins': int.parse(_mins.text.trim()),
          'priceForTwo': int.parse(_price.text.trim()),
          'rating': double.parse(_rating.text.trim()),
          'images': _imgs,
          'imageUrl': _imgs.isEmpty ? '' : _imgs.first,
          if (_loc != null) 'lat': _loc!.latitude,
          if (_loc != null) 'lng': _loc!.longitude,
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _cuisine.dispose();
    _mins.dispose();
    _price.dispose();
    _rating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.restaurant == null ? 'New restaurant' : 'Edit restaurant'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MultiImageUploadField(
                  initial: _imgs,
                  max: maxRestaurantImages,
                  folder: 'restaurants',
                  onChanged: (l) => _imgs = l,
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _cuisine,
                  decoration: const InputDecoration(labelText: 'Cuisine'),
                  validator: _required,
                ),
                const SizedBox(height: Sp.md),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mins,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Mins'),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? 'Number' : null,
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: '₹ for two'),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? 'Number' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: Sp.md),
                Row(children: [
                  Expanded(
                    child: Text(_loc == null
                        ? 'Map location not set'
                        : 'Pin: ${_loc!.latitude.toStringAsFixed(4)}, '
                            '${_loc!.longitude.toStringAsFixed(4)}'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.place_outlined),
                    label: Text(_loc == null ? 'Set on map' : 'Change'),
                    onPressed: () async {
                      final p = await pickLocation(context, initial: _loc);
                      if (p != null) setState(() => _loc = p);
                    },
                  ),
                ]),
                const SizedBox(height: Sp.md),
                TextFormField(
                  controller: _rating,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    return (d == null || d < 0 || d > 5) ? '0 to 5' : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}