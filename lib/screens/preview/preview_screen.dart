import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';
import '../../providers/operations_provider.dart';
import '../../operations/rename_engine.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});
  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _running = false;
  int _done = 0;
  int _total = 0;
  final List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final selected = fp.selectedItems;
    final results = RenameEngine.applyAll(
        selected.map((f) => f.name).toList(), op.config);
    final changeCount = results.where((r) => r.hasChange).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: const Text('المخرجات والمعاينة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        // Output options
        Container(
          padding: const EdgeInsets.all(14),
          color: cs.surfaceContainerHighest,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نوع العملية:', style: TextStyle(
                fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _outCard(
                context, 'استبدال الأصل', Icons.swap_horiz,
                'إعادة تسمية الملفات في مكانها',
                fp.deleteOriginal, () => fp.setDeleteOriginal(true), cs)),
              const SizedBox(width: 8),
              Expanded(child: _outCard(
                context, 'نسخ وتسمية', Icons.copy,
                'إنشاء نسخ مع الاسم الجديد',
                !fp.deleteOriginal, () => fp.setDeleteOriginal(false), cs)),
            ]),
            if (!fp.deleteOriginal) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(fp.outputPath ?? 'نفس مجلد الملفات الأصلية',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('تغيير'),
                ),
              ]),
            ],
          ]),
        ),
        // Summary
        if (selected.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: changeCount > 0 ? cs.primaryContainer : cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(changeCount > 0 ? Icons.check_circle_outline : Icons.info_outline,
                  color: changeCount > 0 ? cs.primary : cs.error),
              const SizedBox(width: 10),
              Text(
                changeCount > 0
                    ? '$changeCount من ${selected.length} ملف سيتغير اسمه'
                    : selected.isEmpty ? 'اختر ملفات أولاً من الشاشة الأولى'
                        : 'لا تغييرات — فعّل خياراً من الشاشة الثانية',
                style: TextStyle(fontWeight: FontWeight.w500,
                    color: changeCount > 0 ? cs.onPrimaryContainer : cs.onErrorContainer),
              ),
            ]),
          ),
        // Preview list label
        if (selected.isNotEmpty) Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(children: [
            Text('معاينة: ', style: TextStyle(
                fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text('${selected.length} ملف', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        ),
        // Preview list
        Expanded(
          child: selected.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.preview, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  const Text('اختر ملفات من الشاشة الأولى'),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      title: Text(r.originalName,
                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      subtitle: r.hasChange
                          ? Row(children: [
                              Icon(Icons.subdirectory_arrow_right, size: 14, color: cs.primary),
                              const SizedBox(width: 4),
                              Expanded(child: Text(r.newName, style: TextStyle(
                                  color: cs.primary, fontWeight: FontWeight.w500,
                                  fontSize: 13))),
                            ])
                          : Text('بدون تغيير',
                              style: TextStyle(fontSize: 12, color: cs.outlineVariant)),
                    );
                  },
                ),
        ),
        // Execute
        if (_running)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              LinearProgressIndicator(value: _total > 0 ? _done / _total : null),
              const SizedBox(height: 8),
              Text('جارٍ إعادة التسمية... $_done / $_total'),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: FilledButton.icon(
              onPressed: changeCount > 0
                  ? () => _execute(context,
                      selected.map((f) => f.file).toList(), op, fp)
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text('بدء إعادة التسمية ($changeCount ملف)'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ),
      ]),
    );
  }

  Widget _outCard(BuildContext ctx, String title, IconData icon, String desc,
      bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: selected ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: selected ? cs.primary : cs.onSurface)),
          Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Future<void> _execute(BuildContext context, List<File> files,
      OperationsProvider op, FilesProvider fp) async {
    setState(() { _running = true; _done = 0; _total = files.length; _errors.clear(); });
    await RenameEngine.executeRename(
      files: files, cfg: op.config,
      outputDir: fp.deleteOriginal ? null : fp.outputPath,
      deleteOriginal: fp.deleteOriginal,
      onProgress: (d, t) => setState(() { _done = d; _total = t; }),
      onError: (e) => setState(() => _errors.add(e)),
    );
    setState(() => _running = false);
    await fp.loadDirectory(fp.currentPath);
    if (!context.mounted) return;
    _showResult(context);
  }

  void _showResult(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('اكتملت العملية'),
      content: Text(_errors.isEmpty
          ? 'تمت إعادة تسمية $_done ملف بنجاح ✅'
          : 'تم: $_done ملف\nأخطاء (${_errors.length}):\n${_errors.take(5).join('\n')}'),
      actions: [TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('موافق'))],
    ));
  }
}
