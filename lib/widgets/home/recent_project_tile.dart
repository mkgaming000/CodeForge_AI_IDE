import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/recent_project.dart';

/// A swipe-to-remove list tile representing a recently opened project,
/// with a pin toggle and last-opened timestamp.
class RecentProjectTile extends StatelessWidget {
  const RecentProjectTile({
    super.key,
    required this.project,
    required this.onTap,
    required this.onTogglePin,
    required this.onRemove,
  });

  final RecentProject project;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onRemove;

  static final DateFormat _format = DateFormat.yMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(project.path),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
          ),
          title: Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${project.path}\n${_format.format(project.lastOpened)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: project.isPinned ? 'Unpin' : 'Pin to top',
            icon: Icon(
              project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: project.isPinned ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onTogglePin,
          ),
        ),
      ),
    );
  }
}
