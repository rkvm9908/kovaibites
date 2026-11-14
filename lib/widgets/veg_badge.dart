import 'package:flutter/material.dart';

class VegBadge extends StatelessWidget {
  final bool isVeg;
  const VegBadge({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}