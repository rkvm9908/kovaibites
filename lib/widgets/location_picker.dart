import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/design.dart';
import '../services/location_service.dart';
import 'osm.dart';
import 'ui_kit.dart';

/// Opens a map dialog and returns the chosen point (null if cancelled).
Future<LatLng?> pickLocation(BuildContext context, {LatLng? initial}) =>
    showDialog<LatLng>(
        context: context, builder: (_) => _LocationPickerDialog(initial));

class _LocationPickerDialog extends StatefulWidget {
  final LatLng? initial;
  const _LocationPickerDialog(this.initial);

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final _map = MapController();
  late LatLng _pin = widget.initial ?? coimbatore;
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final p = await getCurrentLatLng();
      if (!mounted) return;
      setState(() => _pin = p);
      _map.move(p, 17);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h =
        (MediaQuery.of(context).size.height * 0.8).clamp(380.0, 620.0).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 640,
        height: h,
        child: Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(children: [
            Row(children: [
              const IconBadge(Icons.place, size: 38),
              const SizedBox(width: Sp.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose location',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    Text('Tap the map to move the pin',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: Sp.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.lg),
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: widget.initial == null ? 12 : 16,
                    onTap: (_, p) => setState(() => _pin = p),
                  ),
                  children: [
                    osmTiles(),
                    MarkerLayer(markers: [
                      Marker(
                        point: _pin,
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        // The key restarts the bounce every time the pin moves.
                        child: const Icon(Icons.location_on,
                                color: Colors.red, size: 48)
                            .animate(key: ValueKey(_pin))
                            .moveY(
                                begin: -16,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.bounceOut),
                      ),
                    ]),
                    osmAttribution(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.sm),
            Text(
                '${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Sp.sm),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('My location'),
              ),
              const Spacer(),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const SizedBox(width: Sp.sm),
              FilledButton(
                  onPressed: () => Navigator.pop(context, _pin),
                  child: const Text('Confirm')),
            ]),
          ]),
        ),
      ),
    );
  }
}