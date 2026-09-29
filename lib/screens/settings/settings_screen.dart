import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [

        // ── الثيم ─────────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.palette_outlined, color: cs.primary),
              const SizedBox(width: 10),
              const Text('الثيم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 6),
            // فاتح
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text('فاتح', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in [AppThemeType.blue, AppThemeType.arcticBlue,
                  AppThemeType.teal, AppThemeType.purple, AppThemeType.crimson])
                _ThemeChip(type: t, current: s.themeType, onTap: () => s.setTheme(t)),
            ]),
            // داكن
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text('داكن', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in [AppThemeType.darkBlue, AppThemeType.darkTeal,
                  AppThemeType.carbon, AppThemeType.midnight])
                _ThemeChip(type: t, current: s.themeType, onTap: () => s.setTheme(t)),
            ]),
          ]),
        )),

        // ── حجم الخط ──────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.text_fields_rounded, color: cs.primary),
              const SizedBox(width: 10),
              const Text('حجم الخط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _FontBtn(label: 'صغير', size: 0.85, current: s.fontSize, onTap: s.setFontSize),
              _FontBtn(label: 'عادي', size: 1.0, current: s.fontSize, onTap: s.setFontSize),
              _FontBtn(label: 'كبير', size: 1.15, current: s.fontSize, onTap: s.setFontSize),
              _FontBtn(label: 'أكبر', size: 1.3, current: s.fontSize, onTap: s.setFontSize),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('معاينة: هذا النص يعطيك فكرة عن حجم الخط.',
                  style: TextStyle(fontSize: 14 * s.fontSize)),
            ),
          ]),
        )),

        // ── الإعدادات المحفوظة ─────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.bookmark_outlined, color: cs.primary),
              const SizedBox(width: 10),
              const Text('الإعدادات المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
            if (op.savedConfigNames.isEmpty)
              Text('لا توجد إعدادات محفوظة بعد',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
            else
              for (final name in op.savedConfigNames)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.bookmark_rounded, color: cs.primary, size: 20),
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      tooltip: 'تحميل',
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
                      tooltip: 'حذف',
                      onPressed: () => _del(context, op, name),
                    ),
                  ]),
                ),
          ]),
        )),

      ]),
    );
  }

  void _del(BuildContext ctx, OperationsProvider op, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('حذف الإعداد'),
      content: Text('حذف "$name"؟'),
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

class _ThemeChip extends StatelessWidget {
  final AppThemeType type;
  final AppThemeType current;
  final VoidCallback onTap;
  const _ThemeChip({required this.type, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = kThemes[type]!;
    final active = type == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cfg.isDark ? (cfg.background ?? const Color(0xFF1E1E1E)) : cfg.primary,
          borderRadius: BorderRadius.circular(20),
          border: active ? Border.all(color: Colors.white, width: 2.5) : null,
          boxShadow: active ? [BoxShadow(color: cfg.primary.withOpacity(0.5), blurRadius: 6)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (active) const Icon(Icons.check, color: Colors.white, size: 14),
          if (active) const SizedBox(width: 4),
          Text(cfg.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _FontBtn extends StatelessWidget {
  final String label;
  final double size;
  final double current;
  final void Function(double) onTap;
  const _FontBtn({required this.label, required this.size, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = (current - size).abs() < 0.01;
    return GestureDetector(
      onTap: () => onTap(size),
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
}
