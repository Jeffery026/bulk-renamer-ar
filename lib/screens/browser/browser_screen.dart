import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});
  @override State<BrowserScreen> createState() => _S();
}

class _S extends State<BrowserScreen> {
  bool _searching = false;
  final _sc = TextEditingController();

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
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;
    if (!fp.permissionGranted) return _permView(context, fp, cs);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        leading: fp.canGoBack
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: fp.navigateBack)
            : IconButton(
                icon: const Icon(Icons.storage, size: 20),
                onPressed: () => _storageSheet(context, fp),
              ),
        title: _searching
            ? TextField(
                controller: _sc, autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث في الملفات...', border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white60)),
                onChanged: fp.setSearch)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('اختيار الملفات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_shortPath(fp.currentPath),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ]),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search, size: 22),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _sc.clear(); fp.setSearch(''); }
            }),
          ),
          _menu(context, fp),
        ],
      ),
      body: Column(children: [
        // breadcrumb
        Container(
          color: cs.primaryContainer,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(fp.breadcrumbs.length, (i) {
                final isLast = i == fp.breadcrumbs.length - 1;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: isLast ? null : () => fp.navigateToBreadcrumb(i),
                    child: Text(fp.breadcrumbs[i], style: TextStyle(
                      fontSize: 12,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                      color: isLast ? cs.onPrimaryContainer : cs.onPrimaryContainer.withOpacity(0.6),
                    )),
                  ),
                  if (!isLast) Icon(Icons.chevron_right, size: 14, color: cs.onPrimaryContainer.withOpacity(0.4)),
                ]);
              }),
            ),
          ),
        ),
        // selection bar
        if (fp.selectedCount > 0)
          Container(
            color: cs.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('${fp.selectedCount} محدد',
                    style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const Spacer(),
              TextButton(onPressed: fp.selectAll, child: const Text('الكل')),
              TextButton(onPressed: fp.clearSelection, child: const Text('إلغاء')),
            ]),
          ),
        // list
        Expanded(child: _list(fp, cs)),
      ]),
    );
  }

  Widget _list(FilesProvider fp, ColorScheme cs) {
    final items = fp.items;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open_outlined, size: 72, color: cs.outlineVariant),
        const SizedBox(height: 16),
        Text('المجلد فارغ', style: TextStyle(color: cs.onSurfaceVariant)),
      ]));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isDir) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: Color(0xFFFFB300), size: 26),
            ),
            title: Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () => fp.navigateTo(item.entity.path),
          );
        }
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          leading: _FileIcon(name: item.name),
          title: Text(item.name, style: const TextStyle(fontSize: 14)),
          subtitle: _FileInfo(file: item.file),
          trailing: Checkbox(
            value: item.selected,
            onChanged: (_) => fp.toggleSelect(item),
            activeColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onTap: () => fp.toggleSelect(item),
          selected: item.selected,
          selectedTileColor: cs.primaryContainer.withOpacity(0.2),
        );
      },
    );
  }

  Widget _menu(BuildContext ctx, FilesProvider fp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        if (v == 'hidden') fp.toggleHidden();
        if (v == 'storage') _storageSheet(ctx, fp);
        if (v == 'name') fp.setSort(SortBy.name, fp.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending);
        if (v == 'date') fp.setSort(SortBy.date, SortOrder.descending);
        if (v == 'size') fp.setSort(SortBy.size, SortOrder.descending);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'hidden',
            child: Text(fp.showHidden ? 'إخفاء الملفات المخفية' : 'عرض الملفات المخفية')),
        const PopupMenuItem<String>(value: 'storage', child: Text('تغيير التخزين')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'name', child: Text('ترتيب بالاسم')),
        const PopupMenuItem<String>(value: 'date', child: Text('ترتيب بالتاريخ')),
        const PopupMenuItem<String>(value: 'size', child: Text('ترتيب بالحجم')),
      ],
    );
  }

  void _storageSheet(BuildContext ctx, FilesProvider fp) {
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text('اختيار التخزين',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        for (final dir in fp.getStorageRoots())
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: Text(dir.path.contains('emulated') ? 'التخزين الداخلي' : 'بطاقة SD'),
            subtitle: Text(dir.path),
            onTap: () { Navigator.pop(ctx); fp.navigateTo(dir.path); },
          ),
        const SizedBox(height: 8),
      ]),
    ));
  }

  Widget _permView(BuildContext ctx, FilesProvider fp, ColorScheme cs) {
    return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_off_outlined, size: 80, color: cs.outlineVariant),
        const SizedBox(height: 24),
        Text('صلاحية الوصول للملفات',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('يحتاج التطبيق صلاحية الوصول لتخزين جهازك لإعادة تسمية الملفات.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () async {
            await fp.requestPermission();
            if (fp.permissionGranted) await fp.loadDirectory('/storage/emulated/0');
          },
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('منح الصلاحية'),
          style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
        ),
      ]),
    )));
  }

  String _shortPath(String p) {
    final rel = p.replaceFirst(RegExp(r'/storage/emulated/0/?'), '');
    return rel.isEmpty ? 'التخزين الداخلي' : rel;
  }
}

class _FileIcon extends StatelessWidget {
  final String name;
  const _FileIcon({required this.name});
  @override
  Widget build(BuildContext context) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final data = _icon(ext);
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: data.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(data.$1, color: data.$2, size: 24),
    );
  }
  (IconData, Color) _icon(String e) {
    if (['jpg','jpeg','png','gif','webp','bmp','heic'].contains(e)) return (Icons.image_rounded, Colors.teal);
    if (['mp4','avi','mkv','mov','3gp'].contains(e)) return (Icons.movie_rounded, Colors.indigo);
    if (['mp3','flac','wav','aac','ogg'].contains(e)) return (Icons.music_note_rounded, Colors.orange);
    if (e == 'pdf') return (Icons.picture_as_pdf_rounded, Colors.red);
    if (['doc','docx'].contains(e)) return (Icons.description_rounded, Colors.blue);
    if (['xls','xlsx'].contains(e)) return (Icons.table_chart_rounded, Colors.green);
    if (['zip','rar','7z'].contains(e)) return (Icons.folder_zip_rounded, Colors.brown);
    return (Icons.insert_drive_file_rounded, Colors.grey);
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
