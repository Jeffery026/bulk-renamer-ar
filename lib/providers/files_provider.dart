import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum SortBy { name, date, size, extension }
enum SortOrder { ascending, descending }

class FileItem {
  final File file;
  bool selected;
  FileItem({required this.file, this.selected = false});
  String get name => file.path.split('/').last;
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }
}

class FilesProvider extends ChangeNotifier {
  List<FileItem> _items = [];
  String _currentPath = '/storage/emulated/0';
  List<String> _pathHistory = [];
  SortBy _sortBy = SortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  String _searchQuery = '';
  bool _showHidden = false;
  bool _permissionGranted = false;
  String? _outputPath;
  bool _deleteOriginal = false;

  List<FileItem> get items => _filteredAndSorted();
  List<FileItem> get selectedItems => _items.where((f) => f.selected).toList();
  int get selectedCount => _items.where((f) => f.selected).length;
  String get currentPath => _currentPath;
  List<String> get pathHistory => _pathHistory;
  SortBy get sortBy => _sortBy;
  SortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;
  bool get showHidden => _showHidden;
  bool get permissionGranted => _permissionGranted;
  String? get outputPath => _outputPath;
  bool get deleteOriginal => _deleteOriginal;
  bool get canGoBack => _pathHistory.isNotEmpty;

  List<FileItem> _filteredAndSorted() {
    var list = _items.where((f) {
      if (!_showHidden && f.name.startsWith('.')) return false;
      if (_searchQuery.isNotEmpty && !f.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case SortBy.name: cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase()); break;
        case SortBy.date: cmp = a.file.statSync().modified.compareTo(b.file.statSync().modified); break;
        case SortBy.size: cmp = a.file.lengthSync().compareTo(b.file.lengthSync()); break;
        case SortBy.extension: cmp = a.extension.compareTo(b.extension); break;
      }
      return _sortOrder == SortOrder.ascending ? cmp : -cmp;
    });
    return list;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        final legacy = await Permission.storage.request();
        _permissionGranted = legacy.isGranted;
      } else {
        _permissionGranted = true;
      }
    } else {
      _permissionGranted = true;
    }
    notifyListeners();
    return _permissionGranted;
  }

  Future<void> loadDirectory(String path) async {
    if (!_permissionGranted) await requestPermission();
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      final entries = dir.listSync();
      _items = entries
          .whereType<File>()
          .map((f) => FileItem(file: f))
          .toList();
      _currentPath = path;
      notifyListeners();
    } catch (_) {}
  }

  Future<List<Directory>> getSubDirectories(String path) async {
    try {
      return Directory(path).listSync().whereType<Directory>().toList();
    } catch (_) { return []; }
  }

  void navigateTo(String path) {
    _pathHistory.add(_currentPath);
    loadDirectory(path);
  }

  void navigateBack() {
    if (_pathHistory.isNotEmpty) {
      loadDirectory(_pathHistory.removeLast());
      notifyListeners();
    }
  }

  void toggleSelect(FileItem item) {
    item.selected = !item.selected;
    notifyListeners();
  }

  void selectAll() {
    for (final f in _items) { f.selected = true; }
    notifyListeners();
  }

  void clearSelection() {
    for (final f in _items) { f.selected = false; }
    notifyListeners();
  }

  void setSort(SortBy by, SortOrder order) {
    _sortBy = by; _sortOrder = order; notifyListeners();
  }

  void setSearch(String q) { _searchQuery = q; notifyListeners(); }
  void toggleHidden() { _showHidden = !_showHidden; notifyListeners(); }
  void setOutputPath(String? path) { _outputPath = path; notifyListeners(); }
  void setDeleteOriginal(bool v) { _deleteOriginal = v; notifyListeners(); }

  List<Directory> getStorageRoots() {
    final roots = <Directory>[];
    final internal = Directory('/storage/emulated/0');
    if (internal.existsSync()) roots.add(internal);
    final sd = Directory('/storage');
    if (sd.existsSync()) {
      for (final d in sd.listSync().whereType<Directory>()) {
        if (d.path != '/storage/emulated' && d.path != '/storage/self') roots.add(d);
      }
    }
    return roots;
  }
}
