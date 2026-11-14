import 'package:flutter/material.dart';
import '../core/design.dart';

/// Compact "- 2 +" control with an animated counter.
class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double width;

  const QtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.width = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: Material(
        color: Brand.primary,
        elevation: 2,
        shadowColor: Brand.primary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Btn(Icons.remove, onRemove),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim, child: FadeTransition(opacity: anim, child: child)),
              child: Text('$qty',
                  key: ValueKey(qty),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            _Btn(Icons.add, onAdd),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 36,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      );
}