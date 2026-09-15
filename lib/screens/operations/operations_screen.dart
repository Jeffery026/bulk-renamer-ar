import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/operations_provider.dart';
import 'add_tab.dart';
import 'remove_tab.dart';
import 'change_tab.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationsProvider>();
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      initialIndex: op.activeTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خيارات إعادة التسمية'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'إعادة ضبط', onPressed: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('إعادة الضبط'),
                content: const Text('هل تريد مسح كل الخيارات؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                  FilledButton(onPressed: () { op.resetAll(); Navigator.pop(ctx); }, child: const Text('مسح')),
                ],
              ));
            }),
          ],
          bottom: TabBar(
            onTap: op.setActiveTab,
            tabs: const [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'إضافة'),
              Tab(icon: Icon(Icons.remove_circle_outline), text: 'حذف'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'تغيير'),
            ],
          ),
        ),
        body: const TabBarView(children: [AddTab(), RemoveTab(), ChangeTab()]),
      ),
    );
  }
}
