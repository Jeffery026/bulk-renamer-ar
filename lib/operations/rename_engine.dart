import 'dart:io';
import 'package:intl/intl.dart';
import '../models/operation_config.dart';

class RenameResult {
  final String originalName;
  final String newName;
  final bool hasChange;
  RenameResult({required this.originalName, required this.newName})
      : hasChange = originalName != newName;
}

class RenameEngine {
  static String _baseName(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(0, dot) : filename;
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(dot + 1) : '';
  }

  static String _toTitleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');

  static String _toSentenceCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  static String _toCamelCase(String s) {
    final words = s.split(RegExp(r'[\s_\-]+'));
    if (words.isEmpty) return s;
    return words[0].toLowerCase() +
        words.skip(1).map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
  }

  static String _buildDateString(AddDateConfig cfg, DateTime dt) {
    final parts = <String>[];
    if (cfg.year) parts.add(dt.year.toString());
    if (cfg.month) parts.add(dt.month.toString().padLeft(2, '0'));
    if (cfg.day) parts.add(dt.day.toString().padLeft(2, '0'));
    if (cfg.hour) parts.add(dt.hour.toString().padLeft(2, '0'));
    if (cfg.minute) parts.add(dt.minute.toString().padLeft(2, '0'));
    if (cfg.second) parts.add(dt.second.toString().padLeft(2, '0'));
    return parts.join(cfg.separator);
  }

