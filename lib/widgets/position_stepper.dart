import 'package:flutter/material.dart';

class StepperCtrl extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? label;

  const StepperCtrl({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 999,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (label != null) ...[
        Text(label!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        const SizedBox(width: 8),
      ],
      _btn(context, Icons.remove, value > min ? () => onChanged(value - 1) : null, cs),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$value', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface)),
      ),
      _btn(context, Icons.add, value < max ? () => onChanged(value + 1) : null, cs),
    ]);
  }

  Widget _btn(BuildContext ctx, IconData icon, VoidCallback? onTap, ColorScheme cs) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18,
          color: onTap != null ? cs.primary : cs.onSurface.withOpacity(0.3)),
      ),
    );
  }
}
