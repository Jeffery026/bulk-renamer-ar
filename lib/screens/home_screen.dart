import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/files_provider.dart';
import 'browser/browser_screen.dart';
import 'operations/operations_screen.dart';
import 'preview/preview_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    BrowserScreen(), OperationsScreen(), PreviewScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FilesProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'الملفات'),
          const NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'الخيارات'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: fp.selectedCount > 0,
              label: Text('${fp.selectedCount}'),
              child: const Icon(Icons.preview_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: fp.selectedCount > 0,
              label: Text('${fp.selectedCount}'),
              child: const Icon(Icons.preview),
            ),
            label: 'معاينة',
          ),
          const NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
