import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});
  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final fp = context.read<FilesProvider>();
    final granted = await fp.requestPermission();
    if (granted) await fp.loadDirectory('/storage/emulated/0');
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;
    if (!fp.permissionGranted) return _permissionView(context);
    return Scaffold(
      appBar: AppBar(
        leading: fp.canGoBack
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: fp.navigateBack)
            : null,
        title: _searching
            ? TextField(
                controller: _searchCtrl, autofocus: true,
                decoration: const InputDecoration(hintText: 'بحث...', border: InputBorder.none),
                onChanged: fp.setSearch)
            : GestureDetector(
                onTap: () => _showPathPicker(context, fp),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('متصفح الملفات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(_shortPath(fp.currentPath),
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.6))),
                ])),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _searchCtrl.clear(); fp.setSearch(''); }
            }),
          ),
          _sortMenu(context, fp),
        ],
      ),
      body: Column(children: [
        _folderChips(fp),
        if (fp.selectedCount > 0) _selectionBar(fp, cs),
        Expanded(child: _fileList(fp, cs)),
      ]),
    );
  }

  Widget _sortMenu(BuildContext context, FilesProvider fp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        if (v == 'hidden') {
          fp.toggleHidden();
        } else {
          final map = {
            'name': SortBy.name, 'date': SortBy.date,
            'size': SortBy.size, 'ext': SortBy.extension,
          };
          if (map.containsKey(v)) {
            fp.setSort(map[v]!,
                fp.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending);
          }
        }
      },
      itemBuilder: (ctx) {
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'hidden',
            child: Row(children: [
              Icon(fp.showHidden ? Icons.visibility_off : Icons.visibility),
              const SizedBox(width: 8),
              Text(fp.showHidden ? 'إخفاء المخفية' : 'عرض المخفية'),
            ]),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(value: 'name', child: Text('ترتيب حسب الاسم')),
          const PopupMenuItem<String>(value: 'date', child: Text('ترتيب حسب التاريخ')),
          const PopupMenuItem<String>(value: 'size', child: Text('ترتيب حسب الحجم')),
          const PopupMenuItem<String>(value: 'ext', child: Text('ترتيب حسب الامتداد')),
        ];
      },
    );
  }

  Widget _folderChips(FilesProvider fp) {
    return FutureBuilder<List<Directory>>(
      future: fp.getSubDirectories(fp.currentPath),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox();
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: snap.data!.map((d) {
              final name = d.path.split('/').last;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.folder, size: 16),
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  onPressed: () => fp.navigateTo(d.path),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _selectionBar(FilesProvider fp, ColorScheme cs) {
    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Text('${fp.selectedCount} محدد',
            style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton(onPressed: fp.selectAll, child: const Text('اختيار الكل')),
        TextButton(onPressed: fp.clearSelection, child: const Text('إلغاء الكل')),
      ]),
    );
  }

  Widget _fileList(FilesProvider fp, ColorScheme cs) {
    if (fp.items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        const Text('لا توجد ملفات في هذا المجلد'),
      ]));
    }
    return ListView.builder(
      itemCount: fp.items.length,
      itemBuilder: (ctx, i) {
        final item = fp.items[i];
        return ListTile(
          leading: _FileIcon(name: item.name),
          title: Text(item.name, style: const TextStyle(fontSize: 14)),
          subtitle: _FileInfo(file: item.file),
          trailing: Checkbox(value: item.selected, onChanged: (_) => fp.toggleSelect(item)),
          onTap: () => fp.toggleSelect(item),
          selected: item.selected,
          selectedTileColor: cs.primaryContainer.withOpacity(0.3),
        );
      },
    );
  }

  void _showPathPicker(BuildContext ctx, FilesProvider fp) {
    showModalBottomSheet(context: ctx, builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('اختيار التخزين', style: TextStyle(fontWeight: FontWeight.bold))),
        for (final dir in fp.getStorageRoots())
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(dir.path.contains('emulated') ? 'التخزين الداخلي' : 'SD Card: ${dir.path.split('/').last}'),
            onTap: () { Navigator.pop(ctx); fp.navigateTo(dir.path); },
          ),
      ],
    ));
  }

  Widget _permissionView(BuildContext context) {
    final fp = context.read<FilesProvider>();
    return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline, size: 72, color: Colors.teal),
        const SizedBox(height: 24),
        const Text('صلاحية الوصول للملفات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('يحتاج التطبيق صلاحية الوصول للتخزين لإعادة تسمية الملفات.',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await fp.requestPermission();
            if (fp.permissionGranted) await fp.loadDirectory('/storage/emulated/0');
          },
          icon: const Icon(Icons.check),
          label: const Text('منح الصلاحية'),
        ),
      ]),
    )));
  }

  String _shortPath(String path) {
    if (path.contains('emulated/0')) {
      final rel = path.replaceFirst(RegExp(r'.*/emulated/0/?'), '');
      return rel.isEmpty ? 'التخزين الداخلي' : rel;
    }
    return path.split('/').last;
  }
}

class _FileIcon extends StatelessWidget {
  final String name;
  const _FileIcon({required this.name});
  @override
  Widget build(BuildContext context) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    IconData icon; Color color;
    if (['jpg','jpeg','png','gif','webp','bmp','heic'].contains(ext)) { icon=Icons.image; color=Colors.teal; }
    else if (['mp4','avi','mkv','mov','3gp'].contains(ext)) { icon=Icons.videocam; color=Colors.indigo; }
    else if (['mp3','flac','wav','aac','ogg'].contains(ext)) { icon=Icons.audiotrack; color=Colors.orange; }
    else if (ext=='pdf') { icon=Icons.picture_as_pdf; color=Colors.red; }
    else if (['doc','docx'].contains(ext)) { icon=Icons.description; color=Colors.blue; }
    else if (['xls','xlsx'].contains(ext)) { icon=Icons.table_chart; color=Colors.green; }
    else if (['zip','rar','7z'].contains(ext)) { icon=Icons.folder_zip; color=Colors.brown; }
    else { icon=Icons.insert_drive_file; color=Colors.grey; }
    return Icon(icon, color: color, size: 28);
  }
}

class _FileInfo extends StatelessWidget {
  final File file;
  const _FileInfo({required this.file});
  @override
  Widget build(BuildContext context) {
    try {
      final stat = file.statSync();
      final size = stat.size;
      final date = stat.modified;
      final s = size>1048576 ? '${(size/1048576).toStringAsFixed(1)} م.ب'
               : size>1024   ? '${(size/1024).toStringAsFixed(0)} ك.ب'
               : '$size ب';
      return Text('$s · ${date.year}/${date.month.toString().padLeft(2,'0')}/${date.day.toString().padLeft(2,'0')}',
          style: const TextStyle(fontSize: 11));
    } catch (_) { return const SizedBox(); }
  }
}
