import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:provider/provider.dart';

import '../../core/models/editor_tab.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

/// The main code-editing surface for [tab]: syntax highlighting, line
/// numbers / folding gutter, word wrap, and undo-snapshot recording.
///
/// [AutomaticKeepAliveClientMixin] preserves scroll position and avoids
/// rebuilding the controller when the user switches between tabs in the
/// [IndexedStack].
class CodeEditorView extends StatefulWidget {
  const CodeEditorView({super.key, required this.tab});

  final EditorTab tab;

  @override
  State<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends State<CodeEditorView>
    with AutomaticKeepAliveClientMixin {
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.tab.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant CodeEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      oldWidget.tab.controller.removeListener(_onChanged);
      widget.tab.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.tab.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    // Notify the provider so tab dirty-state indicators refresh.
    context.read<EditorProvider>().touch();

    // Debounce: record undo snapshot and optionally auto-save ~600 ms after
    // the user stops typing.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final editor = context.read<EditorProvider>();
      editor.recordUndoSnapshot();
      if (context.read<SettingsProvider>().autoSave) {
        editor.saveActiveTab();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();

    return CodeTheme(
      data: CodeThemeData(styles: themeProvider.codeHighlightStyles),
      child: SizedBox.expand(
        child: CodeField(
          controller: widget.tab.controller,
          expands: true,
          wrap: settings.wordWrap,
          background: themeProvider.editorBackground,
          textStyle: settings.editorTextStyle(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          gutterStyle: settings.showLineNumbers
              ? const GutterStyle(
                  showLineNumbers: true,
                  showFoldingHandles: true,
                  showErrors: false,
                )
              : GutterStyle.none,
        ),
      ),
    );
  }
}