  static RenameResult apply(String filename, OperationConfig cfg, int index, {DateTime? fileDate}) {
    String base = _baseName(filename);
    String ext = _extension(filename);

    // ── Change Base Name (أول خطوة) ─────────────────────────
    if (cfg.changeBaseName.enabled && cfg.changeBaseName.newName.isNotEmpty) {
      base = cfg.changeBaseName.newName;
    }

    // ── Add Prefix ───────────────────────────────────────────
    if (cfg.prefix.enabled && cfg.prefix.text.isNotEmpty) {
      base = cfg.prefix.text + base;
    }

    // ── Add Suffix ───────────────────────────────────────────
    if (cfg.suffix.enabled && cfg.suffix.text.isNotEmpty) {
      base = base + cfg.suffix.text;
    }

    // ── Add At Position ──────────────────────────────────────
    if (cfg.addAtPosition.enabled && cfg.addAtPosition.text.isNotEmpty) {
      final pos = cfg.addAtPosition.position.clamp(0, base.length);
      base = base.substring(0, pos) + cfg.addAtPosition.text + base.substring(pos);
    }

    // ── Add Date ─────────────────────────────────────────────
    if (cfg.addDate.enabled) {
      final dt = fileDate ?? DateTime.now();
      final dateStr = _buildDateString(cfg.addDate, dt);
      if (cfg.addDate.position == DatePosition.before) {
        base = dateStr + cfg.addDate.separator + base;
      } else {
        base = base + cfg.addDate.separator + dateStr;
      }
    }

    // ── Remove From Start ────────────────────────────────────
    if (cfg.removeFromStart.enabled && cfg.removeFromStart.count > 0) {
      final count = cfg.removeFromStart.count.clamp(0, base.length);
      base = base.substring(count);
    }

    // ── Remove From End ──────────────────────────────────────
    if (cfg.removeFromEnd.enabled && cfg.removeFromEnd.count > 0) {
      final count = cfg.removeFromEnd.count.clamp(0, base.length);
      base = base.substring(0, base.length - count);
    }

    // ── Remove At Position ───────────────────────────────────
    if (cfg.removeAtPosition.enabled && cfg.removeAtPosition.count > 0) {
      final start = cfg.removeAtPosition.start.clamp(0, base.length);
      final end = (start + cfg.removeAtPosition.count).clamp(0, base.length);
      base = base.substring(0, start) + base.substring(end);
    }

    // ── Remove By Type ───────────────────────────────────────
    if (cfg.removeByType.enabled) {
      switch (cfg.removeByType.type) {
        case RemoveByType.letters:
          base = base.replaceAll(RegExp(r'[a-zA-Z\u0600-\u06FF]'), '');
          break;
        case RemoveByType.numbers:
          base = base.replaceAll(RegExp(r'[0-9]'), '');
          break;
        case RemoveByType.spaces:
          base = base.replaceAll(' ', '');
          break;
        case RemoveByType.nonLetters:
          base = base.replaceAll(RegExp(r'[^a-zA-Z\u0600-\u06FF]'), '');
          break;
        case RemoveByType.nonNumbers:
          base = base.replaceAll(RegExp(r'[^0-9]'), '');
          break;
        case RemoveByType.all:
          base = '';
          break;
      }
    }

    // ── Remove Specific Chars ────────────────────────────────
    if (cfg.removeChars.enabled && cfg.removeChars.chars.isNotEmpty) {
      for (final ch in cfg.removeChars.chars.split(',')) {
        if (ch.isNotEmpty) base = base.replaceAll(ch.trim(), '');
      }
    }

    // ── Trim Whitespace ──────────────────────────────────────
    if (cfg.removeTrim.enabled) {
      switch (cfg.removeTrim.position) {
        case TrimPosition.start: base = base.trimLeft(); break;
        case TrimPosition.end:   base = base.trimRight(); break;
        case TrimPosition.both:  base = base.trim(); break;
      }
    }

    // ── Remove by Regex ──────────────────────────────────────
    if (cfg.removeRegex.enabled && cfg.removeRegex.pattern.isNotEmpty) {
      try {
        base = base.replaceAll(RegExp(cfg.removeRegex.pattern), '');
      } catch (_) {}
    }

    // ── Replace Text ─────────────────────────────────────────
    if (cfg.replaceText.enabled && cfg.replaceText.find.isNotEmpty) {
      base = base.replaceAll(
        cfg.replaceText.caseSensitive
            ? cfg.replaceText.find
            : RegExp(RegExp.escape(cfg.replaceText.find), caseSensitive: false),
        cfg.replaceText.replace,
      );
    }

    // ── Replace Regex ────────────────────────────────────────
    if (cfg.replaceRegex.enabled && cfg.replaceRegex.pattern.isNotEmpty) {
      try {
        base = base.replaceAll(RegExp(cfg.replaceRegex.pattern), cfg.replaceRegex.replacement);
      } catch (_) {}
    }

    // ── Change Case ──────────────────────────────────────────
    if (cfg.changeCase.enabled) {
      switch (cfg.changeCase.type) {
        case CaseType.upper:    base = base.toUpperCase(); break;
        case CaseType.lower:    base = base.toLowerCase(); break;
        case CaseType.title:    base = _toTitleCase(base); break;
        case CaseType.sentence: base = _toSentenceCase(base); break;
        case CaseType.camel:    base = _toCamelCase(base); break;
      }
    }

    // ── Change Extension ─────────────────────────────────────
    if (cfg.changeExtension.enabled) {
      ext = cfg.changeExtension.newExtension.replaceAll('.', '');
    }

    // ── Auto Index ───────────────────────────────────────────
    if (cfg.autoIndex.enabled) {
      final n = cfg.autoIndex.startIndex + index * cfg.autoIndex.step;
      final padded = n.toString().padLeft(cfg.autoIndex.zeroPad, '0');
      if (cfg.autoIndex.position == IndexPosition.before) {
        base = padded + cfg.autoIndex.separator + base;
      } else {
        base = base + cfg.autoIndex.separator + padded;
      }
    }

    if (base.isEmpty) base = filename;
    final newName = ext.isEmpty ? base : '$base.$ext';
    return RenameResult(originalName: filename, newName: newName);
  }

  static List<RenameResult> applyAll(List<String> filenames, OperationConfig cfg) {
    return List.generate(filenames.length, (i) => apply(filenames[i], cfg, i));
  }

  static Future<void> executeRename({
    required List<File> files,
    required OperationConfig cfg,
    required String? outputDir,
    required bool deleteOriginal,
    required void Function(int done, int total) onProgress,
    required void Function(String error) onError,
  }) async {
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fname = file.path.split('/').last;
      final result = apply(fname, cfg, i, fileDate: file.statSync().modified);
      try {
        final dir = outputDir ?? file.parent.path;
        final dest = '$dir/${result.newName}';
        if (deleteOriginal) {
          await file.rename(dest);
        } else {
          await file.copy(dest);
        }
      } catch (e) {
        onError('$fname: $e');
      }
      onProgress(i + 1, files.length);
    }
  }
}
