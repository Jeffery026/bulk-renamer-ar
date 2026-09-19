import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';
import '../../providers/operations_provider.dart';
import '../../operations/rename_engine.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});
  @override State<PreviewScreen> createState() => _S();
}

class _S extends State<PreviewScreen> {
  bool _running = false;
  int _done = 0, _total = 0;
  final List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final selected = fp.selectedItems;
    final results = RenameEngine.applyAll(selected.map((f) => f.name).toList(), op.config);
    final changes = results.where((r) => r.hasChange).length;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.primary, foregroundColor: Colors.white, elevation: 0,
        title: const Text('التنفيذ والمعاينة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: selected.isEmpty
          ? _empty(cs)
          : Column(children: [
              // Output type
              Container(
                color: cs.surface,
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('نوع العملية', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _outBtn(context, 'استبدال الأصل', Icons.swap_horiz_rounded,
                        'تعديل الاسم مباشرة', fp.deleteOriginal, () => fp.setDeleteOriginal(true), cs)),
                    const SizedBox(width: 8),
                    Expanded(child: _outBtn(context, 'نسخ وتسمية', Icons.copy_rounded,
                        'الاحتفاظ بالأصل', !fp.deleteOriginal, () => fp.setDeleteOriginal(false), cs)),
                  ]),
                  if (!fp.deleteOriginal) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text(
                        fp.outputPath ?? 'نفس مجلد الملفات',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      )),
                      TextButton.icon(
                        onPressed: () => _pickOutputFolder(context, fp),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('تغيير', style: TextStyle(fontSize: 13)),
                      ),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 4),
              // Summary banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: changes > 0 ? cs.primaryContainer : cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(changes > 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      color: changes > 0 ? cs.primary : cs.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    changes > 0
                        ? '$changes ملف سيتغير اسمه من أصل ${selected.length}'
                        : 'لا تغييرات — فعّل خياراً من تبويب الخيارات',
                    style: TextStyle(
                      color: changes > 0 ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500, fontSize: 13,
                    ),
                  ),
                ]),
              ),
              // List label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(children: [
                  Text('معاينة الملفات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface)),
                  const Spacer(),
                  Text('${selected.length} ملف', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
              // Preview list
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final r = results[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: r.hasChange ? Border.all(color: cs.primary.withOpacity(0.3)) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.insert_drive_file_outlined, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r.originalName,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis)),
                      ]),
                      if (r.hasChange) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(r.newName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                              overflow: TextOverflow.ellipsis)),
                        ]),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text('← بدون تغيير', style: TextStyle(fontSize: 11, color: cs.outlineVariant)),
                        ),
                    ]),
                  );
                },
              )),
              // Execute
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                child: _running
                    ? Column(children: [
                        LinearProgressIndicator(value: _total > 0 ? _done / _total : null,
                            borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 8),
                        Text('جارٍ إعادة التسمية... $_done من $_total',
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ])
                    : FilledButton.icon(
                        onPressed: changes > 0
                            ? () => _execute(context, selected.map((f) => f.file).toList(), op, fp)
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('بدء إعادة التسمية ($changes ملف)'),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                      ),
              ),
            ]),
    );
  }

  Widget _empty(ColorScheme cs) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.folder_open_rounded, size: 80, color: cs.outlineVariant),
      const SizedBox(height: 20),
      Text('لم تختر أي ملفات', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text('انتقل لتبويب الملفات وحدد الملفات المراد تسميتها',
          style: TextStyle(fontSize: 13, color: cs.outlineVariant), textAlign: TextAlign.center),
    ]));
  }

  Widget _outBtn(BuildContext ctx, String title, IconData icon, String desc,
      bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: selected ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                color: selected ? cs.primary : cs.onSurface)),
            Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
        ]),
      ),
    );
  }

  void _pickOutputFolder(BuildContext ctx, FilesProvider fp) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FolderPicker(
        initialPath: fp.currentPath,
        onPicked: (path) { fp.setOutputPath(path); Navigator.pop(ctx); },
      ),
    );
  }

  Future<void> _execute(BuildContext ctx, List<File> files, OperationsProvider op, FilesProvider fp) async {
    setState(() { _running = true; _done = 0; _total = files.length; _errors.clear(); });
    await RenameEngine.executeRename(
      files: files, cfg: op.config,
      outputDir: fp.deleteOriginal ? null : (fp.outputPath ?? fp.currentPath),
      deleteOriginal: fp.deleteOriginal,
      onProgress: (d, t) => setState(() { _done = d; _total = t; }),
      onError: (e) => setState(() => _errors.add(e)),
    );
    setState(() => _running = false);
    await fp.loadDirectory(fp.currentPath);
    if (!ctx.mounted) return;
    _showDone(ctx);
  }

  void _showDone(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      icon: Icon(_errors.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: _errors.isEmpty ? Colors.green : Colors.orange, size: 40),
      title: Text(_errors.isEmpty ? 'اكتملت العملية' : 'اكتملت مع تحذيرات'),
      content: Text(_errors.isEmpty
          ? 'تمت إعادة تسمية $_done ملف بنجاح'
          : '$_done ملف تمت إعادة تسميته\n${_errors.length} أخطاء:\n${_errors.take(3).join('\n')}'),
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
  List<FileSystemEntity> _dirs = [];

  @override
  void initState() { super.initState(); _path = widget.initialPath; _load(); }

  void _load() {
    try {
      _dirs = Directory(_path).listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
    } catch (_) { _dirs = []; }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          if (_path != '/storage/emulated/0')
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () { _path = _path.substring(0, _path.lastIndexOf('/')); _load(); }),
          Expanded(child: Text(_path.replaceFirst('/storage/emulated/0', 'التخزين الداخلي'),
              style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          FilledButton(onPressed: () => widget.onPicked(_path), child: const Text('اختيار هذا المجلد')),
        ]),
        const Divider(),
        Expanded(child: _dirs.isEmpty
            ? Center(child: Text('لا توجد مجلدات فرعية', style: TextStyle(color: cs.onSurfaceVariant)))
            : ListView.builder(
                itemCount: _dirs.length,
                itemBuilder: (_, i) {
                  final name = _dirs[i].path.split('/').last;
                  return ListTile(
                    leading: const Icon(Icons.folder_rounded, color: Color(0xFFFFB300)),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () { _path = _dirs[i].path; _load(); },
                  );
                })),
      ]),
    );
  }
}
