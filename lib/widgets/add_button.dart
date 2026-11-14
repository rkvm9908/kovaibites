import 'package:flutter/material.dart';
import '../core/design.dart';
import 'qty_stepper.dart';

/// "ADD" pill that morphs into a quantity stepper once the item is in the cart.
class AddButton extends StatelessWidget {
  final int qty;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const AddButton({
    super.key,
    required this.qty,
    required this.enabled,
    required this.onAdd,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: qty == 0
          ? _AddPill(key: const ValueKey('add'), enabled: enabled, onTap: onAdd)
          : QtyStepper(
              key: const ValueKey('qty'),
              qty: qty,
              onAdd: onIncrement,
              onRemove: onRemove,
            ),
    );
  }
}

class _AddPill extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _AddPill({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Brand.primary : Colors.grey;
    return SizedBox(
      width: 96,
      height: 36,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.6), width: 1.4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ADD',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
                const SizedBox(width: 2),
                Icon(Icons.add, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}