import 'package:flutter/material.dart';

class PositionStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;
  final String? previewName;

  const PositionStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    required this.onChanged,
    this.label = 'الموضع',
    this.previewName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            _stepBtn(context, Icons.remove, value > min ? () => onChanged((value - 1).clamp(min, max)) : null),
            const SizedBox(width: 8),
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            _stepBtn(context, Icons.add, value < max ? () => onChanged((value + 1).clamp(min, max)) : null),
            const SizedBox(width: 12),
            if (previewName != null) Expanded(child: _preview(context, previewName!)),
          ],
        ),
      ],
    );
  }

  Widget _stepBtn(BuildContext context, IconData icon, VoidCallback? onTap) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: onTap == null ? cs.onSurface.withOpacity(0.3) : cs.primary),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    final pos = value.clamp(0, name.length);
    final before = name.substring(0, pos);
    final after = name.substring(pos);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: before, style: TextStyle(color: cs.onSurface, fontSize: 13)),
            WidgetSpan(
              child: Container(width: 2, height: 16, color: cs.primary, margin: const EdgeInsets.symmetric(horizontal: 1)),
            ),
            TextSpan(text: after, style: TextStyle(color: cs.onSurface, fontSize: 13)),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
