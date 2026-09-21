import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});
  @override
  State<BrowserScreen> createState() => _BS();
}

class _BS extends State<BrowserScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _searching = false;
  final _sc = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fp = context.read<FilesProvider>();
      if (!fp.initialized) {
        await fp.requestPermission();
        if (fp.permissionGranted) await fp.loadDirectory('/storage/emulated/0');
      }
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!fp.permissionGranted && !fp.initialized) return _permView(fp, cs);

    final items = fp.items;

    return Column(children: [
      // ── Title bar ─────────────────────────────────────────
      Container(
        color: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(child: Text('اختيار ملفات الإدخال',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          _menuBtn(context, fp),
        ]),
      ),
      // ── Breadcrumbs ────────────────────────────────────────
      Container(
        color: cs.surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          Icon(Icons.phone_android_rounded, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(fp.breadcrumbs.length, (i) {
                final isLast = i == fp.breadcrumbs.length - 1;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: isLast ? null : () => fp.navigateToBreadcrumb(i),
                    child: Text(fp.breadcrumbs[i], style: TextStyle(
                      fontSize: 13,
                      color: isLast ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                  if (!isLast) Icon(Icons.chevron_right, size: 16, color: cs.outlineVariant),
                ]);
              }),
            ),
          )),
        ]),
      ),
      // ── Select / Search row ────────────────────────────────
      Container(
        color: cs.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(children: [
          // Select all
          GestureDetector(
            onTap: fp.selectedCount > 0 ? fp.clearSelection : fp.selectAll,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                fp.selectedCount > 0 ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 22, color: fp.selectedCount > 0 ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text('اختيار الكل', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          // Search
          Expanded(child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Icon(Icons.search, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(child: TextField(
                controller: _sc,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث في هذا المجلد',
                  hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  border: InputBorder.none, isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: fp.setSearch,
              )),
            ]),
          )),
          const SizedBox(width: 8),
          // Clear + Count
          if (fp.selectedCount > 0) ...[
            GestureDetector(
              onTap: fp.clearSelection,
              child: Icon(Icons.remove_circle_outline, size: 20, color: cs.error),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${fp.selectedCount}',
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ]),
      ),
      // ── Back button row ────────────────────────────────────
      if (fp.canGoBack)
        InkWell(
          onTap: fp.navigateBack,
          child: Container(
            color: cs.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(Icons.arrow_back_rounded, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('رجوع', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      Divider(height: 1, color: cs.outlineVariant),
      // ── File list ─────────────────────────────────────────
      Expanded(child: items.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open_outlined, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text('لا توجد ملفات', style: TextStyle(color: cs.onSurfaceVariant)),
            ]))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 56, color: cs.outlineVariant),
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.isDir) {
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.folder_rounded, color: const Color(0xFFFFB300), size: 28),
                    title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    onTap: () => fp.navigateTo(item.entity.path),
                  );
                }
                final selected = fp.isSelected(item);
                return ListTile(
                  dense: true,
                  leading: _FileIcon(name: item.name),
                  title: Text(item.name, style: const TextStyle(fontSize: 14)),
                  subtitle: _FileInfo(file: item.file),
                  trailing: Icon(
                    selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: selected ? cs.primary : cs.outlineVariant,
                    size: 22,
                  ),
                  onTap: () => fp.toggleSelect(item),
                  selected: selected,
                  selectedTileColor: cs.primaryContainer.withOpacity(0.2),
                );
              },
            )),
    ]);
  }

  Widget _menuBtn(BuildContext ctx, FilesProvider fp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        if (v == 'hidden') fp.toggleHidden();
        if (v == 'storage') _storageSheet(ctx, fp);
        if (v == 'name') fp.setSort(SortBy.name, fp.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending);
        if (v == 'date') fp.setSort(SortBy.date, SortOrder.descending);
        if (v == 'size') fp.setSort(SortBy.size, SortOrder.descending);
        if (v == 'ext') fp.setSort(SortBy.extension, SortOrder.ascending);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'hidden',
            child: Text(fp.showHidden ? 'إخفاء الملفات المخفية' : 'عرض الملفات المخفية')),
        const PopupMenuItem<String>(value: 'storage', child: Text('تغيير التخزين')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'name', child: Text('ترتيب بالاسم')),
        const PopupMenuItem<String>(value: 'date', child: Text('ترتيب بالتاريخ')),
        const PopupMenuItem<String>(value: 'size', child: Text('ترتيب بالحجم')),
        const PopupMenuItem<String>(value: 'ext', child: Text('ترتيب بالامتداد')),
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
            onTap: () { Navigator.pop(ctx); fp.navigateTo(dir.path); },
          ),
        const SizedBox(height: 8),
      ]),
    ));
  }

  Widget _permView(FilesProvider fp, ColorScheme cs) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_off_outlined, size: 72, color: cs.outlineVariant),
        const SizedBox(height: 24),
        const Text('صلاحية الوصول للملفات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('يحتاج التطبيق الوصول لتخزين جهازك',
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
    ));
  }
}

class _FileIcon extends StatelessWidget {
  final String name;
  const _FileIcon({required this.name});
  @override
  Widget build(BuildContext context) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final (icon, color) = _ic(ext);
    return SizedBox(width: 36, height: 36,
      child: Icon(icon, color: color, size: 26));
  }
  (IconData, Color) _ic(String e) {
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
      final sz = s.size > 1048576
          ? '${(s.size / 1048576).toStringAsFixed(1)} م.ب'
          : s.size > 1024
              ? '${(s.size / 1024).toStringAsFixed(0)} ك.ب'
              : '${s.size} ب';
      final d = s.modified;
      return Text(
          '$sz · ${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11));
    } catch (_) { return const SizedBox(); }
  }
}
