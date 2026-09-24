import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        // حجم الخط
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.text_fields_rounded, color: cs.primary),
              const SizedBox(width: 10),
              const Text('حجم الخط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _sizeBtn(context, settings, 0.85, 'صغير'),
              _sizeBtn(context, settings, 1.0, 'عادي'),
              _sizeBtn(context, settings, 1.15, 'كبير'),
              _sizeBtn(context, settings, 1.3, 'أكبر'),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('معاينة: هذا النص يعطيك فكرة عن حجم الخط.',
                  style: TextStyle(fontSize: 14 * settings.fontSize)),
            ),
          ]),
        )),
        // الثيم
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.palette_outlined, color: cs.primary),
              const SizedBox(width: 10),
              const Text('مظهر التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            for (final mode in [
              (ThemeMode.system, 'تلقائي (حسب الجهاز)', Icons.brightness_auto_rounded),
              (ThemeMode.light, 'فاتح', Icons.light_mode_rounded),
              (ThemeMode.dark, 'داكن', Icons.dark_mode_rounded),
            ])
              RadioListTile<ThemeMode>(
                dense: true,
                title: Row(children: [
                  Icon(mode.$3, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(mode.$2),
                ]),
                value: mode.$1,
                groupValue: settings.themeMode,
                onChanged: (v) => settings.setThemeMode(v!),
              ),
          ]),
        )),
        // الإعدادات المحفوظة
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.bookmark_outlined, color: cs.primary),
              const SizedBox(width: 10),
              const Text('الإعدادات المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            if (op.savedConfigNames.isEmpty)
              Text('لا توجد إعدادات محفوظة',
                  style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final name in op.savedConfigNames)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.bookmark_rounded, color: cs.primary, size: 20),
                  title: Text(name),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      onPressed: () async {
                        await op.loadConfig(name);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم تحميل: $name'),
                                  behavior: SnackBarBehavior.floating));
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
                      onPressed: () => _confirmDelete(context, op, name),
                    ),
                  ]),
                ),
          ]),
        )),
      ]),
    );
  }

  Widget _sizeBtn(BuildContext ctx, SettingsProvider s, double size, String label) {
    final cs = Theme.of(ctx).colorScheme;
    final active = (s.fontSize - size).abs() < 0.01;
    return GestureDetector(
      onTap: () => s.setFontSize(size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: active ? cs.onPrimary : cs.onSurface,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, OperationsProvider op, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('حذف الإعداد'),
      content: Text('هل تريد حذف "$name"؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { op.deleteConfig(name); Navigator.pop(ctx); },
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}
