// ═══════════════════════════════════════════════════════════════
// نموذج إعداد العمليات — يحتوي على كل خيارات إعادة التسمية
// ═══════════════════════════════════════════════════════════════

enum IndexPosition { before, after }
enum DatePosition { before, after }
enum CaseType { upper, lower, title, sentence, camel }
enum RemoveByType { letters, numbers, spaces, nonLetters, nonNumbers, all }
enum TrimPosition { start, end, both }
enum AddPositionMode { before, after, custom }

class PrefixConfig {
  bool enabled;
  String text;
  PrefixConfig({this.enabled = false, this.text = ''});
  PrefixConfig copyWith({bool? enabled, String? text}) =>
      PrefixConfig(enabled: enabled ?? this.enabled, text: text ?? this.text);
}

class SuffixConfig {
  bool enabled;
  String text;
  SuffixConfig({this.enabled = false, this.text = ''});
  SuffixConfig copyWith({bool? enabled, String? text}) =>
      SuffixConfig(enabled: enabled ?? this.enabled, text: text ?? this.text);
}

class AddAtPositionConfig {
  bool enabled;
  String text;
  int position;
  AddAtPositionConfig({this.enabled = false, this.text = '', this.position = 0});
  AddAtPositionConfig copyWith({bool? enabled, String? text, int? position}) =>
      AddAtPositionConfig(
        enabled: enabled ?? this.enabled,
        text: text ?? this.text,
        position: position ?? this.position,
      );
}

class AddDateConfig {
  bool enabled;
  DatePosition position;
  String separator;
  bool year, month, day, hour, minute, second;
  AddDateConfig({
    this.enabled = false,
    this.position = DatePosition.before,
    this.separator = '-',
    this.year = true,
    this.month = true,
    this.day = true,
    this.hour = false,
    this.minute = false,
    this.second = false,
  });
  AddDateConfig copyWith({
    bool? enabled, DatePosition? position, String? separator,
    bool? year, bool? month, bool? day, bool? hour, bool? minute, bool? second,
  }) => AddDateConfig(
    enabled: enabled ?? this.enabled,
    position: position ?? this.position,
    separator: separator ?? this.separator,
    year: year ?? this.year,
    month: month ?? this.month,
    day: day ?? this.day,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    second: second ?? this.second,
  );
}

class AutoIndexConfig {
  bool enabled;
  int startIndex;
  int step;
  int zeroPad;
  IndexPosition position;
  String separator;
  AutoIndexConfig({
    this.enabled = false,
    this.startIndex = 1,
    this.step = 1,
    this.zeroPad = 0,
    this.position = IndexPosition.before,
    this.separator = '_',
  });
  AutoIndexConfig copyWith({
    bool? enabled, int? startIndex, int? step,
    int? zeroPad, IndexPosition? position, String? separator,
  }) => AutoIndexConfig(
    enabled: enabled ?? this.enabled,
    startIndex: startIndex ?? this.startIndex,
    step: step ?? this.step,
    zeroPad: zeroPad ?? this.zeroPad,
    position: position ?? this.position,
    separator: separator ?? this.separator,
  );
}

// ── Remove ──────────────────────────────────────────────────────

class RemoveFromStartConfig {
  bool enabled;
  int count;
  RemoveFromStartConfig({this.enabled = false, this.count = 1});
  RemoveFromStartConfig copyWith({bool? enabled, int? count}) =>
      RemoveFromStartConfig(enabled: enabled ?? this.enabled, count: count ?? this.count);
}

class RemoveFromEndConfig {
  bool enabled;
  int count;
  RemoveFromEndConfig({this.enabled = false, this.count = 1});
  RemoveFromEndConfig copyWith({bool? enabled, int? count}) =>
      RemoveFromEndConfig(enabled: enabled ?? this.enabled, count: count ?? this.count);
}

class RemoveAtPositionConfig {
  bool enabled;
  int start;
  int count;
  RemoveAtPositionConfig({this.enabled = false, this.start = 0, this.count = 1});
  RemoveAtPositionConfig copyWith({bool? enabled, int? start, int? count}) =>
      RemoveAtPositionConfig(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        count: count ?? this.count,
      );
}

class RemoveByTypeConfig {
  bool enabled;
  RemoveByType type;
  RemoveByTypeConfig({this.enabled = false, this.type = RemoveByType.numbers});
  RemoveByTypeConfig copyWith({bool? enabled, RemoveByType? type}) =>
      RemoveByTypeConfig(enabled: enabled ?? this.enabled, type: type ?? this.type);
}

class RemoveCharsConfig {
  bool enabled;
  String chars;
  RemoveCharsConfig({this.enabled = false, this.chars = ''});
  RemoveCharsConfig copyWith({bool? enabled, String? chars}) =>
      RemoveCharsConfig(enabled: enabled ?? this.enabled, chars: chars ?? this.chars);
}

class RemoveTrimConfig {
  bool enabled;
  TrimPosition position;
  RemoveTrimConfig({this.enabled = false, this.position = TrimPosition.both});
  RemoveTrimConfig copyWith({bool? enabled, TrimPosition? position}) =>
      RemoveTrimConfig(enabled: enabled ?? this.enabled, position: position ?? this.position);
}

class RemoveRegexConfig {
  bool enabled;
  String pattern;
  RemoveRegexConfig({this.enabled = false, this.pattern = ''});
  RemoveRegexConfig copyWith({bool? enabled, String? pattern}) =>
      RemoveRegexConfig(enabled: enabled ?? this.enabled, pattern: pattern ?? this.pattern);
}

// ── Change ──────────────────────────────────────────────────────

