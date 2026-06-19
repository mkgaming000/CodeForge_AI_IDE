import 'package:flutter/widgets.dart';

/// A simple bounded undo/redo history of [TextEditingValue] snapshots.
///
/// Snapshots are pushed by the editor whenever a "significant" edit occurs
/// (after a pause in typing, or before a large programmatic change such as
/// "Replace All" or an AI-generated edit). [undo] and [redo] return the
/// value that should be restored to the controller, or `null` if there is
/// nothing to do.
class UndoRedoStack {
  UndoRedoStack({this.maxEntries = 200});

  final int maxEntries;

  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];

  /// True if there is a previous state to revert to.
  bool get canUndo => _undoStack.length > 1;

  /// True if a previously undone state can be re-applied.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The most recently pushed snapshot, or `null` if history is empty.
  TextEditingValue? get current => _undoStack.isEmpty ? null : _undoStack.last;

  /// Records a new snapshot. If the text is unchanged from the last
  /// snapshot (e.g. only the cursor moved), the last snapshot's selection is
  /// updated in place instead of growing the stack. Pushing a genuinely new
  /// text state clears the redo stack.
  void push(TextEditingValue value) {
    if (_undoStack.isNotEmpty && _undoStack.last.text == value.text) {
      _undoStack[_undoStack.length - 1] = value;
      return;
    }
    _undoStack.add(value);
    if (_undoStack.length > maxEntries) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Moves the current state to the redo stack and returns the previous
  /// state, or `null` if there is nothing to undo.
  TextEditingValue? undo() {
    if (!canUndo) return null;
    final last = _undoStack.removeLast();
    _redoStack.add(last);
    return _undoStack.last;
  }

  /// Re-applies the most recently undone state.
  TextEditingValue? redo() {
    if (_redoStack.isEmpty) return null;
    final value = _redoStack.removeLast();
    _undoStack.add(value);
    return value;
  }

  /// Resets history, seeding it with [initial] — typically the freshly
  /// loaded file contents.
  void reset(TextEditingValue initial) {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.add(initial);
  }
}
