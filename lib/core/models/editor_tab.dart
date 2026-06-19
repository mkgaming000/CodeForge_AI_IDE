import 'package:uuid/uuid.dart';

import '../services/language_registry.dart';
import '../utils/smart_editing_controller.dart';
import '../utils/undo_redo_stack.dart';

const _uuid = Uuid();

/// Represents a single open tab in the code editor.
///
/// Holds the [controller] backing the visible [CodeField], the file's
/// [language] (for highlighting and AI context), and bookkeeping needed to
/// know whether the file has unsaved changes.
class EditorTab {
  EditorTab({
    required this.filePath,
    required this.fileName,
    required this.language,
    required String initialContent,
    int tabSize = 4,
    bool autoIndent = true,
    bool autoCloseBrackets = true,
  })  : id = _uuid.v4(),
        savedContent = initialContent,
        undoRedo = UndoRedoStack(),
        controller = SmartCodeController(
          text: initialContent,
          language: language.mode,
          tabSize: tabSize,
          autoIndent: autoIndent,
          autoCloseBrackets: autoCloseBrackets,
        ) {
    undoRedo.reset(controller.value);
  }

  /// Stable identifier for this tab (used for keys / equality).
  final String id;

  /// Absolute path of the file on disk.
  final String filePath;

  /// Display name shown in the tab bar (file name with extension).
  final String fileName;

  /// Language definition used for highlighting, comments, and AI context.
  final LanguageDefinition language;

  /// The controller that backs the [CodeField] for this tab.
  final SmartCodeController controller;

  /// History of edits for undo/redo.
  final UndoRedoStack undoRedo;

  /// File contents as of the last successful save (or initial load).
  String savedContent;

  /// True if the in-memory content differs from [savedContent].
  bool get isDirty => controller.fullText != savedContent;

  /// Marks the current content as saved.
  void markSaved() {
    savedContent = controller.fullText;
  }

  void dispose() {
    controller.dispose();
  }

  @override
  bool operator ==(Object other) => other is EditorTab && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
