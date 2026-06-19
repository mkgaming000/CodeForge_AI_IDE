import 'package:flutter/widgets.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// A [CodeController] that adds smart-editing behaviours on top of syntax
/// highlighting and code folding:
///
///  * **Auto-indent** — pressing Enter copies the indentation of the previous
///    line, increasing it by [tabSize] spaces after an opening bracket or a
///    trailing colon (Python-style blocks). When the cursor sits between a
///    matching bracket pair the closing bracket is pushed to its own line.
///  * **Auto-close brackets & quotes** — typing `(`, `[`, `{`, `"` or `'`
///    inserts the matching closing character.
///  * **Skip-over** — typing a closing character that immediately follows the
///    cursor advances the cursor past it rather than inserting a duplicate.
///
/// Both behaviours can be toggled at runtime via [autoIndent] and
/// [autoCloseBrackets] to reflect the user's Settings preferences.
class SmartCodeController extends CodeController {
  SmartCodeController({
    super.text,
    super.language,
    this.autoIndent = true,
    this.autoCloseBrackets = true,
    this.tabSize = 4,
  }) {
    // The super constructor body has completed at this point (Dart guarantees
    // super() runs before the subclass constructor body), so addListener is safe.
    _previousValue = value;
    addListener(_handleChange);
  }

  bool autoIndent;
  bool autoCloseBrackets;
  int tabSize;

  late TextEditingValue _previousValue;
  bool _isInternalChange = false;

  static const Map<String, String> _openToClose = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  };

  static const Set<String> _skippable = {')', ']', '}', '"', "'"};

  void _handleChange() {
    if (_isInternalChange) {
      _previousValue = value;
      return;
    }

    final newValue = value;
    final oldValue = _previousValue;
    _previousValue = newValue;

    // Only react to a single-character insertion with a collapsed caret.
    if (newValue.text.length != oldValue.text.length + 1) return;
    final selection = newValue.selection;
    if (!selection.isCollapsed) return;

    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > newValue.text.length) return;

    final insertedChar = newValue.text[cursor - 1];

    if (insertedChar == '\n') {
      if (autoIndent) _handleAutoIndent(newValue, cursor);
      return;
    }

    if (!autoCloseBrackets) return;

    // Skip-over: if the just-typed closing char was already there, advance
    // the cursor past it instead of inserting a duplicate.
    if (_skippable.contains(insertedChar) &&
        cursor < newValue.text.length &&
        newValue.text[cursor] == insertedChar &&
        cursor - 1 < oldValue.text.length &&
        oldValue.text[cursor - 1] == insertedChar) {
      _skipOver(newValue, cursor);
      return;
    }

    if (_openToClose.containsKey(insertedChar)) {
      _autoClose(newValue, cursor, insertedChar);
    }
  }

  void _handleAutoIndent(TextEditingValue newValue, int cursor) {
    final text = newValue.text;
    final newlineIndex = cursor - 1;

    int lineStart = newlineIndex;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final previousLine = text.substring(lineStart, newlineIndex);

    final indentMatch = RegExp(r'^[ \t]*').firstMatch(previousLine);
    final currentIndent = indentMatch?.group(0) ?? '';

    final trimmed = previousLine.trimRight();
    final lastChar = trimmed.isEmpty ? '' : trimmed[trimmed.length - 1];
    final opensBlock =
        lastChar == '{' || lastChar == '[' || lastChar == '(' || trimmed.endsWith(':');

    final nextIndent = opensBlock ? '$currentIndent${' ' * tabSize}' : currentIndent;

    final charAfterCursor = cursor < text.length ? text[cursor] : '';
    final closesPair = (lastChar == '{' && charAfterCursor == '}') ||
        (lastChar == '[' && charAfterCursor == ']') ||
        (lastChar == '(' && charAfterCursor == ')');

    if (nextIndent.isEmpty && !closesPair) return;

    final insertion = closesPair ? '$nextIndent\n$currentIndent' : nextIndent;
    final newCursor = cursor + nextIndent.length;
    final newText = text.replaceRange(cursor, cursor, insertion);

    _setValue(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    ));
  }

  void _autoClose(TextEditingValue newValue, int cursor, String openChar) {
    if (cursor >= 2 && newValue.text[cursor - 2] == r'\') return;
    final closeChar = _openToClose[openChar]!;
    final newText = newValue.text.replaceRange(cursor, cursor, closeChar);
    _setValue(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    ));
  }

  void _skipOver(TextEditingValue newValue, int cursor) {
    final newText = newValue.text.replaceRange(cursor - 1, cursor, '');
    _setValue(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    ));
  }

  void _setValue(TextEditingValue v) {
    _isInternalChange = true;
    value = v;
    _previousValue = v;
    _isInternalChange = false;
  }

  @override
  void dispose() {
    removeListener(_handleChange);
    super.dispose();
  }
}
