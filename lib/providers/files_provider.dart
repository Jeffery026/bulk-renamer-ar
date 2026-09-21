import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum SortBy { name, date, size, extension }
enum SortOrder { ascending, descending }

class FileItem {
  final FileSystemEntity entity;
  FileItem({required this.entity});
  bool get isDir => entity is Directory;
  bool get isFile => entity is File;
  String get name => entity.path.split('/').last;
  File get file => entity as File;
  String get ext {
    if (isDir) return '';
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }
}

class FilesProvider extends ChangeNotifier {
  List<FileItem> _all = [];
  final Set<String> _selectedPaths = {};
  String _currentPath = '/storage/emulated/0';
  final List<String> _history = [];
  SortBy _sortBy = SortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  String _search = '';
  bool _showHidden = false;
  bool _permissionGranted = false;
  String? _outputPath;
  bool _deleteOriginal = true;
  bool _initialized = false;

  bool get permissionGranted => _permissionGranted;
  bool get canGoBack => _history.isNotEmpty;
  String get currentPath => _currentPath;
  String? get outputPath => _outputPath;
  bool get deleteOriginal => _deleteOriginal;
  bool get showHidden => _showHidden;
  SortOrder get sortOrder => _sortOrder;
  int get selectedCount => _selectedPaths.length;
  bool get initialized => _initialized;

  List<FileItem> get items {
    var list = _all.where((f) {
      if (!_showHidden && f.name.startsWith('.')) return false;
      if (_search.isNotEmpty &&
          !f.name.toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
    final dirs = list.where((f) => f.isDir).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    var files = list.where((f) => f.isFile).toList();
    files.sort((a, b) {
      int c;
      switch (_sortBy) {
        case SortBy.name:
          c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortBy.date:
          c = a.file.statSync().modified
              .compareTo(b.file.statSync().modified);
          break;
        case SortBy.size:
          c = a.file.lengthSync().compareTo(b.file.lengthSync());
          break;
        case SortBy.extension:
          c = a.ext.compareTo(b.ext);
          break;
      }
      return _sortOrder == SortOrder.ascending ? c : -c;
    });
    return [...dirs, ...files];
  }

  bool isSelected(FileItem item) => _selectedPaths.contains(item.entity.path);

  List<File> get selectedFiles => _selectedPaths
      .where((p) => File(p).existsSync())
      .map((p) => File(p))
      .toList();

  List<String> get selectedNames =>
      selectedFiles.map((f) => f.path.split('/').last).toList();

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      var s = await Permission.manageExternalStorage.request();
      if (!s.isGranted) s = await Permission.storage.request();
      _permissionGranted = s.isGranted;
    } else {
      _permissionGranted = true;
    }
    notifyListeners();
    return _permissionGranted;
  }

  Future<void> loadDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      _all = dir.listSync().map((e) => FileItem(entity: e)).toList();
      _currentPath = path;
      _initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  void navigateTo(String path) {
    _history.add(_currentPath);
    loadDirectory(path);
  }

  void navigateBack() {
    if (_history.isNotEmpty) loadDirectory(_history.removeLast());
  }

  void toggleSelect(FileItem item) {
    if (!item.isFile) return;
    final path = item.entity.path;
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    notifyListeners();
  }

  void selectAll() {
    for (final f in _all) {
      if (f.isFile) _selectedPaths.add(f.entity.path);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPaths.clear();
    notifyListeners();
  }

  void setSort(SortBy by, SortOrder order) {
    _sortBy = by;
    _sortOrder = order;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void toggleHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  void setOutputPath(String? p) {
    _outputPath = p;
    notifyListeners();
  }

  void setDeleteOriginal(bool v) {
    _deleteOriginal = v;
    notifyListeners();
  }

  List<Directory> getStorageRoots() {
    final r = <Directory>[];
    final i = Directory('/storage/emulated/0');
    if (i.existsSync()) r.add(i);
    try {
      for (final d in Directory('/storage').listSync().whereType<Directory>()) {
        if (!d.path.contains('emulated') && d.path != '/storage/self') r.add(d);
      }
    } catch (_) {}
    return r;
  }

  List<String> get breadcrumbs {
    final rel =
        _currentPath.replaceFirst(RegExp(r'/storage/emulated/0/?'), '');
    if (rel.isEmpty) return ['الجهاز'];
    return ['الجهاز', ...rel.split('/').where((s) => s.isNotEmpty)];
  }

  void navigateToBreadcrumb(int i) {
    if (i == 0) {
      navigateTo('/storage/emulated/0');
      return;
    }
    final crumbs = breadcrumbs;
    navigateTo('/storage/emulated/0/' + crumbs.sublist(1, i + 1).join('/'));
  }
}
