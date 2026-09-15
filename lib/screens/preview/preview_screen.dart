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
    final files = context.watch<FilesProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final selected = files.selectedItems;
    final results = RenameEngine.applyAll(selected.map((f) => f.name).toList(), op.config);
    final hasChanges = results.any((r) => r.hasChange);

    return Scaffold(
      appBar: AppBar(title: const Text('معاينة النتائج')),
      body: selected.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 16),
              const Text('لم يتم اختيار أي ملفات', style: TextStyle(fontSize: 16)),
            ]))
          : Column(children: [
              // ملخص
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasChanges ? cs.primaryContainer : cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(hasChanges ? Icons.check_circle_outline : Icons.warning_outlined,
                      color: hasChanges ? cs.onPrimaryContainer : cs.onErrorContainer),
                  const SizedBox(width: 10),
                  Text(
                    hasChanges
                        ? '${results.where((r) => r.hasChange).length} من ${selected.length} ملف سيتغير'
                        : 'لا تغييرات — فعّل خياراً أولاً',
                    style: TextStyle(
                        color: hasChanges ? cs.onPrimaryContainer : cs.onErrorContainer,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              // خيار المخرجات
              _OutputOptions(files: files),
              // قائمة المعاينة
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = results[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: _fileIcon(r.originalName),
                      title: Text(r.originalName, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: r.hasChange
                          ? Row(children: [
                              Icon(Icons.arrow_downward, size: 14, color: cs.primary),
                              const SizedBox(width: 4),
                              Expanded(child: Text(r.newName, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500))),
                            ])
                          : const Text('بدون تغيير', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  },
                ),
              ),
              // زر التنفيذ
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
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: hasChanges ? () => _execute(context, selected.map((f) => f.file).toList(), op, files) : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text('بدء إعادة التسمية (${results.where((r) => r.hasChange).length} ملف)'),
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  ),
                ),
            ]),
    );
  }

  Widget _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
    final isVideo = ['mp4', 'avi', 'mkv', 'mov'].contains(ext);
    final isAudio = ['mp3', 'flac', 'wav', 'aac'].contains(ext);
    final isPdf = ext == 'pdf';
    return Icon(
      isImage ? Icons.image : isVideo ? Icons.videocam : isAudio ? Icons.audiotrack :
      isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
      color: isImage ? Colors.teal : isVideo ? Colors.indigo : isAudio ? Colors.orange :
      isPdf ? Colors.red : Colors.grey,
    );
  }

  Future<void> _execute(BuildContext context, List<File> files, OperationsProvider op, FilesProvider fp) async {
    setState(() { _running = true; _done = 0; _total = files.length; _errors.clear(); });
    await RenameEngine.executeRename(
      files: files, cfg: op.config,
      outputDir: fp.outputPath,
      deleteOriginal: fp.deleteOriginal,
      onProgress: (d, t) => setState(() { _done = d; _total = t; }),
      onError: (e) => setState(() => _errors.add(e)),
    );
    setState(() => _running = false);
    if (!context.mounted) return;
    await fp.loadDirectory(fp.currentPath);
    _showDone(context);
  }

  void _showDone(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('اكتملت العملية'),
      content: Text(_errors.isEmpty
          ? 'تمت إعادة تسمية $_done ملف بنجاح ✅'
          : 'تم: $_done — أخطاء: ${_errors.length}\n\n${_errors.join('\n')}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('موافق'))],
    ));
  }
}

class _OutputOptions extends StatelessWidget {
  final FilesProvider files;
  const _OutputOptions({required this.files});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        const Text('المخرجات:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        ChoiceChip(label: const Text('نفس المكان'), selected: files.deleteOriginal,
            onSelected: (_) => files.setDeleteOriginal(true)),
        const SizedBox(width: 6),
        ChoiceChip(label: const Text('نسخ وإعادة تسمية'), selected: !files.deleteOriginal,
            onSelected: (_) => files.setDeleteOriginal(false)),
      ]),
    );
  }
}
