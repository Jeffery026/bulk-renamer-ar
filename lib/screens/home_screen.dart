import 'package:flutter/material.dart';
import 'browser/browser_screen.dart';
import 'operations/operations_screen.dart';
import 'preview/preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = PageController();
  int _page = 0;

  void _go(int p) => _ctrl.animateToPage(p,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: PageView(
        controller: _ctrl,
        onPageChanged: (p) => setState(() => _page = p),
        children: const [BrowserScreen(), OperationsScreen(), PreviewScreen()],
      ),
      bottomNavigationBar: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0 ? () => _go(_page - 1) : null,
            color: _page > 0 ? cs.primary : cs.onSurface.withOpacity(0.3),
          ),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _dot(0, 'الملفات', cs),
            const SizedBox(width: 20),
            _dot(1, 'الخيارات', cs),
            const SizedBox(width: 20),
            _dot(2, 'المخرجات', cs),
          ])),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < 2 ? () => _go(_page + 1) : null,
            color: _page < 2 ? cs.primary : cs.onSurface.withOpacity(0.3),
          ),
        ]),
      ),
    );
  }

  Widget _dot(int i, String label, ColorScheme cs) {
    final active = _page == i;
    return GestureDetector(
      onTap: () => _go(i),
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? cs.primary : cs.onSurface.withOpacity(0.45),
        )),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 8 : 6, height: active ? 8 : 6,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: active ? cs.primary : cs.onSurface.withOpacity(0.25)),
        ),
      ]),
    );
  }
}
