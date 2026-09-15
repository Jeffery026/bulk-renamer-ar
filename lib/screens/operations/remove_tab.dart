import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/operation_config.dart';
import '../../widgets/section_card.dart';
import '../../widgets/position_stepper.dart';

class RemoveTab extends StatelessWidget {
  const RemoveTab({super.key});
  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final c = op.config;
    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      SectionCard(title: 'حذف من البداية', icon: Icons.arrow_back, enabled: c.removeFromStart.enabled,
        onToggle: (v) => op.updateRemoveFromStart(enabled: v),
        child: PositionStepper(label: 'عدد الحروف المحذوفة', value: c.removeFromStart.count,
            min: 1, max: 200, previewName: 'اسم_الملف_الطويل',
            onChanged: (v) => op.updateRemoveFromStart(count: v)),
      ),
      SectionCard(title: 'حذف من النهاية', icon: Icons.arrow_forward, enabled: c.removeFromEnd.enabled,
        onToggle: (v) => op.updateRemoveFromEnd(enabled: v),
        child: PositionStepper(label: 'عدد الحروف المحذوفة', value: c.removeFromEnd.count,
            min: 1, max: 200, previewName: 'اسم_الملف_الطويل',
            onChanged: (v) => op.updateRemoveFromEnd(count: v)),
      ),
      SectionCard(title: 'حذف من موضع محدد', icon: Icons.content_cut, enabled: c.removeAtPosition.enabled,
        onToggle: (v) => op.updateRemoveAtPosition(enabled: v),
        child: Column(children: [
          PositionStepper(label: 'بداية الحذف', value: c.removeAtPosition.start,
              min: 0, max: 200, previewName: 'اسم_الملف_الطويل',
              onChanged: (v) => op.updateRemoveAtPosition(start: v)),
          const SizedBox(height: 16),
          PositionStepper(label: 'عدد الحروف المحذوفة', value: c.removeAtPosition.count,
              min: 1, max: 200, onChanged: (v) => op.updateRemoveAtPosition(count: v)),
        ]),
      ),
      SectionCard(title: 'حذف بالنوع', icon: Icons.filter_alt, enabled: c.removeByType.enabled,
        onToggle: (v) => op.updateRemoveByType(enabled: v),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in RemoveByType.values)
            ChoiceChip(
              label: Text(_typeLabel(t)),
              selected: c.removeByType.type == t,
              onSelected: (_) => op.updateRemoveByType(type: t),
            ),
        ]),
      ),
      SectionCard(title: 'حذف حروف محددة', icon: Icons.remove_circle_outline, enabled: c.removeChars.enabled,
        onToggle: (v) => op.updateRemoveChars(enabled: v),
        child: TextField(
          decoration: const InputDecoration(labelText: 'الحروف (مفصولة بفاصلة)', hintText: 'مثال: a,b,0,-'),
          onChanged: (v) => op.updateRemoveChars(chars: v),
          controller: TextEditingController(text: c.removeChars.chars)
            ..selection = TextSelection.collapsed(offset: c.removeChars.chars.length),
        ),
      ),
      SectionCard(title: 'قص المسافات', icon: Icons.space_bar, enabled: c.removeTrim.enabled,
        onToggle: (v) => op.updateRemoveTrim(enabled: v),
        child: Row(children: [
          for (final pos in TrimPosition.values) ...[
            ChoiceChip(label: Text(_trimLabel(pos)), selected: c.removeTrim.position == pos,
                onSelected: (_) => op.updateRemoveTrim(position: pos)),
            const SizedBox(width: 8),
          ],
        ]),
      ),
      SectionCard(title: 'حذف بتعبير نمطي (Regex)', icon: Icons.code, enabled: c.removeRegex.enabled,
        onToggle: (v) => op.updateRemoveRegex(enabled: v),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(labelText: 'النمط', hintText: 'مثال: [0-9]'),
            onChanged: (v) => op.updateRemoveRegex(pattern: v),
            controller: TextEditingController(text: c.removeRegex.pattern)
              ..selection = TextSelection.collapsed(offset: c.removeRegex.pattern.length),
          ),
          const SizedBox(height: 8),
          _regexHelp(context),
        ]),
      ),
      const SizedBox(height: 80),
    ]);
  }

  String _typeLabel(RemoveByType t) => const {
    RemoveByType.letters: 'حروف', RemoveByType.numbers: 'أرقام',
    RemoveByType.spaces: 'مسافات', RemoveByType.nonLetters: 'غير الحروف',
    RemoveByType.nonNumbers: 'غير الأرقام', RemoveByType.all: 'الكل',
  }[t]!;

  String _trimLabel(TrimPosition p) => const {
    TrimPosition.start: 'البداية', TrimPosition.end: 'النهاية', TrimPosition.both: 'كلاهما',
  }[p]!;

  Widget _regexHelp(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      title: const Text('دليل Regex', style: TextStyle(fontSize: 13)),
      tilePadding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('[0-9]  ← أي رقم', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('[a-z]  ← حروف صغيرة', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('[A-Z]  ← حروف كبيرة', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('\\s     ← مسافة', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('\\d+    ← أرقام متعددة', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('[^a-z] ← كل ما ليس حرفاً', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ]),
        ),
      ],
    );
  }
}
