import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/operation_config.dart';
import '../../widgets/section_card.dart';

class ChangeTab extends StatelessWidget {
  const ChangeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final c = op.config;
    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      SectionCard(title: 'تغيير الاسم الأساسي', icon: Icons.drive_file_rename_outline,
        enabled: c.changeBaseName.enabled, onToggle: (v) => op.updateChangeBaseName(enabled: v),
        child: TextField(
          decoration: const InputDecoration(labelText: 'الاسم الجديد', hintText: 'اسم موحّد لكل الملفات'),
          onChanged: (v) => op.updateChangeBaseName(newName: v),
          controller: TextEditingController(text: c.changeBaseName.newName)
            ..selection = TextSelection.collapsed(offset: c.changeBaseName.newName.length),
        ),
      ),
      SectionCard(title: 'تغيير الامتداد', icon: Icons.extension,
        enabled: c.changeExtension.enabled, onToggle: (v) => op.updateChangeExtension(enabled: v),
        child: TextField(
          decoration: const InputDecoration(labelText: 'الامتداد الجديد', hintText: 'مثال: jpg أو اتركه فارغاً للحذف'),
          onChanged: (v) => op.updateChangeExtension(newExtension: v),
          controller: TextEditingController(text: c.changeExtension.newExtension)
            ..selection = TextSelection.collapsed(offset: c.changeExtension.newExtension.length),
        ),
      ),
      SectionCard(title: 'تغيير حالة الأحرف', icon: Icons.text_format,
        enabled: c.changeCase.enabled, onToggle: (v) => op.updateChangeCase(enabled: v),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in CaseType.values)
            ChoiceChip(label: Text(_caseLabel(t)), selected: c.changeCase.type == t,
                onSelected: (_) => op.updateChangeCase(type: t)),
        ]),
      ),
      SectionCard(title: 'استبدال نص', icon: Icons.find_replace,
        enabled: c.replaceText.enabled, onToggle: (v) => op.updateReplaceText(enabled: v),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(labelText: 'البحث عن', hintText: 'النص القديم'),
            onChanged: (v) => op.updateReplaceText(find: v),
            controller: TextEditingController(text: c.replaceText.find)
              ..selection = TextSelection.collapsed(offset: c.replaceText.find.length),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'استبدال بـ', hintText: 'النص الجديد (اتركه فارغاً للحذف)'),
            onChanged: (v) => op.updateReplaceText(replace: v),
            controller: TextEditingController(text: c.replaceText.replace)
              ..selection = TextSelection.collapsed(offset: c.replaceText.replace.length),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Checkbox(value: c.replaceText.caseSensitive, onChanged: (v) => op.updateReplaceText(caseSensitive: v)),
            const Text('حساس لحالة الأحرف'),
          ]),
        ]),
      ),
      SectionCard(title: 'استبدال بتعبير نمطي (Regex)', icon: Icons.code,
        enabled: c.replaceRegex.enabled, onToggle: (v) => op.updateReplaceRegex(enabled: v),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(labelText: 'النمط', hintText: 'مثال: [0-9]+'),
            onChanged: (v) => op.updateReplaceRegex(pattern: v),
            controller: TextEditingController(text: c.replaceRegex.pattern)
              ..selection = TextSelection.collapsed(offset: c.replaceRegex.pattern.length),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'استبدال بـ', hintText: 'النص البديل'),
            onChanged: (v) => op.updateReplaceRegex(replacement: v),
            controller: TextEditingController(text: c.replaceRegex.replacement)
              ..selection = TextSelection.collapsed(offset: c.replaceRegex.replacement.length),
          ),
        ]),
      ),
      const SizedBox(height: 80),
    ]);
  }

  String _caseLabel(CaseType t) => const {
    CaseType.upper: 'كبيرة', CaseType.lower: 'صغيرة',
    CaseType.title: 'Title Case', CaseType.sentence: 'Sentence case', CaseType.camel: 'camelCase',
  }[t]!;
}
