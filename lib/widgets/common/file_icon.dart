import 'package:flutter/material.dart';

import '../../core/models/file_node.dart';
import '../../core/services/language_registry.dart';

/// Renders an icon for [node]: a colored folder icon (open/closed) for
/// directories, or a language-specific icon (from [LanguageRegistry]) for
/// files.
class FileIcon extends StatelessWidget {
  const FileIcon({super.key, required this.node, this.size = 20});

  final FileNode node;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (node.isDirectory) {
      return Icon(
        node.isExpanded ? Icons.folder_open : Icons.folder,
        size: size,
        color: const Color(0xFFE8B339),
      );
    }

    final language = LanguageRegistry.forFile(extension: node.extension, fileName: node.name);
    return Icon(language.icon, size: size, color: language.color);
  }
}
