import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const coimbatore = LatLng(11.0168, 76.9558);

Future<LatLng> getCurrentLatLng() async {
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw 'Location permission kudunga (browser settings-la allow pannunga)';
  }
  final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  return LatLng(p.latitude, p.longitude);
}

/// Free: API key venaam, Google Maps app/web open aagum
Future<void> openDirections(LatLng p) => launchUrl(
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}'),
      mode: LaunchMode.externalApplication,
    );