import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/models/file_node.dart';
import '../providers/editor_provider.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/ai/ai_chat_panel.dart';
import '../widgets/common/app_dialogs.dart';
import '../widgets/editor/code_editor_view.dart';
import '../widgets/editor/editor_tab_bar.dart';
import '../widgets/editor/find_replace_bar.dart';
import '../widgets/explorer/file_explorer_panel.dart';

/// The main IDE screen: file explorer drawer, open-file tab bar, the active
/// code editor, an optional find/replace bar, and the AI assistant panel.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _showFindBar = false;

  Future<void> _openFile(FileNode node) async {
    try {
      await context.read<EditorProvider>().openFile(node);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, e.toString().replaceFirst(RegExp(r'^(FileSystemException|Exception):\s*'), ''));
    }
  }

  Future<void> _save(EditorProvider editor) async {
    if (editor.activeTab == null) return;
    await editor.saveActiveTab();
    if (mounted) AppDialogs.showMessage(context, 'Saved');
  }

  Future<void> _saveAll(EditorProvider editor) async {
    await editor.saveAll();
    if (mounted) AppDialogs.showMessage(context, 'All files saved');
  }

  Future<void> _closeAllTabs(EditorProvider editor) async {
    if (editor.hasUnsavedChanges) {
      final proceed = await AppDialogs.confirm(
        context: context,
        title: 'Close all tabs?',
        message: 'Some files have unsaved changes that will be lost.',
        confirmLabel: 'Close All',
        isDestructive: true,
      );
      if (!proceed) return;
    }
    editor.closeAllTabs(force: true);
  }

  Future<void> _jumpToLine(EditorProvider editor) async {
    final tab = editor.activeTab;
    if (tab == null) return;

    final lineStr = await AppDialogs.textInput(
      context: context,
      title: 'Go to Line',
      label: 'Line number',
      confirmLabel: 'Go',
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validate: (v) => v.trim().isEmpty || int.tryParse(v.trim()) == null ? 'Enter a line number' : '',
    );
    if (lineStr == null) return;
    final line = int.tryParse(lineStr.trim());
    if (line == null) return;

    final text = tab.controller.fullText;
    final lines = text.split('\n');
    final targetLine = (line - 1).clamp(0, lines.length - 1).toInt();

    var offset = 0;
    for (var i = 0; i < targetLine; i++) {
      offset += lines[i].length + 1;
    }
    offset = offset.clamp(0, text.length).toInt();
    tab.controller.selection = TextSelection.collapsed(offset: offset);
    editor.touch();
  }

  /// Toggles a line-comment prefix on every non-empty line touched by the
  /// current selection (or the current line, if the selection is collapsed).
  Future<void> _toggleLineComment(EditorProvider editor) async {
    final tab = editor.activeTab;
    if (tab == null) return;

    final lineComment = tab.language.lineComment;
    if (lineComment == null) {
      AppDialogs.showMessage(context, '${tab.language.displayName} has no single-line comment syntax');
      return;
    }

    final controller = tab.controller;
    final text = controller.fullText;
    final selection = controller.selection;
    final selStart = selection.isValid ? selection.start : 0;
    final selEnd = selection.isValid ? selection.end : 0;

    int findLineStart(int offset) {
      var i = offset.clamp(0, text.length).toInt();
      while (i > 0 && text[i - 1] != '\n') {
        i--;
      }
      return i;
    }

    int findLineEnd(int offset) {
      var i = offset.clamp(0, text.length).toInt();
      while (i < text.length && text[i] != '\n') {
        i++;
      }
      return i;
    }

    final regionStart = findLineStart(selStart);
    var endAnchor = selEnd;
    if (endAnchor > regionStart && endAnchor <= text.length && endAnchor > 0 && text[endAnchor - 1] == '\n') {
      endAnchor -= 1;
    }
    final regionEnd = findLineEnd(endAnchor);

    final region = text.substring(regionStart, regionEnd);
    final lines = region.split('\n');
    final nonEmpty = lines.where((l) => l.trim().isNotEmpty).toList();
    final allCommented = nonEmpty.isNotEmpty && nonEmpty.every((l) => l.trimLeft().startsWith(lineComment));

    final newLines = lines.map((l) {
      if (l.trim().isEmpty) return l;
      final trimmed = l.trimLeft();
      final indent = l.substring(0, l.length - trimmed.length);
      if (allCommented) {
        if (trimmed.startsWith('$lineComment ')) {
          return '$indent${trimmed.substring(lineComment.length + 1)}';
        }
        return '$indent${trimmed.substring(lineComment.length)}';
      }
      return '$indent$lineComment $trimmed';
    });

    editor.replaceRange(regionStart, regionEnd - regionStart, newLines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final projects = context.watch<ProjectProvider>();
    final activeTab = editor.activeTab;

    return PopScope(
      canPop: !editor.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final proceed = await AppDialogs.confirm(
          context: context,
          title: 'Unsaved changes',
          message: 'You have unsaved changes. Leave anyway? Unsaved edits will be lost.',
          confirmLabel: 'Leave',
          isDestructive: true,
        );
        if (proceed && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        drawer: FileExplorerPanel(activeFilePath: activeTab?.filePath, onOpenFile: _openFile),
        endDrawer: const AiChatPanel(),
        appBar: AppBar(
          title: Text(projects.currentProjectName ?? 'CodeForge', overflow: TextOverflow.ellipsis),
          actions: [
            if (activeTab != null) ...[
              IconButton(
                tooltip: activeTab.isDirty ? 'Save' : 'Saved',
                icon: Icon(activeTab.isDirty ? Icons.save_outlined : Icons.cloud_done_outlined),
                onPressed: activeTab.isDirty ? () => _save(editor) : null,
              ),
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: editor.canUndo ? editor.undo : null,
              ),
              IconButton(
                tooltip: 'Redo',
                icon: const Icon(Icons.redo),
                onPressed: editor.canRedo ? editor.redo : null,
              ),
              IconButton(
                tooltip: 'Find & Replace',
                icon: Icon(_showFindBar ? Icons.close : Icons.search),
                onPressed: () => setState(() => _showFindBar = !_showFindBar),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'jump':
                      _jumpToLine(editor);
                      break;
                    case 'comment':
                      _toggleLineComment(editor);
                      break;
                    case 'wrap':
                      final settings = context.read<SettingsProvider>();
                      settings.setWordWrap(!settings.wordWrap);
                      break;
                    case 'save_all':
                      _saveAll(editor);
                      break;
                    case 'close_all':
                      _closeAllTabs(editor);
                      break;
                  }
                },
                itemBuilder: (menuContext) {
                  final wordWrap = context.read<SettingsProvider>().wordWrap;
                  return [
                    const PopupMenuItem(value: 'jump', child: ListTile(leading: Icon(Icons.numbers), title: Text('Go to Line'))),
                    const PopupMenuItem(value: 'comment', child: ListTile(leading: Icon(Icons.comment_outlined), title: Text('Toggle Line Comment'))),
                    CheckedPopupMenuItem(
                      value: 'wrap',
                      checked: wordWrap,
                      child: const Text('Word Wrap'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'save_all', child: ListTile(leading: Icon(Icons.save_alt_outlined), title: Text('Save All'))),
                    const PopupMenuItem(value: 'close_all', child: ListTile(leading: Icon(Icons.close), title: Text('Close All Tabs'))),
                  ];
                },
              ),
            ],
            Builder(
              builder: (innerContext) => IconButton(
                tooltip: 'AI Assistant',
                icon: const Icon(Icons.auto_awesome_outlined),
                onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            const EditorTabBar(),
            if (_showFindBar && activeTab != null) FindReplaceBar(onClose: () => setState(() => _showFindBar = false)),
            Expanded(
              child: activeTab == null
                  ? _buildEmptyState(context)
                  : IndexedStack(
                      index: editor.activeIndex,
                      children: [for (final tab in editor.tabs) CodeEditorView(key: ValueKey(tab.id), tab: tab)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No files open',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Open the file explorer to browse your project, or create a new file.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (innerContext) => FilledButton.icon(
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Open Explorer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
