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
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fp = context.read<FilesProvider>();
      await fp.requestPermission();
      if (fp.permissionGranted) await fp.loadDirectory('/storage/emulated/0');
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<String> _segments(String path) {
    final rel = path.replaceFirst(RegExp(r'/storage/emulated/0/?'), '');
    if (rel.isEmpty) return ['التخزين الداخلي'];
    return ['التخزين الداخلي', ...rel.split('/').where((s) => s.isNotEmpty)];
  }

  void _navigateToSegment(FilesProvider fp, int segIndex) {
    final segs = _segments(fp.currentPath);
    if (segIndex == 0) {
      fp.loadDirectory('/storage/emulated/0');
    } else {
      final rel = segs.sublist(1, segIndex + 1).join('/');
      fp.loadDirectory('/storage/emulated/0/$rel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!fp.permissionGranted) return _permissionView(context, fp);

    final segs = _segments(fp.currentPath);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث...', hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none),
                onChanged: fp.setSearch,
              )
            : const Text('اختيار الملفات',
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchCtrl.clear(); fp.setSearch(''); }
            }),
          ),
          _menuBtn(context, fp),
        ],
      ),
      body: Column(children: [
        // Breadcrumbs
        Container(
          color: cs.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            if (fp.canGoBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: fp.navigateBack,
                color: cs.onPrimaryContainer,
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(segs.length, (i) {
                    final isLast = i == segs.length - 1;
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: isLast ? null : () => _navigateToSegment(fp, i),
                        child: Text(segs[i], style: TextStyle(
                          fontSize: 13,
                          color: isLast ? cs.onPrimaryContainer : cs.onPrimaryContainer.withOpacity(0.6),
                          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                      if (!isLast) Icon(Icons.chevron_right, size: 14,
                          color: cs.onPrimaryContainer.withOpacity(0.5)),
                    ]);
                  }),
                ),
              ),
            ),
          ]),
        ),
        // Sub-folders chips
        FutureBuilder<List<Directory>>(
          future: fp.getSubDirectories(fp.currentPath),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) return const SizedBox();
            return Container(
              height: 42,
              color: cs.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                children: snap.data!.map((d) {
                  final name = d.path.split('/').last;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.folder, size: 14),
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => fp.navigateTo(d.path),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        // Selection bar
        if (fp.selectedCount > 0)
          Container(
            color: cs.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('${fp.selectedCount} محدد',
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(onPressed: fp.selectAll, child: const Text('اختيار الكل')),
              TextButton(onPressed: fp.clearSelection, child: const Text('إلغاء الكل')),
            ]),
          ),
        // File list
        Expanded(child: _fileList(fp, cs)),
      ]),
    );
  }

  Widget _fileList(FilesProvider fp, ColorScheme cs) {
    final items = fp.items;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        const Text('المجلد فارغ'),
      ]));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          leading: _FileIcon(name: item.name),
          title: Text(item.name, style: const TextStyle(fontSize: 14)),
          subtitle: _FileInfo(file: item.file),
          trailing: Checkbox(
            value: item.selected,
            onChanged: (_) => fp.toggleSelect(item),
            activeColor: cs.primary,
          ),
          onTap: () => fp.toggleSelect(item),
          selected: item.selected,
          selectedTileColor: cs.primaryContainer.withOpacity(0.25),
          dense: true,
        );
      },
    );
  }

  Widget _menuBtn(BuildContext context, FilesProvider fp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        if (v == 'hidden') fp.toggleHidden();
        if (v == 'storage') _showStorage(context, fp);
        if (v == 'name') fp.setSort(SortBy.name, fp.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending);
        if (v == 'date') fp.setSort(SortBy.date, SortOrder.descending);
        if (v == 'size') fp.setSort(SortBy.size, SortOrder.descending);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'hidden',
            child: Text(fp.showHidden ? 'إخفاء الملفات المخفية' : 'عرض الملفات المخفية')),
        const PopupMenuItem<String>(value: 'storage', child: Text('اختيار التخزين')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'name', child: Text('ترتيب بالاسم')),
        const PopupMenuItem<String>(value: 'date', child: Text('ترتيب بالتاريخ')),
        const PopupMenuItem<String>(value: 'size', child: Text('ترتيب بالحجم')),
      ],
    );
  }

  void _showStorage(BuildContext ctx, FilesProvider fp) {
    showModalBottomSheet(context: ctx, builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('اختيار التخزين', style: TextStyle(fontWeight: FontWeight.bold))),
        for (final dir in fp.getStorageRoots())
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(dir.path.contains('emulated') ? 'التخزين الداخلي' : 'بطاقة SD'),
            onTap: () { Navigator.pop(ctx); fp.navigateTo(dir.path); },
          ),
      ],
    ));
  }

  Widget _permissionView(BuildContext ctx, FilesProvider fp) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline, size: 72, color: Colors.teal),
        const SizedBox(height: 24),
        const Text('صلاحية الوصول للملفات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('يحتاج التطبيق صلاحية الوصول للتخزين.',
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
    ));
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
    return Icon(icon, color: color, size: 26);
  }
}

class _FileInfo extends StatelessWidget {
  final File file;
  const _FileInfo({required this.file});
  @override
  Widget build(BuildContext context) {
    try {
      final s = file.statSync();
      final sz = s.size > 1048576 ? '${(s.size/1048576).toStringAsFixed(1)} م.ب'
          : s.size > 1024 ? '${(s.size/1024).toStringAsFixed(0)} ك.ب' : '${s.size} ب';
      final d = s.modified;
      return Text('$sz · ${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}',
          style: const TextStyle(fontSize: 11));
    } catch (_) { return const SizedBox(); }
  }
}
