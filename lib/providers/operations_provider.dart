import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/operation_config.dart';

class OperationsProvider extends ChangeNotifier {
  OperationConfig _config = OperationConfig();
  List<String> _savedConfigNames = [];
  int _activeTab = 0;

  OperationConfig get config => _config;
  List<String> get savedConfigNames => _savedConfigNames;
  int get activeTab => _activeTab;

  OperationsProvider() { _loadSavedNames(); }

  void setActiveTab(int t) { _activeTab = t; notifyListeners(); }

  // ── Add ────────────────────────────────────────────────────
  void updatePrefix({bool? enabled, String? text}) {
    _config.prefix = _config.prefix.copyWith(enabled: enabled, text: text);
    notifyListeners();
  }
  void updateSuffix({bool? enabled, String? text}) {
    _config.suffix = _config.suffix.copyWith(enabled: enabled, text: text);
    notifyListeners();
  }
  void updateAddAtPosition({bool? enabled, String? text, int? position}) {
    _config.addAtPosition = _config.addAtPosition.copyWith(enabled: enabled, text: text, position: position);
    notifyListeners();
  }
  void updateAddDate({bool? enabled, DatePosition? position, String? separator,
      bool? year, bool? month, bool? day, bool? hour, bool? minute, bool? second}) {
    _config.addDate = _config.addDate.copyWith(
        enabled: enabled, position: position, separator: separator,
        year: year, month: month, day: day, hour: hour, minute: minute, second: second);
    notifyListeners();
  }
  void updateAutoIndex({bool? enabled, int? startIndex, int? step,
      int? zeroPad, IndexPosition? position, String? separator}) {
    _config.autoIndex = _config.autoIndex.copyWith(
        enabled: enabled, startIndex: startIndex, step: step,
        zeroPad: zeroPad, position: position, separator: separator);
    notifyListeners();
  }

  // ── Remove ─────────────────────────────────────────────────
  void updateRemoveFromStart({bool? enabled, int? count}) {
    _config.removeFromStart = _config.removeFromStart.copyWith(enabled: enabled, count: count);
    notifyListeners();
  }
  void updateRemoveFromEnd({bool? enabled, int? count}) {
    _config.removeFromEnd = _config.removeFromEnd.copyWith(enabled: enabled, count: count);
    notifyListeners();
  }
  void updateRemoveAtPosition({bool? enabled, int? start, int? count}) {
    _config.removeAtPosition = _config.removeAtPosition.copyWith(enabled: enabled, start: start, count: count);
    notifyListeners();
  }
  void updateRemoveByType({bool? enabled, RemoveByType? type}) {
    _config.removeByType = _config.removeByType.copyWith(enabled: enabled, type: type);
    notifyListeners();
  }
  void updateRemoveChars({bool? enabled, String? chars}) {
    _config.removeChars = _config.removeChars.copyWith(enabled: enabled, chars: chars);
    notifyListeners();
  }
  void updateRemoveTrim({bool? enabled, TrimPosition? position}) {
    _config.removeTrim = _config.removeTrim.copyWith(enabled: enabled, position: position);
    notifyListeners();
  }
  void updateRemoveRegex({bool? enabled, String? pattern}) {
    _config.removeRegex = _config.removeRegex.copyWith(enabled: enabled, pattern: pattern);
    notifyListeners();
  }

  // ── Change ─────────────────────────────────────────────────
  void updateChangeBaseName({bool? enabled, String? newName}) {
    _config.changeBaseName = _config.changeBaseName.copyWith(enabled: enabled, newName: newName);
    notifyListeners();
  }
  void updateChangeExtension({bool? enabled, String? newExtension}) {
    _config.changeExtension = _config.changeExtension.copyWith(enabled: enabled, newExtension: newExtension);
    notifyListeners();
  }
  void updateChangeCase({bool? enabled, CaseType? type}) {
    _config.changeCase = _config.changeCase.copyWith(enabled: enabled, type: type);
    notifyListeners();
  }
  void updateReplaceText({bool? enabled, String? find, String? replace, bool? caseSensitive}) {
    _config.replaceText = _config.replaceText.copyWith(
        enabled: enabled, find: find, replace: replace, caseSensitive: caseSensitive);
    notifyListeners();
  }
  void updateReplaceRegex({bool? enabled, String? pattern, String? replacement}) {
    _config.replaceRegex = _config.replaceRegex.copyWith(
        enabled: enabled, pattern: pattern, replacement: replacement);
    notifyListeners();
  }

  void resetAll() { _config = OperationConfig(); notifyListeners(); }

  // ── Save/Load Configs ───────────────────────────────────────
  Future<void> _loadSavedNames() async {
    final prefs = await SharedPreferences.getInstance();
    _savedConfigNames = prefs.getStringList('config_names') ?? [];
    notifyListeners();
  }

  Future<void> saveConfig(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _config.name = name;
    if (!_savedConfigNames.contains(name)) {
      _savedConfigNames.add(name);
      await prefs.setStringList('config_names', _savedConfigNames);
    }
    await prefs.setString('config_$name', _serializeConfig());
    notifyListeners();
  }

  Future<void> loadConfig(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('config_$name');
    if (data != null) {
      _deserializeConfig(data);
      notifyListeners();
    }
  }

  Future<void> deleteConfig(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _savedConfigNames.remove(name);
    await prefs.remove('config_$name');
    await prefs.setStringList('config_names', _savedConfigNames);
    notifyListeners();
  }

  String _serializeConfig() => jsonEncode({
    'prefix': {'enabled': _config.prefix.enabled, 'text': _config.prefix.text},
    'suffix': {'enabled': _config.suffix.enabled, 'text': _config.suffix.text},
    'addAtPos': {'enabled': _config.addAtPosition.enabled, 'text': _config.addAtPosition.text, 'pos': _config.addAtPosition.position},
    'autoIndex': {'enabled': _config.autoIndex.enabled, 'start': _config.autoIndex.startIndex, 'step': _config.autoIndex.step, 'pad': _config.autoIndex.zeroPad, 'pos': _config.autoIndex.position.index, 'sep': _config.autoIndex.separator},
  });

  void _deserializeConfig(String data) {
    try {
      final m = jsonDecode(data) as Map<String, dynamic>;
      if (m['prefix'] != null) _config.prefix = PrefixConfig(enabled: m['prefix']['enabled'], text: m['prefix']['text']);
      if (m['suffix'] != null) _config.suffix = SuffixConfig(enabled: m['suffix']['enabled'], text: m['suffix']['text']);
      if (m['autoIndex'] != null) {
        final ai = m['autoIndex'];
        _config.autoIndex = AutoIndexConfig(enabled: ai['enabled'], startIndex: ai['start'], step: ai['step'], zeroPad: ai['pad'], position: IndexPosition.values[ai['pos']], separator: ai['sep']);
      }
    } catch (_) {}
  }
}
