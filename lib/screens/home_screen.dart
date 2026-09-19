import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/files_provider.dart';
import 'browser/browser_screen.dart';
import 'operations/operations_screen.dart';
import 'preview/preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _S();
}

class _S extends State<HomeScreen> {
  final _ctrl = PageController();
  int _page = 0;

  void _go(int p) => _ctrl.animateToPage(p,
      duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: PageView(
        controller: _ctrl,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => _page = p),
        children: const [BrowserScreen(), OperationsScreen(), PreviewScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: _go,
        height: 62,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'الملفات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'الخيارات',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: fp.selectedCount > 0,
              label: Text('${fp.selectedCount}'),
              child: const Icon(Icons.play_circle_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: fp.selectedCount > 0,
              label: Text('${fp.selectedCount}'),
              child: const Icon(Icons.play_circle_rounded),
            ),
            label: 'التنفيذ',
          ),
        ],
      ),
    );
  }
}
