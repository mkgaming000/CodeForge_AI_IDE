import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/models/editor_tab.dart';
import '../core/models/file_node.dart';
import '../core/services/file_system_service.dart';
import '../core/services/language_registry.dart';

/// A single search match: the offset where it starts and how many
/// characters it spans (regex matches can vary in length).
class TextMatch {
  const TextMatch(this.start, this.length);

  final int start;
  final int length;
}

/// Manages the set of open editor tabs: opening/closing/saving files,
/// undo/redo history, and find & replace within the active tab.
class EditorProvider extends ChangeNotifier {
  EditorProvider({
    required this.tabSize,
    required this.autoIndent,
    required this.autoCloseBrackets,
  });

  int tabSize;
  bool autoIndent;
  bool autoCloseBrackets;

  final FileSystemService _fs = FileSystemService.instance;

  final List<EditorTab> _tabs = [];
  int _activeIndex = -1;

  List<EditorTab> get tabs => List.unmodifiable(_tabs);
  EditorTab? get activeTab => (_activeIndex >= 0 && _activeIndex < _tabs.length) ? _tabs[_activeIndex] : null;
  int get activeIndex => _activeIndex;
  bool get hasOpenTabs => _tabs.isNotEmpty;
  bool get hasUnsavedChanges => _tabs.any((t) => t.isDirty);

  /// Notifies listeners that the active tab's content changed (e.g. the
  /// user typed a character). Used to refresh dirty-state indicators in the
  /// tab bar without the editor view managing that UI itself.
  void touch() => notifyListeners();

  /// Opens [node] in a new tab, or switches to it if already open.
  Future<void> openFile(FileNode node) async {
    final existingIndex = _tabs.indexWhere((t) => t.filePath == node.path);
    if (existingIndex != -1) {
      _activeIndex = existingIndex;
      notifyListeners();
      return;
    }

    String content;
    try {
      content = await _fs.readFile(node.path);
    } catch (e) {
      throw FileSystemException('Could not open file: $e', node.path);
    }

    final language = LanguageRegistry.forFile(extension: node.extension, fileName: node.name);
    final tab = EditorTab(
      filePath: node.path,
      fileName: node.name,
      language: language,
      initialContent: content,
      tabSize: tabSize,
      autoIndent: autoIndent,
      autoCloseBrackets: autoCloseBrackets,
    );

    _tabs.add(tab);
    if (_tabs.length > AppConstants.maxOpenTabs) {
      _tabs.removeAt(0).dispose();
    }
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void setActiveIndex(int index) {
    if (index < 0 || index >= _tabs.length || index == _activeIndex) return;
    _activeIndex = index;
    notifyListeners();
  }

  /// Closes the tab at [index]. Returns `false` without closing if the tab
  /// has unsaved changes and [force] is `false` — the caller should confirm
  /// with the user (and either save first or retry with `force: true`).
  bool closeTab(int index, {bool force = false}) {
    if (index < 0 || index >= _tabs.length) return false;
    final tab = _tabs[index];
    if (tab.isDirty && !force) return false;

    tab.dispose();
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _activeIndex = -1;
    } else if (index <= _activeIndex) {
      _activeIndex = (_activeIndex - 1).clamp(0, _tabs.length - 1).toInt();
    }
    notifyListeners();
    return true;
  }

  Future<void> saveTab(int index) async {
    if (index < 0 || index >= _tabs.length) return;
    final tab = _tabs[index];
    if (!tab.isDirty) return;
    await _fs.writeFile(tab.filePath, tab.controller.fullText);
    tab.markSaved();
    notifyListeners();
  }

  Future<void> saveActiveTab() => _activeIndex == -1 ? Future.value() : saveTab(_activeIndex);

  Future<void> saveAll() async {
    for (var i = 0; i < _tabs.length; i++) {
      await saveTab(i);
    }
  }

  void closeAllTabs({bool force = false}) {
    if (!force && hasUnsavedChanges) return;
    for (final tab in _tabs) {
      tab.dispose();
    }
    _tabs.clear();
    _activeIndex = -1;
    notifyListeners();
  }

  /// Applies new editor settings (e.g. from the Settings screen) to every
  /// open tab's controller.
  void updateEditorSettings({int? tabSize, bool? autoIndent, bool? autoCloseBrackets}) {
    if (tabSize != null) this.tabSize = tabSize;
    if (autoIndent != null) this.autoIndent = autoIndent;
    if (autoCloseBrackets != null) this.autoCloseBrackets = autoCloseBrackets;
    for (final tab in _tabs) {
      tab.controller.tabSize = this.tabSize;
      tab.controller.autoIndent = this.autoIndent;
      tab.controller.autoCloseBrackets = this.autoCloseBrackets;
    }
  }

  // ------------------------------------------------------------------
  // Undo / Redo
  // ------------------------------------------------------------------

