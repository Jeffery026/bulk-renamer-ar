import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget child;
  final Color? color;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onToggle,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = color ?? cs.primaryContainer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: enabled ? cs.surface : cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? cardColor : cs.outlineVariant, width: enabled ? 1.5 : 1),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => onToggle(!enabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: enabled ? cardColor : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: enabled ? cs.onPrimaryContainer : cs.onSurfaceVariant, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
                  const Spacer(),
                  Switch(value: enabled, onChanged: onToggle),
                ],
              ),
            ),
          ),
          if (enabled) ...[
            Divider(height: 1, color: cardColor),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ],
      ),
    );
  }
}
