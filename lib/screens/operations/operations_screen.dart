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
  @override State<OperationsScreen> createState() => _OS();
}

class _OS extends State<OperationsScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  _Cat _cat = _Cat.all;
  int _ver = 0;
  final _saveCtrl = TextEditingController();

  @override void dispose() { _saveCtrl.dispose(); super.dispose(); }

  bool get _sc => _cat == _Cat.all || _cat == _Cat.change;
  bool get _sa => _cat == _Cat.all || _cat == _Cat.add;
  bool get _sr => _cat == _Cat.all || _cat == _Cat.remove;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final c = op.config;

    return Column(children: [
      // Title
      Container(
        color: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(child: const Text('خيارات إعادة التسمية',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              onPressed: () => _confirmReset(context, op)),
        ]),
      ),
      // Config row
      Container(
        color: cs.surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            isExpanded: true,
            hint: Text('تحميل إعداد محفوظ...', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            items: op.savedConfigNames.map((n) =>
                DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (n) { if (n != null) { op.loadConfig(n); setState(() => _ver++); } },
          ))),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _saveDialog(context, op),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(color: cs.primary),
            ),
            child: Text('حفظ', style: TextStyle(color: cs.primary, fontSize: 13)),
          ),
        ]),
      ),
      // Category buttons (centered like original)
      Container(
        color: cs.surface,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _catBtn('تغيير', _Cat.all == _cat || _Cat.change == _cat ? _cat == _Cat.change : false,
              _cat == _Cat.change, cs),
          const SizedBox(width: 8),
          _catBtn('إضافة', _cat == _Cat.add, _cat == _Cat.add, cs),
          const SizedBox(width: 8),
          _catBtn('حذف', _cat == _Cat.remove, _cat == _Cat.remove, cs),
          const SizedBox(width: 8),
          _catBtn('الكل', _cat == _Cat.all, _cat == _Cat.all, cs),
        ]),
      ),
      const Divider(height: 1),
      // Scrollable ops
      Expanded(child: SingleChildScrollView(
        key: ValueKey(_ver),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(children: [
          if (_sc) ...[
            _hdr('تغيير', const Color(0xFF1565C0)),
            _op('تغيير الاسم الأساسي', const Color(0xFF1565C0), c.changeBaseName.enabled,
              (v) => op.updateChangeBaseName(enabled: v),
              TxtField(initial: c.changeBaseName.newName, label: 'الاسم الجديد', hint: 'اسم موحد', onChanged: (v) => op.updateChangeBaseName(newName: v))),
            _op('ترقيم تلقائي (اختياري)', const Color(0xFF1565C0), c.autoIndex.enabled,
              (v) => op.updateAutoIndex(enabled: v), _autoIdx(c, op)),
            _op('حالة الأحرف', const Color(0xFF1565C0), c.changeCase.enabled,
              (v) => op.updateChangeCase(enabled: v),
              Column(mainAxisSize: MainAxisSize.min, children: CaseType.values.map((t) =>
                RadioListTile<CaseType>(dense: true, title: Text(_caseL(t)), value: t,
                  groupValue: c.changeCase.type, onChanged: (v) => op.updateChangeCase(type: v!))).toList())),
            _op('تغيير الامتداد', const Color(0xFF1565C0), c.changeExtension.enabled,
              (v) => op.updateChangeExtension(enabled: v),
              TxtField(initial: c.changeExtension.newExtension, label: 'الامتداد الجديد', hint: 'jpg — فارغ للحذف', onChanged: (v) => op.updateChangeExtension(newExtension: v))),
          ],
          if (_sa) ...[
            _hdr('إضافة', const Color(0xFF2E7D32)),
            _op('بادئة', const Color(0xFF2E7D32), c.prefix.enabled,
              (v) => op.updatePrefix(enabled: v),
              TxtField(initial: c.prefix.text, label: 'النص', hint: 'مثال: رحلة_', onChanged: (v) => op.updatePrefix(text: v))),
            _op('لاحقة', const Color(0xFF2E7D32), c.suffix.enabled,
              (v) => op.updateSuffix(enabled: v),
              TxtField(initial: c.suffix.text, label: 'النص', hint: 'مثال: _نسخة', onChanged: (v) => op.updateSuffix(text: v))),
            _op('إضافة في موضع محدد ±', const Color(0xFF2E7D32), c.addAtPosition.enabled,
              (v) => op.updateAddAtPosition(enabled: v), _atPos(c, op)),
            _op('إضافة تاريخ آخر تعديل', const Color(0xFF2E7D32), c.addDate.enabled,
              (v) => op.updateAddDate(enabled: v), _dateCard(c, op)),
          ],
          if (_sr) ...[
            _hdr('حذف واستبدال', const Color(0xFF6A1B1B)),
            _op('قص المسافات', const Color(0xFF6A1B1B), c.removeTrim.enabled,
              (v) => op.updateRemoveTrim(enabled: v),
              Column(mainAxisSize: MainAxisSize.min, children: [
                RadioListTile<TrimPosition>(dense: true, title: const Text('بداية ونهاية'), value: TrimPosition.both, groupValue: c.removeTrim.position, onChanged: (v) => op.updateRemoveTrim(position: v!)),
                RadioListTile<TrimPosition>(dense: true, title: const Text('جميع المسافات'), value: TrimPosition.start, groupValue: c.removeTrim.position, onChanged: (v) => op.updateRemoveTrim(position: v!)),
              ])),
            _op('حذف حروف', const Color(0xFF6A1B1B), c.removeChars.enabled,
              (v) => op.updateRemoveChars(enabled: v),
              TxtField(initial: c.removeChars.chars, label: 'مفصولة بفاصلة', hint: 'مثال: a, 3, -', onChanged: (v) => op.updateRemoveChars(chars: v))),
            _op('حذف بالنوع', const Color(0xFF6A1B1B), c.removeByType.enabled,
              (v) => op.updateRemoveByType(enabled: v),
              Column(mainAxisSize: MainAxisSize.min, children: [RemoveByType.numbers, RemoveByType.letters, RemoveByType.spaces, RemoveByType.nonNumbers, RemoveByType.nonLetters]
                .map((t) => RadioListTile<RemoveByType>(dense: true, title: Text(_typeL(t)), value: t, groupValue: c.removeByType.type, onChanged: (v) => op.updateRemoveByType(type: v!))).toList())),
            _op('حذف من البداية ±', const Color(0xFF6A1B1B), c.removeFromStart.enabled,
              (v) => op.updateRemoveFromStart(enabled: v),
              Row(children: [const Text('عدد الحروف:', style: TextStyle(fontSize: 13)), const SizedBox(width: 10),
                StepperCtrl(value: c.removeFromStart.count, min: 1, max: 200, onChanged: (v) => op.updateRemoveFromStart(count: v))])),
            _op('حذف من النهاية ±', const Color(0xFF6A1B1B), c.removeFromEnd.enabled,
              (v) => op.updateRemoveFromEnd(enabled: v),
              Row(children: [const Text('عدد الحروف:', style: TextStyle(fontSize: 13)), const SizedBox(width: 10),
                StepperCtrl(value: c.removeFromEnd.count, min: 1, max: 200, onChanged: (v) => op.updateRemoveFromEnd(count: v))])),
            _op('حذف من موضع محدد ±', const Color(0xFF6A1B1B), c.removeAtPosition.enabled,
              (v) => op.updateRemoveAtPosition(enabled: v),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('من الموضع:', style: TextStyle(fontSize: 13)), StepperCtrl(value: c.removeAtPosition.start, min: 0, max: 999, onChanged: (v) => op.updateRemoveAtPosition(start: v))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('عدد الحروف:', style: TextStyle(fontSize: 13)), StepperCtrl(value: c.removeAtPosition.count, min: 1, max: 200, onChanged: (v) => op.updateRemoveAtPosition(count: v))]),
              ])),
            _op('حذف بـ Regex', const Color(0xFF6A1B1B), c.removeRegex.enabled,
              (v) => op.updateRemoveRegex(enabled: v),
              TxtField(initial: c.removeRegex.pattern, label: 'النمط', hint: 'مثال: [0-9]', onChanged: (v) => op.updateRemoveRegex(pattern: v))),
            _op('استبدال نص', const Color(0xFF6A1B1B), c.replaceText.enabled,
              (v) => op.updateReplaceText(enabled: v),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: TxtField(initial: c.replaceText.find, label: 'القديم', onChanged: (v) => op.updateReplaceText(find: v))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey)),
                  Expanded(child: TxtField(initial: c.replaceText.replace, label: 'الجديد', onChanged: (v) => op.updateReplaceText(replace: v))),
                ]),
                Row(children: [Checkbox(value: c.replaceText.caseSensitive, onChanged: (v) => op.updateReplaceText(caseSensitive: v ?? false)), const Text('حساس لحالة الأحرف', style: TextStyle(fontSize: 13))]),
              ])),
            _op('استبدال بـ Regex', const Color(0xFF6A1B1B), c.replaceRegex.enabled,
              (v) => op.updateReplaceRegex(enabled: v),
              Row(children: [
                Expanded(child: TxtField(initial: c.replaceRegex.pattern, label: 'نمط', onChanged: (v) => op.updateReplaceRegex(pattern: v))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey)),
                Expanded(child: TxtField(initial: c.replaceRegex.replacement, label: 'جديد', onChanged: (v) => op.updateReplaceRegex(replacement: v))),
              ])),
          ],
          const SizedBox(height: 16),
        ]),
      )),
      // Live sample (fixed bottom like original)
      _LiveSample(),
    ]);
  }

  Widget _hdr(String t, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
    child: Row(children: [
      Container(width: 3, height: 18, color: color, margin: const EdgeInsets.only(left: 8)),
      Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: color.withOpacity(0.2))),
    ]),
  );

  Widget _catBtn(String label, bool unused, bool active, ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cat = label == 'الكل' ? _Cat.all
              : label == 'تغيير' ? _Cat.change
              : label == 'إضافة' ? _Cat.add
              : _Cat.remove;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          border: Border.all(color: active ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: active ? cs.onPrimary : cs.onSurfaceVariant,
        )),
      ),
    );
  }

  Widget _op(String title, Color color, bool enabled, ValueChanged<bool> onToggle, Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: enabled ? 1 : 0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          InkWell(
            onTap: () => onToggle(!enabled),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(children: [
                Container(width: 3, height: 20,
                    color: enabled ? color : Colors.transparent,
                    margin: const EdgeInsets.only(left: 8)),
                Expanded(child: Text(title, style: TextStyle(
                  fontSize: 14, fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                ))),
                Switch(value: enabled, onChanged: onToggle, activeColor: color),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: enabled
                ? Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: child)
                : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }

  Widget _autoIdx(OperationConfig c, OperationsProvider op) => Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      const Text('الموضع:', style: TextStyle(fontSize: 13)), const SizedBox(width: 10),
      ChoiceChip(label: const Text('قبل الاسم'), selected: c.autoIndex.position == IndexPosition.before, onSelected: (_) => op.updateAutoIndex(position: IndexPosition.before)),
      const SizedBox(width: 6),
      ChoiceChip(label: const Text('بعد الاسم'), selected: c.autoIndex.position == IndexPosition.after, onSelected: (_) => op.updateAutoIndex(position: IndexPosition.after)),
    ]),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('يبدأ من:', style: TextStyle(fontSize: 13)), StepperCtrl(value: c.autoIndex.startIndex, min: 0, max: 9999, onChanged: (v) => op.updateAutoIndex(startIndex: v))]),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الخطوة:', style: TextStyle(fontSize: 13)), StepperCtrl(value: c.autoIndex.step, min: 1, max: 100, onChanged: (v) => op.updateAutoIndex(step: v))]),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('أصفار بادئة:', style: TextStyle(fontSize: 13)), StepperCtrl(value: c.autoIndex.zeroPad, min: 0, max: 6, onChanged: (v) => op.updateAutoIndex(zeroPad: v))]),
    const SizedBox(height: 8),
    TxtField(initial: c.autoIndex.separator, label: 'الفاصل', hint: '_', onChanged: (v) => op.updateAutoIndex(separator: v)),
  ]);

  Widget _atPos(OperationConfig c, OperationsProvider op) => Column(mainAxisSize: MainAxisSize.min, children: [
    TxtField(initial: c.addAtPosition.text, label: 'النص المُدرَج', hint: 'مثال: _نسخة', onChanged: (v) => op.updateAddAtPosition(text: v)),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('الموضع:', style: TextStyle(fontSize: 13)),
      StepperCtrl(value: c.addAtPosition.position, min: 0, max: 200, onChanged: (v) => op.updateAddAtPosition(position: v)),
    ]),
  ]);

  Widget _dateCard(OperationConfig c, OperationsProvider op) => Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      const Text('الموضع:', style: TextStyle(fontSize: 13)), const SizedBox(width: 10),
      ChoiceChip(label: const Text('قبل'), selected: c.addDate.position == DatePosition.before, onSelected: (_) => op.updateAddDate(position: DatePosition.before)),
      const SizedBox(width: 6),
      ChoiceChip(label: const Text('بعد'), selected: c.addDate.position == DatePosition.after, onSelected: (_) => op.updateAddDate(position: DatePosition.after)),
    ]),
    const SizedBox(height: 8),
    TxtField(initial: c.addDate.separator, label: 'الفاصل', hint: '-', onChanged: (v) => op.updateAddDate(separator: v)),
    const SizedBox(height: 8),
    Wrap(spacing: 6, runSpacing: 4, children: [
      FilterChip(label: const Text('سنة'), selected: c.addDate.year, onSelected: (v) => op.updateAddDate(year: v)),
      FilterChip(label: const Text('شهر'), selected: c.addDate.month, onSelected: (v) => op.updateAddDate(month: v)),
      FilterChip(label: const Text('يوم'), selected: c.addDate.day, onSelected: (v) => op.updateAddDate(day: v)),
      FilterChip(label: const Text('ساعة'), selected: c.addDate.hour, onSelected: (v) => op.updateAddDate(hour: v)),
      FilterChip(label: const Text('دقيقة'), selected: c.addDate.minute, onSelected: (v) => op.updateAddDate(minute: v)),
    ]),
  ]);

  void _confirmReset(BuildContext ctx, OperationsProvider op) => showDialog(
    context: ctx, builder: (_) => AlertDialog(
      title: const Text('إعادة الضبط'),
      content: const Text('هل تريد مسح جميع الخيارات؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () { op.resetAll(); setState(() => _ver++); Navigator.pop(ctx); }, child: const Text('مسح')),
      ],
    ));

  void _saveDialog(BuildContext ctx, OperationsProvider op) {
    _saveCtrl.clear();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('حفظ الإعداد'),
      content: TextField(controller: _saveCtrl, decoration: const InputDecoration(labelText: 'اسم الإعداد')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          if (_saveCtrl.text.trim().isEmpty) return;
          await op.saveConfig(_saveCtrl.text.trim());
          if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تم الحفظ ✅'), behavior: SnackBarBehavior.floating)); }
        }, child: const Text('حفظ')),
      ],
    ));
  }

  String _caseL(CaseType t) => const { CaseType.lower: 'أحرف صغيرة', CaseType.upper: 'أحرف كبيرة', CaseType.sentence: 'Sentence case', CaseType.title: 'Title Case', CaseType.camel: 'camelCase' }[t]!;
  String _typeL(RemoveByType t) => const { RemoveByType.numbers: 'إزالة الأرقام', RemoveByType.letters: 'إزالة الحروف', RemoveByType.spaces: 'إزالة المسافات', RemoveByType.nonNumbers: 'إزالة غير الأرقام', RemoveByType.nonLetters: 'إزالة غير الحروف', RemoveByType.all: 'إزالة الكل' }[t]!;
}

class _LiveSample extends StatelessWidget {
  const _LiveSample();
  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final result = RenameEngine.apply('صورة_اختبار.jpg', op.config, 0);
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Icon(Icons.u_turn_left_rounded, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('صورة_اختبار.jpg',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text(result.newName, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: result.hasChange ? cs.primary : cs.onSurfaceVariant,
          )),
        ])),
        Text('معاينة حية', style: TextStyle(fontSize: 11, color: cs.outlineVariant)),
      ]),
    );
  }
}