  bool get canUndo => activeTab?.undoRedo.canUndo ?? false;
  bool get canRedo => activeTab?.undoRedo.canRedo ?? false;

  /// Records the current state of the active tab for undo/redo. The editor
  /// UI calls this on a short debounce as the user types.
  void recordUndoSnapshot() {
    activeTab?.undoRedo.push(activeTab!.controller.value);
  }

  void undo() {
    final tab = activeTab;
    if (tab == null) return;
    final value = tab.undoRedo.undo();
    if (value != null) {
      tab.controller.value = value;
      notifyListeners();
    }
  }

  void redo() {
    final tab = activeTab;
    if (tab == null) return;
    final value = tab.undoRedo.redo();
    if (value != null) {
      tab.controller.value = value;
      notifyListeners();
    }
  }

  /// Replaces the active tab's entire content (e.g. after an AI edit),
  /// recording the change for undo.
  void replaceActiveContent(String newContent) {
    final tab = activeTab;
    if (tab == null) return;
    tab.undoRedo.push(tab.controller.value);
    tab.controller.value = TextEditingValue(
      text: newContent,
      selection: TextSelection.collapsed(offset: newContent.length),
    );
    tab.undoRedo.push(tab.controller.value);
    notifyListeners();
  }

  /// Inserts [text] at the active tab's cursor, replacing the current
  /// selection if there is one. Returns `false` if there is no open tab.
  /// Used by the AI panel's "Insert into editor" action on code blocks.
  bool insertTextAtCursor(String text) {
    final tab = activeTab;
    if (tab == null) return false;

    final controller = tab.controller;
    final source = controller.fullText;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start.clamp(0, source.length).toInt() : source.length;
    final end = selection.isValid ? selection.end.clamp(0, source.length).toInt() : source.length;

    final newText = source.replaceRange(start, end, text);
    tab.undoRedo.push(controller.value);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    tab.undoRedo.push(controller.value);
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------------
  // Find & Replace (operates on the active tab)
  // ------------------------------------------------------------------

  /// Returns every match of [query] in the active tab's text, as
  /// (start, length) pairs.
  List<TextMatch> findAll(String query, {bool caseSensitive = false, bool useRegex = false}) {
    final tab = activeTab;
    if (tab == null || query.isEmpty) return const [];
    final text = tab.controller.fullText;

    if (useRegex) {
      try {
        final regex = RegExp(query, caseSensitive: caseSensitive);
        return regex.allMatches(text).map((m) => TextMatch(m.start, m.end - m.start)).toList();
      } catch (_) {
        return const [];
      }
    }

    final haystack = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    if (needle.isEmpty) return const [];

    final matches = <TextMatch>[];
    var index = haystack.indexOf(needle);
    while (index != -1) {
      matches.add(TextMatch(index, needle.length));
      index = haystack.indexOf(needle, index + needle.length);
    }
    return matches;
  }

  /// Selects (highlights) [match] in the active tab.
  void selectMatch(TextMatch match) {
    final tab = activeTab;
    if (tab == null) return;
    final text = tab.controller.fullText;
    final start = match.start.clamp(0, text.length).toInt();
    final end = (match.start + match.length).clamp(0, text.length).toInt();
    tab.controller.selection = TextSelection(baseOffset: start, extentOffset: end);
    notifyListeners();
  }

  /// Replaces the text at `[offset, offset + oldLength)` with [replacement]
  /// and places the cursor immediately after it.
  void replaceRange(int offset, int oldLength, String replacement) {
    final tab = activeTab;
    if (tab == null) return;
    final text = tab.controller.fullText;
    if (offset < 0 || offset + oldLength > text.length) return;

    final newText = text.replaceRange(offset, offset + oldLength, replacement);
    tab.undoRedo.push(tab.controller.value);
    tab.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + replacement.length),
    );
    tab.undoRedo.push(tab.controller.value);
    notifyListeners();
  }

  /// Replaces every occurrence of [query] with [replacement] in the active
  /// tab. Returns the number of replacements made.
  int replaceAll(String query, String replacement, {bool caseSensitive = false, bool useRegex = false}) {
    final tab = activeTab;
    if (tab == null || query.isEmpty) return 0;
    final text = tab.controller.fullText;

    RegExp regex;
    try {
      regex = useRegex ? RegExp(query, caseSensitive: caseSensitive) : RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
    } catch (_) {
      return 0;
    }

    final count = regex.allMatches(text).length;
    if (count == 0) return 0;

    final newText = text.replaceAll(regex, replacement);
    tab.undoRedo.push(tab.controller.value);
    tab.controller.value = TextEditingValue(text: newText, selection: const TextSelection.collapsed(offset: 0));
    tab.undoRedo.push(tab.controller.value);
    notifyListeners();
    return count;
  }
}
