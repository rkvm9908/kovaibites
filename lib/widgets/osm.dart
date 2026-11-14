import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

TileLayer osmTiles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.kovaibites.app',
    );

Widget osmAttribution() => const RichAttributionWidget(
      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
    );