import 'package:flutter/material.dart';

import '../../core/models/file_node.dart';
import '../../providers/file_explorer_provider.dart';
import '../common/file_icon.dart';

/// Renders a single row of the file explorer tree for [node], and — if it's
/// an expanded directory — recursively renders its children beneath it.
///
/// [onTapFile] is called when a file row is tapped (to open it in the
/// editor). [onShowMenu] is called on long-press or when the trailing "more"
/// button is tapped, to show the context menu for [node].
class FileTreeItem extends StatelessWidget {
  const FileTreeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.explorer,
    required this.onTapFile,
    required this.onShowMenu,
    this.activeFilePath,
  });

  final FileNode node;
  final int depth;
  final FileExplorerProvider explorer;
  final void Function(FileNode node) onTapFile;
  final void Function(BuildContext context, FileNode node) onShowMenu;
  final String? activeFilePath;

  static const double _indentWidth = 16.0;
  static const double _basePadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = node.isFile && node.path == activeFilePath;
    final isCutGhost = explorer.clipboardIsCut && explorer.clipboardNode?.path == node.path;

    final row = Material(
      color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (node.isDirectory) {
            explorer.toggleExpanded(node);
          } else {
            onTapFile(node);
          }
        },
        onLongPress: () => onShowMenu(context, node),
        child: Opacity(
          opacity: isCutGhost ? 0.5 : 1.0,
          child: Padding(
            padding: EdgeInsets.only(left: _basePadding + depth * _indentWidth, right: 4),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  if (node.isDirectory)
                    Icon(
                      node.isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 4),
                  FileIcon(node: node, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onShowMenu(context, node),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.more_vert, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!node.isDirectory || !node.isExpanded) {
      return row;
    }

    final children = node.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        if (children == null)
          Padding(
            padding: EdgeInsets.only(left: _basePadding + (depth + 1) * _indentWidth, top: 6, bottom: 6),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            ),
          )
        else if (children.isEmpty)
          Padding(
            padding: EdgeInsets.only(left: _basePadding + (depth + 1) * _indentWidth, top: 4, bottom: 8),
            child: Text(
              'Empty folder',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          for (final child in children)
            FileTreeItem(
              key: ValueKey(child.path),
              node: child,
              depth: depth + 1,
              explorer: explorer,
              onTapFile: onTapFile,
              onShowMenu: onShowMenu,
              activeFilePath: activeFilePath,
            ),
      ],
    );
  }
}
