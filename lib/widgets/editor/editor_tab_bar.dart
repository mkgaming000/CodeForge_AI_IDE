import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/editor_tab.dart';
import '../../providers/editor_provider.dart';
import '../common/app_dialogs.dart';

/// Horizontal strip of open file tabs, with a colored language icon, a
/// dirty-state dot or close button, and active-tab highlighting.
class EditorTabBar extends StatelessWidget {
  const EditorTabBar({super.key});

  Future<void> _closeTab(BuildContext context, EditorProvider editor, int index) async {
    final tab = editor.tabs[index];
    if (!tab.isDirty) {
      editor.closeTab(index);
      return;
    }

    final action = await AppDialogs.unsavedChanges(context, tab.fileName);
    switch (action) {
      case UnsavedChangesAction.save:
        await editor.saveTab(index);
        editor.closeTab(index, force: true);
        break;
      case UnsavedChangesAction.discard:
        editor.closeTab(index, force: true);
        break;
      case UnsavedChangesAction.cancel:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final theme = Theme.of(context);

    if (editor.tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: editor.tabs.length,
        itemBuilder: (context, index) {
          final tab = editor.tabs[index];
          final isActive = index == editor.activeIndex;
          return _TabChip(
            tab: tab,
            isActive: isActive,
            onTap: () => editor.setActiveIndex(index),
            onClose: () => _closeTab(context, editor, index),
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final EditorTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: isActive ? theme.colorScheme.primary : Colors.transparent, width: 2),
              right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.language.icon, size: 15, color: tab.language.color),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  tab.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: tab.isDirty
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(Icons.close, size: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
