import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات المحفوظة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // حفظ الإعداد الحالي
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('حفظ الإعداد الحالي', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم الإعداد', hintText: 'مثال: إعادة تسمية الصور')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                await op.saveConfig(_nameCtrl.text.trim());
                _nameCtrl.clear();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الحفظ ✅'), behavior: SnackBarBehavior.floating));
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ]),
        )),
        const SizedBox(height: 16),
        // الإعدادات المحفوظة
        if (op.savedConfigNames.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Icon(Icons.bookmark_border, size: 48, color: cs.outlineVariant),
              const SizedBox(height: 12),
              const Text('لا توجد إعدادات محفوظة'),
            ]),
          ))
        else ...[
          Text('الإعدادات المحفوظة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final name in op.savedConfigNames)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(name),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.upload),
                    tooltip: 'تحميل',
                    onPressed: () async {
                      await op.loadConfig(name);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تحميل: $name'), behavior: SnackBarBehavior.floating));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text('حذف الإعداد'),
                      content: Text('هل تريد حذف "$name"؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () { op.deleteConfig(name); Navigator.pop(context); },
                          child: const Text('حذف'),
                        ),
                      ],
                    )),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }
}