class ChangeBaseNameConfig {
  bool enabled;
  String newName;
  ChangeBaseNameConfig({this.enabled = false, this.newName = ''});
  ChangeBaseNameConfig copyWith({bool? enabled, String? newName}) =>
      ChangeBaseNameConfig(enabled: enabled ?? this.enabled, newName: newName ?? this.newName);
}

class ChangeExtensionConfig {
  bool enabled;
  String newExtension;
  ChangeExtensionConfig({this.enabled = false, this.newExtension = ''});
  ChangeExtensionConfig copyWith({bool? enabled, String? newExtension}) =>
      ChangeExtensionConfig(enabled: enabled ?? this.enabled, newExtension: newExtension ?? this.newExtension);
}

class ChangeCaseConfig {
  bool enabled;
  CaseType type;
  ChangeCaseConfig({this.enabled = false, this.type = CaseType.lower});
  ChangeCaseConfig copyWith({bool? enabled, CaseType? type}) =>
      ChangeCaseConfig(enabled: enabled ?? this.enabled, type: type ?? this.type);
}

class ReplaceTextConfig {
  bool enabled;
  String find;
  String replace;
  bool caseSensitive;
  ReplaceTextConfig({
    this.enabled = false,
    this.find = '',
    this.replace = '',
    this.caseSensitive = false,
  });
  ReplaceTextConfig copyWith({
    bool? enabled, String? find, String? replace, bool? caseSensitive,
  }) => ReplaceTextConfig(
    enabled: enabled ?? this.enabled,
    find: find ?? this.find,
    replace: replace ?? this.replace,
    caseSensitive: caseSensitive ?? this.caseSensitive,
  );
}

class ReplaceRegexConfig {
  bool enabled;
  String pattern;
  String replacement;
  ReplaceRegexConfig({this.enabled = false, this.pattern = '', this.replacement = ''});
  ReplaceRegexConfig copyWith({bool? enabled, String? pattern, String? replacement}) =>
      ReplaceRegexConfig(
        enabled: enabled ?? this.enabled,
        pattern: pattern ?? this.pattern,
        replacement: replacement ?? this.replacement,
      );
}

// ── Master Config ────────────────────────────────────────────────

class OperationConfig {
  String name;
  // Add
  PrefixConfig prefix;
  SuffixConfig suffix;
  AddAtPositionConfig addAtPosition;
  AddDateConfig addDate;
  AutoIndexConfig autoIndex;
  // Remove
  RemoveFromStartConfig removeFromStart;
  RemoveFromEndConfig removeFromEnd;
  RemoveAtPositionConfig removeAtPosition;
  RemoveByTypeConfig removeByType;
  RemoveCharsConfig removeChars;
  RemoveTrimConfig removeTrim;
  RemoveRegexConfig removeRegex;
  // Change
  ChangeBaseNameConfig changeBaseName;
  ChangeExtensionConfig changeExtension;
  ChangeCaseConfig changeCase;
  ReplaceTextConfig replaceText;
  ReplaceRegexConfig replaceRegex;

  OperationConfig({
    this.name = 'إعداد جديد',
    PrefixConfig? prefix,
    SuffixConfig? suffix,
    AddAtPositionConfig? addAtPosition,
    AddDateConfig? addDate,
    AutoIndexConfig? autoIndex,
    RemoveFromStartConfig? removeFromStart,
    RemoveFromEndConfig? removeFromEnd,
    RemoveAtPositionConfig? removeAtPosition,
    RemoveByTypeConfig? removeByType,
    RemoveCharsConfig? removeChars,
    RemoveTrimConfig? removeTrim,
    RemoveRegexConfig? removeRegex,
    ChangeBaseNameConfig? changeBaseName,
    ChangeExtensionConfig? changeExtension,
    ChangeCaseConfig? changeCase,
    ReplaceTextConfig? replaceText,
    ReplaceRegexConfig? replaceRegex,
  })  : prefix = prefix ?? PrefixConfig(),
        suffix = suffix ?? SuffixConfig(),
        addAtPosition = addAtPosition ?? AddAtPositionConfig(),
        addDate = addDate ?? AddDateConfig(),
        autoIndex = autoIndex ?? AutoIndexConfig(),
        removeFromStart = removeFromStart ?? RemoveFromStartConfig(),
        removeFromEnd = removeFromEnd ?? RemoveFromEndConfig(),
        removeAtPosition = removeAtPosition ?? RemoveAtPositionConfig(),
        removeByType = removeByType ?? RemoveByTypeConfig(),
        removeChars = removeChars ?? RemoveCharsConfig(),
        removeTrim = removeTrim ?? RemoveTrimConfig(),
        removeRegex = removeRegex ?? RemoveRegexConfig(),
        changeBaseName = changeBaseName ?? ChangeBaseNameConfig(),
        changeExtension = changeExtension ?? ChangeExtensionConfig(),
        changeCase = changeCase ?? ChangeCaseConfig(),
        replaceText = replaceText ?? ReplaceTextConfig(),
        replaceRegex = replaceRegex ?? ReplaceRegexConfig();

  bool get hasAnyEnabled =>
      prefix.enabled || suffix.enabled || addAtPosition.enabled ||
      addDate.enabled || autoIndex.enabled || removeFromStart.enabled ||
      removeFromEnd.enabled || removeAtPosition.enabled || removeByType.enabled ||
      removeChars.enabled || removeTrim.enabled || removeRegex.enabled ||
      changeBaseName.enabled || changeExtension.enabled || changeCase.enabled ||
      replaceText.enabled || replaceRegex.enabled;
}
