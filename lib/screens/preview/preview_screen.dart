import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';
import '../../providers/operations_provider.dart';
import '../../operations/rename_engine.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});
  @override
  State<PreviewScreen> createState() => _PS();
}

class _PS extends State<PreviewScreen> {
  bool _running = false;
  int _done = 0, _total = 0;
  final List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;

    final files = fp.selectedFiles;
    final names = files.map((f) => f.path.split('/').last).toList();
    final results = RenameEngine.applyAll(names, op.config);
    final changes = results.where((r) => r.hasChange).length;

    return Column(children: [
      // ── Title ─────────────────────────────────────────────
      Container(
        color: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(child: Text('اختيار المخرجات',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
      ),
      // ── Output card ───────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  fp.outputPath ?? 'غير محدد',
                  style: TextStyle(fontSize: 14, color: fp.outputPath != null ? cs.onSurface : cs.onSurfaceVariant),
                )),
                const SizedBox(width: 8),
                SizedBox(height: 30,
                  child: FilledButton(
                    onPressed: () => _pickFolder(context, fp),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('اختيار'),
                  ),
                ),
              ]),
              Divider(color: cs.outlineVariant),
              Row(children: [
                Expanded(child: RadioListTile<bool>(
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: const Text('الاحتفاظ بالقديم', style: TextStyle(fontSize: 13)),
                  value: false, groupValue: fp.deleteOriginal,
                  onChanged: (v) => fp.setDeleteOriginal(false),
                )),
                Expanded(child: RadioListTile<bool>(
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: const Text('حذف القديم', style: TextStyle(fontSize: 13)),
                  value: true, groupValue: fp.deleteOriginal,
                  onChanged: (v) => fp.setDeleteOriginal(true),
                )),
              ]),
              if (fp.outputPath == null && !fp.deleteOriginal)
                Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 6),
                  Text('لم يتم اختيار مجلد. سيُستخدم نفس مجلد الملف.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
            ]),
          ),
        ),
      ),
      // ── Preview label ─────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          Text('إعادة التسمية:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
          const SizedBox(width: 8),
          Text(files.isEmpty ? '0 ملف' : '$changes تغيير من ${files.length}',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Icon(Icons.sort_rounded, size: 22, color: cs.onSurfaceVariant),
        ]),
      ),
      // ── Preview list ──────────────────────────────────────
      Expanded(child: files.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text('اختر ملفات من الشاشة الأولى',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ]))
          : Card(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final r = results[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.originalName,
                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                      if (r.hasChange) Row(children: [
                        Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(r.newName,
                            style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                      ]) else
                        Text('← بدون تغيير',
                            style: TextStyle(fontSize: 11, color: cs.outlineVariant)),
                    ]),
                  );
                },
              ),
            )),
      // ── Execute button (centered like original) ───────────
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _running
            ? Column(children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(value: _total > 0 ? _done / _total : null,
                      borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 6),
                Text('$_done من $_total ...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ])
            : SizedBox(
                width: 180, height: 44,
                child: FilledButton(
                  onPressed: changes > 0
                      ? () => _execute(context, files, op, fp)
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text('بدء ($changes ملف)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
      ),
    ]);
  }

  void _pickFolder(BuildContext ctx, FilesProvider fp) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FolderPicker(
        initialPath: fp.currentPath,
        onPicked: (p) { fp.setOutputPath(p); Navigator.pop(ctx); },
      ),
    );
  }

  Future<void> _execute(BuildContext ctx, List<File> files,
      OperationsProvider op, FilesProvider fp) async {
    setState(() { _running = true; _done = 0; _total = files.length; _errors.clear(); });
    await RenameEngine.executeRename(
      files: files, cfg: op.config,
      outputDir: fp.deleteOriginal ? null : (fp.outputPath ?? fp.currentPath),
      deleteOriginal: fp.deleteOriginal,
      onProgress: (d, t) => setState(() { _done = d; _total = t; }),
      onError: (e) => _errors.add(e),
    );
    setState(() => _running = false);
    await fp.loadDirectory(fp.currentPath);
    if (!ctx.mounted) return;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      icon: Icon(_errors.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: _errors.isEmpty ? Colors.green : Colors.orange, size: 40),
      title: Text(_errors.isEmpty ? 'اكتملت العملية' : 'اكتملت مع تحذيرات'),
      content: Text(_errors.isEmpty
          ? 'تمت إعادة تسمية $_done ملف بنجاح ✅'
          : '$_done ملف تمت إعادة تسميته\n${_errors.take(3).join('\n')}'),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('موافق'))],
    ));
  }
}

class _FolderPicker extends StatefulWidget {
  final String initialPath;
  final void Function(String) onPicked;
  const _FolderPicker({required this.initialPath, required this.onPicked});
  @override State<_FolderPicker> createState() => _FPS();
}

class _FPS extends State<_FolderPicker> {
  late String _path;
  List<Directory> _dirs = [];

  @override
  void initState() { super.initState(); _path = widget.initialPath; _load(); }

  void _load() {
    try {
      _dirs = Directory(_path).listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.split('/').last.toLowerCase()
            .compareTo(b.path.split('/').last.toLowerCase()));
    } catch (_) { _dirs = []; }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _path.replaceFirst('/storage/emulated/0', 'التخزين الداخلي');
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          if (_path != '/storage/emulated/0')
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  _path = _path.substring(0, _path.lastIndexOf('/'));
                  if (_path.isEmpty) _path = '/storage/emulated/0';
                  _load();
                }),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          FilledButton(
            onPressed: () => widget.onPicked(_path),
            child: const Text('اختيار هذا المجلد'),
          ),
        ])),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(child: _dirs.isEmpty
            ? Center(child: Text('لا توجد مجلدات', style: TextStyle(color: cs.onSurfaceVariant)))
            : ListView.separated(
                itemCount: _dirs.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 52, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final name = _dirs[i].path.split('/').last;
                  return ListTile(
                    leading: const Icon(Icons.folder_rounded, color: Color(0xFFFFB300)),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () { _path = _dirs[i].path; _load(); },
                  );
                })),
      ]),
    );
  }
}
