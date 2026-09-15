import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/operation_config.dart';
import '../../widgets/section_card.dart';
import '../../widgets/position_stepper.dart';

class AddTab extends StatelessWidget {
  const AddTab({super.key});

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final c = op.config;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── بادئة ──────────────────────────────────────────────
        SectionCard(
          title: 'إضافة بادئة', icon: Icons.text_fields,
          enabled: c.prefix.enabled,
          onToggle: (v) => op.updatePrefix(enabled: v),
          child: Column(children: [
            TextField(
              decoration: const InputDecoration(labelText: 'النص', hintText: 'مثال: رحلة_'),
              onChanged: (v) => op.updatePrefix(text: v),
              controller: TextEditingController(text: c.prefix.text)
                ..selection = TextSelection.collapsed(offset: c.prefix.text.length),
            ),
          ]),
        ),
        // ── لاحقة ──────────────────────────────────────────────
        SectionCard(
          title: 'إضافة لاحقة', icon: Icons.text_rotate_vertical,
          enabled: c.suffix.enabled,
          onToggle: (v) => op.updateSuffix(enabled: v),
          child: TextField(
            decoration: const InputDecoration(labelText: 'النص', hintText: 'مثال: _نسخة'),
            onChanged: (v) => op.updateSuffix(text: v),
            controller: TextEditingController(text: c.suffix.text)
              ..selection = TextSelection.collapsed(offset: c.suffix.text.length),
          ),
        ),
        // ── إضافة في موضع محدد ─────────────────────────────────
        SectionCard(
          title: 'إضافة في موضع محدد', icon: Icons.vertical_align_center,
          enabled: c.addAtPosition.enabled,
          onToggle: (v) => op.updateAddAtPosition(enabled: v),
          child: Column(children: [
            TextField(
              decoration: const InputDecoration(labelText: 'النص المراد إدراجه'),
              onChanged: (v) => op.updateAddAtPosition(text: v),
              controller: TextEditingController(text: c.addAtPosition.text)
                ..selection = TextSelection.collapsed(offset: c.addAtPosition.text.length),
            ),
            const SizedBox(height: 16),
            PositionStepper(
              label: 'الموضع (من البداية)',
              value: c.addAtPosition.position,
              min: 0, max: 100,
              previewName: 'اسم_الملف',
              onChanged: (v) => op.updateAddAtPosition(position: v),
            ),
          ]),
        ),
        // ── تاريخ آخر تعديل ────────────────────────────────────
        SectionCard(
          title: 'إضافة تاريخ آخر تعديل', icon: Icons.calendar_today,
          enabled: c.addDate.enabled,
          onToggle: (v) => op.updateAddDate(enabled: v),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('الموضع:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              ChoiceChip(label: const Text('قبل الاسم'), selected: c.addDate.position == DatePosition.before,
                  onSelected: (_) => op.updateAddDate(position: DatePosition.before)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('بعد الاسم'), selected: c.addDate.position == DatePosition.after,
                  onSelected: (_) => op.updateAddDate(position: DatePosition.after)),
            ]),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'الفاصل', hintText: '-'),
              onChanged: (v) => op.updateAddDate(separator: v),
              controller: TextEditingController(text: c.addDate.separator),
            ),
            const SizedBox(height: 12),
            const Text('مكوّنات التاريخ:', style: TextStyle(fontSize: 14)),
            Wrap(spacing: 8, children: [
              FilterChip(label: const Text('سنة'), selected: c.addDate.year, onSelected: (v) => op.updateAddDate(year: v)),
              FilterChip(label: const Text('شهر'), selected: c.addDate.month, onSelected: (v) => op.updateAddDate(month: v)),
              FilterChip(label: const Text('يوم'), selected: c.addDate.day, onSelected: (v) => op.updateAddDate(day: v)),
              FilterChip(label: const Text('ساعة'), selected: c.addDate.hour, onSelected: (v) => op.updateAddDate(hour: v)),
              FilterChip(label: const Text('دقيقة'), selected: c.addDate.minute, onSelected: (v) => op.updateAddDate(minute: v)),
              FilterChip(label: const Text('ثانية'), selected: c.addDate.second, onSelected: (v) => op.updateAddDate(second: v)),
            ]),
          ]),
        ),
        // ── ترقيم تلقائي (اختياري) ─────────────────────────────
        SectionCard(
          title: 'ترقيم تلقائي (اختياري)', icon: Icons.format_list_numbered,
          enabled: c.autoIndex.enabled,
          onToggle: (v) => op.updateAutoIndex(enabled: v),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                const Expanded(child: Text('اختياري تماماً — لن يُجبَر عليك', style: TextStyle(fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Text('الموضع:'), const SizedBox(width: 12),
              ChoiceChip(label: const Text('قبل الاسم'), selected: c.autoIndex.position == IndexPosition.before,
                  onSelected: (_) => op.updateAutoIndex(position: IndexPosition.before)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('بعد الاسم'), selected: c.autoIndex.position == IndexPosition.after,
                  onSelected: (_) => op.updateAutoIndex(position: IndexPosition.after)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('يبدأ من:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                PositionStepper(value: c.autoIndex.startIndex, min: 0, max: 9999,
                    label: '', onChanged: (v) => op.updateAutoIndex(startIndex: v)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('الخطوة:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                PositionStepper(value: c.autoIndex.step, min: 1, max: 100,
                    label: '', onChanged: (v) => op.updateAutoIndex(step: v)),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('حشو أصفار:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                PositionStepper(value: c.autoIndex.zeroPad, min: 0, max: 10,
                    label: '', onChanged: (v) => op.updateAutoIndex(zeroPad: v)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: TextField(
                decoration: const InputDecoration(labelText: 'الفاصل', hintText: '_'),
                onChanged: (v) => op.updateAutoIndex(separator: v),
                controller: TextEditingController(text: c.autoIndex.separator),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
