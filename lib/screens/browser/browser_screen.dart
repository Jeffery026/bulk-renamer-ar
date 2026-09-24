import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/files_provider.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});
  @override State<BrowserScreen> createState() => _BS();
}

class _BS extends State<BrowserScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _sc = TextEditingController();

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;

    // ← الواجهة الأولى: اختيار التخزين فقط (لا ملفات تلقائية)
    if (!fp.initialized) return _startView(context, fp, cs);
    if (!fp.permissionGranted) return _permView(context, fp, cs);

    final items = fp.items;

    return Column(children: [
      // Title bar
      Container(
        color: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(child: Text('اختيار ملفات الإدخال',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.storage_rounded, color: Colors.white70, size: 20),
            onPressed: () => _storageSheet(context, fp),
            tooltip: 'تغيير التخزين',
          ),
          _menuBtn(context, fp),
        ]),
      ),
      // Breadcrumbs
      Container(
        color: cs.surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(fp.breadcrumbs.length, (i) {
            final isLast = i == fp.breadcrumbs.length - 1;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: isLast ? null : () => fp.navigateToBreadcrumb(i),
                child: Text(fp.breadcrumbs[i], style: TextStyle(
                  fontSize: 12,
                  color: isLast ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                )),
              ),
              if (!isLast) Icon(Icons.chevron_right, size: 14, color: cs.outlineVariant),
            ]);
          })),
        ),
      ),
      // Search row
      Container(
        color: cs.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(children: [
          // ← "اختيار الكل" يظهر فقط عند وجود ملفات
          if (items.any((f) => f.isFile)) ...[
            GestureDetector(
              onTap: fp.selectedCount > 0 ? fp.clearSelection : fp.selectAll,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  fp.selectedCount > 0 ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20, color: fp.selectedCount > 0 ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('الكل', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: TextField(
            controller: _sc,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'بحث...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
            ),
            onChanged: fp.setSearch,
          )),
          if (fp.selectedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
              child: Text('${fp.selectedCount}',
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ]),
      ),
      // Back button row
      if (fp.canGoBack)
        InkWell(
          onTap: fp.navigateBack,
          child: Container(
            color: cs.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Icon(Icons.arrow_back_rounded, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('رجوع', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      Divider(height: 1, color: cs.outlineVariant),
      // File list
      Expanded(child: items.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open_outlined, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text('المجلد فارغ', style: TextStyle(color: cs.onSurfaceVariant)),
            ]))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 52, color: cs.outlineVariant),
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.isDir) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_rounded, color: Color(0xFFFFB300), size: 28),
                    title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                    onTap: () => fp.navigateTo(item.entity.path),
                  );
                }
                final selected = fp.isSelected(item);
                return ListTile(
                  dense: true,
                  leading: _icon(item.name),
                  title: Text(item.name, style: const TextStyle(fontSize: 14)),
                  subtitle: _info(item.file),
                  trailing: Icon(
                    selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: selected ? cs.primary : cs.outlineVariant, size: 20,
                  ),
                  onTap: () => fp.toggleSelect(item),
                  selected: selected,
                  selectedTileColor: cs.primaryContainer.withOpacity(0.2),
                );
              },
            )),
    ]);
  }

  // ← الشاشة الأولى: زر تصفح فقط
  Widget _startView(BuildContext ctx, FilesProvider fp, ColorScheme cs) {
    return Column(children: [
      Container(
        color: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: const Row(children: [
          Expanded(child: Text('اختيار ملفات الإدخال',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
      ),
      Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_outlined, size: 96, color: cs.outlineVariant),
        const SizedBox(height: 24),
        Text('لم يتم اختيار مجلد بعد',
            style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('اضغط تصفح لاختيار الملفات',
            style: TextStyle(fontSize: 13, color: cs.outlineVariant)),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _storageSheet(ctx, fp),
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('تصفح الملفات'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 50),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ]))),
    ]);
  }

  Widget _permView(BuildContext ctx, FilesProvider fp, ColorScheme cs) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 72, color: cs.outlineVariant),
        const SizedBox(height: 24),
        const Text('صلاحية الوصول للملفات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('يحتاج التطبيق صلاحية الوصول لتخزين جهازك.',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () async {
            await fp.requestPermission();
            if (fp.permissionGranted && ctx.mounted) _storageSheet(ctx, fp);
          },
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('منح الصلاحية'),
          style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
        ),
      ]),
    ));
  }

  void _storageSheet(BuildContext ctx, FilesProvider fp) async {
    await fp.requestPermission();
    if (!fp.permissionGranted || !ctx.mounted) return;
    showModalBottomSheet(context: ctx, builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text('اختيار التخزين',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        for (final dir in fp.getStorageRoots()) ListTile(
          leading: Icon(Icons.storage_rounded, color: Theme.of(ctx).colorScheme.primary),
          title: Text(dir.path.contains('emulated') ? 'التخزين الداخلي' : 'بطاقة SD'),
          onTap: () { Navigator.pop(ctx); fp.navigateTo(dir.path); },
        ),
        const SizedBox(height: 8),
      ]),
    ));
  }

  Widget _menuBtn(BuildContext ctx, FilesProvider fp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
      onSelected: (v) {
        if (v == 'hidden') fp.toggleHidden();
        if (v == 'storage') _storageSheet(ctx, fp);
        if (v == 'name') fp.setSort(SortBy.name, fp.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending);
        if (v == 'date') fp.setSort(SortBy.date, SortOrder.descending);
        if (v == 'size') fp.setSort(SortBy.size, SortOrder.descending);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'hidden', child: Text(fp.showHidden ? 'إخفاء المخفية' : 'عرض المخفية')),
        const PopupMenuItem<String>(value: 'storage', child: Text('تغيير التخزين')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'name', child: Text('ترتيب بالاسم')),
        const PopupMenuItem<String>(value: 'date', child: Text('ترتيب بالتاريخ')),
        const PopupMenuItem<String>(value: 'size', child: Text('ترتيب بالحجم')),
      ],
    );
  }

  Widget _icon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final (ic, cl) = _ic(ext);
    return SizedBox(width: 36, child: Icon(ic, color: cl, size: 26));
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

  Widget _info(File f) {
    try {
      final s = f.statSync();
      final sz = s.size > 1048576 ? '${(s.size/1048576).toStringAsFixed(1)} م.ب'
          : s.size > 1024 ? '${(s.size/1024).toStringAsFixed(0)} ك.ب' : '${s.size} ب';
      final d = s.modified;
      return Text('$sz · ${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}',
          style: const TextStyle(fontSize: 11));
    } catch (_) { return const SizedBox(); }
  }
}
