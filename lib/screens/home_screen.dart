import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/files_provider.dart';
import 'browser/browser_screen.dart';
import 'operations/operations_screen.dart';
import 'preview/preview_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HS();
}

class _HS extends State<HomeScreen> {
  final _ctrl = PageController();
  int _page = 0;

  void _go(int p) => _ctrl.animateToPage(p,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: PageView(
        controller: _ctrl,
        // ← تمكين السحب بين الصفحات
        onPageChanged: (p) => setState(() => _page = p),
        children: const [BrowserScreen(), OperationsScreen(), PreviewScreen()],
      ),
      bottomNavigationBar: Container(
        // ← ارتفاع تلقائي يراعي أزرار النظام السفلية
        color: cs.primary,
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 52,
          child: Row(children: [
            // زر الإعدادات
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white70),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            // ← يسار
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
              color: _page > 0 ? Colors.white : Colors.white30,
              onPressed: _page > 0 ? () => _go(_page - 1) : null,
            ),
            // نقاط التنقل
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(0, 'الإدخال', fp.selectedCount, cs),
                const SizedBox(width: 18),
                _dot(1, 'الخيارات', 0, cs),
                const SizedBox(width: 18),
                _dot(2, 'المخرجات', 0, cs),
              ],
            )),
            // يمين ←
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 26),
              color: _page < 2 ? Colors.white : Colors.white30,
              onPressed: _page < 2 ? () => _go(_page + 1) : null,
            ),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }

  Widget _dot(int i, String label, int badge, ColorScheme cs) {
    final active = _page == i;
    return GestureDetector(
      onTap: () => _go(i),
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white60,
          )),
          if (badge > 0) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$badge', style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.bold, color: cs.primary)),
            ),
          ],
        ]),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 24 : 6, height: 4,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
    );
  }
}
