import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/operation_config.dart';
import '../../operations/rename_engine.dart';
import '../../widgets/section_card.dart';
import '../../widgets/position_stepper.dart';

enum _Cat { all, change, add, remove }

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  _Cat _cat = _Cat.all;
  int _cfgVersion = 0;
  final _sampleName = 'صورة_اختبار.jpg';
  final _saveCtrl = TextEditingController();

  bool get _showChange => _cat == _Cat.all || _cat == _Cat.change;
  bool get _showAdd => _cat == _Cat.all || _cat == _Cat.add;
  bool get _showRemove => _cat == _Cat.all || _cat == _Cat.remove;

  @override
  void dispose() { _saveCtrl.dispose(); super.dispose(); }

  void _loadCfg(String name) async {
    await context.read<OperationsProvider>().loadConfig(name);
    setState(() => _cfgVersion++);
  }

  void _showSaveDialog() {
    _saveCtrl.clear();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('حفظ الإعداد'),
      content: TextField(controller: _saveCtrl,
        decoration: const InputDecoration(labelText: 'اسم الإعداد', hintText: 'مثال: إعادة تسمية الصور')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () async {
            if (_saveCtrl.text.trim().isEmpty) return;
            await context.read<OperationsProvider>().saveConfig(_saveCtrl.text.trim());
            if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم الحفظ ✅'), behavior: SnackBarBehavior.floating)); }
          },
          child: const Text('حفظ'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final c = op.config;

    const chColor = Color(0xFF006B5C);
    const addColor = Color(0xFF2E7D32);
    const remColor = Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: const Text('خيارات إعادة التسمية',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'إعادة ضبط',
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text('إعادة الضبط'),
              content: const Text('هل تريد مسح كل الخيارات؟'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                FilledButton(onPressed: () { op.resetAll(); setState(() => _cfgVersion++); Navigator.pop(context); }, child: const Text('مسح')),
              ],
            ))),
        ],
      ),
      body: Column(children: [
        // Config bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: cs.surfaceContainerHighest,
          child: Row(children: [
            Expanded(child: op.savedConfigNames.isEmpty
              ? const Text('لا توجد إعدادات محفوظة', style: TextStyle(fontSize: 13))
              : DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('تحميل إعداد محفوظ'),
                  underline: const SizedBox(),
                  items: op.savedConfigNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (n) { if (n != null) _loadCfg(n); },
                )),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _showSaveDialog,
              icon: const Icon(Icons.bookmark_add, size: 16),
              label: const Text('حفظ'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ]),
        ),
        // Category filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: cs.surface,
          child: Row(children: [
            _catBtn('الكل', _Cat.all, cs.primary, cs),
            const SizedBox(width: 6),
            _catBtn('تغيير', _Cat.change, chColor, cs),
            const SizedBox(width: 6),
            _catBtn('إضافة', _Cat.add, addColor, cs),
            const SizedBox(width: 6),
            _catBtn('حذف', _Cat.remove, remColor, cs),
          ]),
        ),
        // Operations scroll
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey(_cfgVersion),
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── تغيير ──────────────────────────────────────────
              if (_showChange) ...[
                _header('تغيير', chColor),
                OpSection(title: 'تغيير الاسم الأساسي', labelColor: chColor,
                  enabled: c.changeBaseName.enabled,
                  onToggle: (v) => op.updateChangeBaseName(enabled: v),
                  child: TxtField(initial: c.changeBaseName.newName,
                    label: 'الاسم الجديد', hint: 'اسم موحد لكل الملفات',
                    onChanged: (v) => op.updateChangeBaseName(newName: v))),
                OpSection(title: 'ترقيم تلقائي (اختياري)', labelColor: chColor,
                  enabled: c.autoIndex.enabled,
                  onToggle: (v) => op.updateAutoIndex(enabled: v),
                  child: _autoIndexCard(c, op, cs)),
                OpSection(title: 'حالة الأحرف', labelColor: chColor,
                  enabled: c.changeCase.enabled,
                  onToggle: (v) => op.updateChangeCase(enabled: v),
                  child: Column(children: [
                    for (final t in CaseType.values)
                      RadioListTile<CaseType>(
                        title: Text(_caseLabel(t)), value: t,
                        groupValue: c.changeCase.type, dense: true,
                        onChanged: (v) => op.updateChangeCase(type: v!)),
                  ])),
                OpSection(title: 'تغيير الامتداد', labelColor: chColor,
                  enabled: c.changeExtension.enabled,
                  onToggle: (v) => op.updateChangeExtension(enabled: v),
                  child: TxtField(initial: c.changeExtension.newExtension,
                    label: 'الامتداد الجديد', hint: 'jpg — اتركه فارغاً للحذف',
                    onChanged: (v) => op.updateChangeExtension(newExtension: v))),
              ],
              // ── إضافة ──────────────────────────────────────────
              if (_showAdd) ...[
                _header('إضافة', addColor),
                OpSection(title: 'إضافة بادئة', labelColor: addColor,
                  enabled: c.prefix.enabled,
                  onToggle: (v) => op.updatePrefix(enabled: v),
                  child: TxtField(initial: c.prefix.text,
                    label: 'النص', hint: 'مثال: رحلة_',
                    onChanged: (v) => op.updatePrefix(text: v))),
                OpSection(title: 'إضافة لاحقة', labelColor: addColor,
                  enabled: c.suffix.enabled,
                  onToggle: (v) => op.updateSuffix(enabled: v),
                  child: TxtField(initial: c.suffix.text,
                    label: 'النص', hint: 'مثال: _نسخة',
                    onChanged: (v) => op.updateSuffix(text: v))),
                OpSection(title: 'إضافة في موضع محدد', labelColor: addColor,
                  enabled: c.addAtPosition.enabled,
                  onToggle: (v) => op.updateAddAtPosition(enabled: v),
                  child: _addAtPosCard(c, op, cs)),
                OpSection(title: 'إضافة تاريخ آخر تعديل', labelColor: addColor,
                  enabled: c.addDate.enabled,
                  onToggle: (v) => op.updateAddDate(enabled: v),
                  child: _dateCard(c, op, cs)),
              ],
              // ── حذف واستبدال ────────────────────────────────────
              if (_showRemove) ...[
                _header('حذف واستبدال', remColor),
                OpSection(title: 'قص المسافات', labelColor: remColor,
                  enabled: c.removeTrim.enabled,
                  onToggle: (v) => op.updateRemoveTrim(enabled: v),
                  child: Column(children: [
                    RadioListTile<TrimPosition>(
                      title: const Text('من البداية والنهاية'), dense: true,
                      value: TrimPosition.both, groupValue: c.removeTrim.position,
                      onChanged: (v) => op.updateRemoveTrim(position: v!)),
                    RadioListTile<TrimPosition>(
                      title: const Text('إزالة جميع المسافات'), dense: true,
                      value: TrimPosition.start, groupValue: c.removeTrim.position,
                      onChanged: (v) => op.updateRemoveTrim(position: v!)),
                  ])),
                OpSection(title: 'حذف حروف أو كلمة', labelColor: remColor,
                  enabled: c.removeChars.enabled,
                  onToggle: (v) => op.updateRemoveChars(enabled: v),
                  child: TxtField(initial: c.removeChars.chars,
                    label: 'الحروف (مفصولة بفاصلة)', hint: 'مثال: a, 3, |, -',
                    onChanged: (v) => op.updateRemoveChars(chars: v))),
                OpSection(title: 'حذف بالنوع', labelColor: remColor,
                  enabled: c.removeByType.enabled,
                  onToggle: (v) => op.updateRemoveByType(enabled: v),
                  child: Column(children: [
                    for (final t in [RemoveByType.numbers, RemoveByType.letters,
                        RemoveByType.nonNumbers, RemoveByType.nonLetters, RemoveByType.spaces])
                      RadioListTile<RemoveByType>(
                        title: Text(_typeLabel(t)), dense: true,
                        value: t, groupValue: c.removeByType.type,
                        onChanged: (v) => op.updateRemoveByType(type: v!)),
                  ])),
                OpSection(title: 'حذف من البداية', labelColor: remColor,
                  enabled: c.removeFromStart.enabled,
                  onToggle: (v) => op.updateRemoveFromStart(enabled: v),
                  child: Row(children: [
                    const Text('عدد الحروف:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    StepperCtrl(value: c.removeFromStart.count, min: 1, max: 200,
                      onChanged: (v) => op.updateRemoveFromStart(count: v)),
                  ])),
                OpSection(title: 'حذف من النهاية', labelColor: remColor,
                  enabled: c.removeFromEnd.enabled,
                  onToggle: (v) => op.updateRemoveFromEnd(enabled: v),
                  child: Row(children: [
                    const Text('عدد الحروف:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    StepperCtrl(value: c.removeFromEnd.count, min: 1, max: 200,
                      onChanged: (v) => op.updateRemoveFromEnd(count: v)),
                  ])),
                OpSection(title: 'حذف من موضع محدد', labelColor: remColor,
                  enabled: c.removeAtPosition.enabled,
                  onToggle: (v) => op.updateRemoveAtPosition(enabled: v),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('من الموضع:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      StepperCtrl(value: c.removeAtPosition.start, min: 0, max: 999,
                        onChanged: (v) => op.updateRemoveAtPosition(start: v)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Text('عدد الحروف:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      StepperCtrl(value: c.removeAtPosition.count, min: 1, max: 200,
                        onChanged: (v) => op.updateRemoveAtPosition(count: v)),
                    ]),
                  ])),
                OpSection(title: 'حذف بتعبير نمطي Regex', labelColor: remColor,
                  enabled: c.removeRegex.enabled,
                  onToggle: (v) => op.updateRemoveRegex(enabled: v),
                  child: TxtField(initial: c.removeRegex.pattern,
                    label: 'النمط', hint: 'مثال: [0-9]',
                    onChanged: (v) => op.updateRemoveRegex(pattern: v))),
                OpSection(title: 'استبدال نص', labelColor: remColor,
                  enabled: c.replaceText.enabled,
                  onToggle: (v) => op.updateReplaceText(enabled: v),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TxtField(initial: c.replaceText.find,
                        label: 'القديم', hint: 'old',
                        onChanged: (v) => op.updateReplaceText(find: v))),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_back, size: 18)),
                      Expanded(child: TxtField(initial: c.replaceText.replace,
                        label: 'الجديد', hint: 'new',
                        onChanged: (v) => op.updateReplaceText(replace: v))),
                    ]),
                    Row(children: [
                      Checkbox(value: c.replaceText.caseSensitive,
                        onChanged: (v) => op.updateReplaceText(caseSensitive: v ?? false)),
                      const Text('حساس لحالة الأحرف', style: TextStyle(fontSize: 13)),
                    ]),
                  ])),
                OpSection(title: 'استبدال بـ Regex', labelColor: remColor,
                  enabled: c.replaceRegex.enabled,
                  onToggle: (v) => op.updateReplaceRegex(enabled: v),
                  child: Row(children: [
                    Expanded(child: TxtField(initial: c.replaceRegex.pattern,
                      label: 'النمط', hint: 'pattern',
                      onChanged: (v) => op.updateReplaceRegex(pattern: v))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_back, size: 18)),
                    Expanded(child: TxtField(initial: c.replaceRegex.replacement,
                      label: 'الجديد', hint: 'new',
                      onChanged: (v) => op.updateReplaceRegex(replacement: v))),
                  ])),
              ],
              const SizedBox(height: 16),
            ]),
          ),
        ),
        // Live Sample Bar
        _LiveSample(sampleName: _sampleName),
      ]),
    );
  }

  Widget _header(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(children: [
        Container(width: 4, height: 20, color: color, margin: const EdgeInsets.only(left: 8)),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.3))),
      ]),
    );
  }

  Widget _catBtn(String label, _Cat cat, Color color, ColorScheme cs) {
    final active = _cat == cat;
    return GestureDetector(
      onTap: () => setState(() => _cat = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: active ? 0 : 1),
        ),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : color,
          fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _autoIndexCard(OperationConfig c, OperationsProvider op, ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('الموضع:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 12),
        ChoiceChip(label: const Text('قبل الاسم'), selected: c.autoIndex.position == IndexPosition.before,
          onSelected: (_) => op.updateAutoIndex(position: IndexPosition.before)),
        const SizedBox(width: 6),
        ChoiceChip(label: const Text('بعد الاسم'), selected: c.autoIndex.position == IndexPosition.after,
          onSelected: (_) => op.updateAutoIndex(position: IndexPosition.after)),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('يبدأ من:', style: TextStyle(fontSize: 13)),
        StepperCtrl(value: c.autoIndex.startIndex, min: 0, max: 9999,
          onChanged: (v) => op.updateAutoIndex(startIndex: v)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('الخطوة:', style: TextStyle(fontSize: 13)),
        StepperCtrl(value: c.autoIndex.step, min: 1, max: 100,
          onChanged: (v) => op.updateAutoIndex(step: v)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('حشو أصفار:', style: TextStyle(fontSize: 13)),
        StepperCtrl(value: c.autoIndex.zeroPad, min: 0, max: 10,
          onChanged: (v) => op.updateAutoIndex(zeroPad: v)),
      ]),
      const SizedBox(height: 8),
      TxtField(initial: c.autoIndex.separator, label: 'الفاصل', hint: '_',
        onChanged: (v) => op.updateAutoIndex(separator: v)),
    ]);
  }

  Widget _addAtPosCard(OperationConfig c, OperationsProvider op, ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TxtField(initial: c.addAtPosition.text, label: 'النص المُدرَج', hint: 'مثال: _نسخة',
        onChanged: (v) => op.updateAddAtPosition(text: v)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('الموضع (من البداية):', style: TextStyle(fontSize: 13)),
        StepperCtrl(value: c.addAtPosition.position, min: 0, max: 200,
          onChanged: (v) => op.updateAddAtPosition(position: v)),
      ]),
    ]);
  }

  Widget _dateCard(OperationConfig c, OperationsProvider op, ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('الموضع:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 12),
        ChoiceChip(label: const Text('قبل'), selected: c.addDate.position == DatePosition.before,
          onSelected: (_) => op.updateAddDate(position: DatePosition.before)),
        const SizedBox(width: 6),
        ChoiceChip(label: const Text('بعد'), selected: c.addDate.position == DatePosition.after,
          onSelected: (_) => op.updateAddDate(position: DatePosition.after)),
      ]),
      const SizedBox(height: 8),
      TxtField(initial: c.addDate.separator, label: 'الفاصل', hint: '-',
        onChanged: (v) => op.updateAddDate(separator: v)),
      const SizedBox(height: 8),
      const Text('الوحدات:', style: TextStyle(fontSize: 13)),
      Wrap(spacing: 6, children: [
        FilterChip(label: const Text('سنة'), selected: c.addDate.year, onSelected: (v) => op.updateAddDate(year: v)),
        FilterChip(label: const Text('شهر'), selected: c.addDate.month, onSelected: (v) => op.updateAddDate(month: v)),
        FilterChip(label: const Text('يوم'), selected: c.addDate.day, onSelected: (v) => op.updateAddDate(day: v)),
        FilterChip(label: const Text('ساعة'), selected: c.addDate.hour, onSelected: (v) => op.updateAddDate(hour: v)),
        FilterChip(label: const Text('دقيقة'), selected: c.addDate.minute, onSelected: (v) => op.updateAddDate(minute: v)),
      ]),
    ]);
  }

  String _caseLabel(CaseType t) => const {
    CaseType.lower: 'أحرف صغيرة', CaseType.upper: 'أحرف كبيرة',
    CaseType.sentence: 'Sentence case', CaseType.title: 'Title Case', CaseType.camel: 'camelCase',
  }[t]!;

  String _typeLabel(RemoveByType t) => const {
    RemoveByType.numbers: 'إزالة الأرقام', RemoveByType.letters: 'إزالة الحروف',
    RemoveByType.spaces: 'إزالة المسافات', RemoveByType.nonNumbers: 'إزالة غير الأرقام',
    RemoveByType.nonLetters: 'إزالة غير الحروف', RemoveByType.all: 'إزالة الكل',
  }[t]!;
}

class _LiveSample extends StatelessWidget {
  final String sampleName;
  const _LiveSample({required this.sampleName});

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final result = RenameEngine.apply(sampleName, op.config, 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        border: Border(top: BorderSide(color: cs.primary.withOpacity(0.3))),
      ),
      child: Row(children: [
        Icon(Icons.visibility, size: 16, color: cs.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sampleName, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withOpacity(0.6))),
          Row(children: [
            Icon(Icons.arrow_downward, size: 12, color: cs.primary),
            const SizedBox(width: 4),
            Expanded(child: Text(result.newName, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
              overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        if (!op.config.hasAnyEnabled)
          Text('فعّل خياراً للبدء', style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withOpacity(0.5))),
      ]),
    );
  }
}
