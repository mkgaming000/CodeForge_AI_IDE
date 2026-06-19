import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/file_node.dart';
import '../../providers/file_explorer_provider.dart';
import '../common/app_dialogs.dart';
import '../common/file_icon.dart';
import 'file_tree_item.dart';

/// The project file explorer, shown as the editor screen's start [Drawer].
///
/// Provides the file tree, name search, and a long-press / "more" context
/// menu on every node for create, rename, duplicate, cut/copy/paste, and
/// delete.
class FileExplorerPanel extends StatefulWidget {
  const FileExplorerPanel({
    super.key,
    required this.activeFilePath,
    required this.onOpenFile,
  });

  final String? activeFilePath;
  final ValueChanged<FileNode> onOpenFile;

  @override
  State<FileExplorerPanel> createState() => _FileExplorerPanelState();
}

class _FileExplorerPanelState extends State<FileExplorerPanel> {
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<FileNode>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchResults = null;
      }
    });
  }

  Future<void> _onSearchChanged(FileExplorerProvider explorer, String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _isSearching = true);
    final results = await explorer.searchByName(trimmed);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  String _friendlyError(Object e) {
    return e.toString().replaceFirst(RegExp(r'^(FileSystemException|Exception):\s*'), '');
  }

  Future<void> _createFile(FileExplorerProvider explorer, FileNode parent) async {
    final name = await AppDialogs.newFileName(context);
    if (name == null) return;
    try {
      await explorer.createFile(parent, name);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  Future<void> _createFolder(FileExplorerProvider explorer, FileNode parent) async {
    final name = await AppDialogs.newFolderName(context);
    if (name == null) return;
    try {
      await explorer.createFolder(parent, name);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  Future<void> _rename(FileExplorerProvider explorer, FileNode node) async {
    final name = await AppDialogs.rename(context, node.name);
    if (name == null || name == node.name) return;
    try {
      await explorer.renameNode(node, name);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  Future<void> _delete(FileExplorerProvider explorer, FileNode node) async {
    final confirmed = await AppDialogs.confirmDelete(context, node.name, isDirectory: node.isDirectory);
    if (!confirmed) return;
    try {
      await explorer.deleteNode(node);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  Future<void> _duplicate(FileExplorerProvider explorer, FileNode node) async {
    try {
      await explorer.duplicateNode(node);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  Future<void> _paste(FileExplorerProvider explorer, FileNode destination) async {
    try {
      await explorer.pasteInto(destination);
    } catch (e) {
      if (mounted) AppDialogs.showError(context, _friendlyError(e));
    }
  }

  void _showNodeMenu(BuildContext context, FileNode node) {
    final explorer = context.read<FileExplorerProvider>();
    final isRoot = node.path == explorer.rootPath;
    final hasClipboard = explorer.clipboardNode != null;
    final errorColor = Theme.of(context).colorScheme.error;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: FileIcon(node: node, size: 22),
                title: Text(node.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(node.path, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Divider(height: 1),
              if (node.isDirectory) ...[
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('New File'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _createFile(explorer, node);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: const Text('New Folder'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _createFolder(explorer, node);
                  },
                ),
              ],
              if (!isRoot) ...[
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _rename(explorer, node);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text('Duplicate'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _duplicate(explorer, node);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: const Text('Cut'),
                  onTap: () {
                    explorer.cutToClipboard(node);
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copy'),
                  onTap: () {
                    explorer.copyToClipboard(node);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
              if (node.isDirectory && hasClipboard)
                ListTile(
                  leading: const Icon(Icons.content_paste_outlined),
                  title: Text(explorer.clipboardIsCut ? 'Paste (move here)' : 'Paste (copy here)'),
                  subtitle: Text(explorer.clipboardNode?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _paste(explorer, node);
                  },
                ),
              if (!isRoot)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: errorColor),
                  title: Text('Delete', style: TextStyle(color: errorColor)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _delete(explorer, node);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final explorer = context.watch<FileExplorerProvider>();
    final root = explorer.root;

    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, explorer, root),
            if (_searchMode) _buildSearchBar(explorer),
            const Divider(height: 1),
            Expanded(
              child: root == null
                  ? const Center(child: Text('No project open'))
                  : (_searchMode && _searchResults != null)
                      ? _buildSearchResults(context, explorer)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: FileTreeItem(
                            node: root,
                            depth: 0,
                            explorer: explorer,
                            onTapFile: widget.onOpenFile,
                            onShowMenu: _showNodeMenu,
                            activeFilePath: widget.activeFilePath,
                          ),
                        ),
            ),
            if (explorer.clipboardNode != null) _buildClipboardBar(context, explorer),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FileExplorerProvider explorer, FileNode? root) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              root?.name ?? 'Explorer',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Search files',
            icon: Icon(_searchMode ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          if (root != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'new_file':
                    _createFile(explorer, root);
                    break;
                  case 'new_folder':
                    _createFolder(explorer, root);
                    break;
                  case 'refresh':
                    explorer.refresh();
                    break;
                  case 'toggle_hidden':
                    explorer.setShowHidden(!explorer.showHidden);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new_file',
                  child: ListTile(leading: Icon(Icons.note_add_outlined), title: Text('New File')),
                ),
                const PopupMenuItem(
                  value: 'new_folder',
                  child: ListTile(leading: Icon(Icons.create_new_folder_outlined), title: Text('New Folder')),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(leading: Icon(Icons.refresh), title: Text('Refresh')),
                ),
                PopupMenuItem(
                  value: 'toggle_hidden',
                  child: ListTile(
                    leading: Icon(explorer.showHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    title: Text(explorer.showHidden ? 'Hide hidden files' : 'Show hidden files'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FileExplorerProvider explorer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search files by name…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
          isDense: true,
        ),
        onChanged: (value) => _onSearchChanged(explorer, value),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, FileExplorerProvider explorer) {
    final results = _searchResults ?? const <FileNode>[];
    if (results.isEmpty) {
      return Center(child: Text('No matches', style: Theme.of(context).textTheme.bodyMedium));
    }
    final rootPath = explorer.rootPath ?? '';
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final node = results[index];
        final relativePath = node.path.startsWith(rootPath) ? node.path.substring(rootPath.length).replaceFirst('/', '') : node.path;
        return ListTile(
          leading: FileIcon(node: node, size: 20),
          title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(relativePath, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () async {
            if (node.isFile) {
              widget.onOpenFile(node);
            } else {
              await explorer.revealPath(node.path);
            }
            if (!mounted) return;
            setState(() {
              _searchMode = false;
              _searchController.clear();
              _searchResults = null;
            });
          },
        );
      },
    );
  }

  Widget _buildClipboardBar(BuildContext context, FileExplorerProvider explorer) {
    final theme = Theme.of(context);
    final node = explorer.clipboardNode!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Icon(explorer.clipboardIsCut ? Icons.content_cut : Icons.copy_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${explorer.clipboardIsCut ? "Cut" : "Copied"}: ${node.name} — open a folder\'s menu to paste',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: explorer.clearClipboard,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
