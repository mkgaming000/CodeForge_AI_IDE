import 'dart:io';

/// The type of a node in the file explorer tree.
enum FileNodeType { file, directory }

/// Represents a single file or directory within the project tree.
///
/// This is a lightweight, immutable-ish model: [children] is mutable so the
/// tree can be lazily populated as folders are expanded, but the identity of
/// a node (its [path]) never changes.
class FileNode {
  FileNode({
    required this.path,
    required this.name,
    required this.type,
    this.children,
    this.isExpanded = false,
    this.sizeBytes,
    this.modified,
  });

  /// Absolute path on disk.
  final String path;

  /// Display name (last path segment).
  final String name;

  /// Whether this node is a file or a directory.
  final FileNodeType type;

  /// Children of this node, if it is a directory and has been scanned.
  /// `null` means "not yet loaded".
  List<FileNode>? children;

  /// Whether this directory node is currently expanded in the tree view.
  bool isExpanded;

  /// File size in bytes (files only).
  final int? sizeBytes;

  /// Last modified timestamp.
  final DateTime? modified;

  bool get isDirectory => type == FileNodeType.directory;
  bool get isFile => type == FileNodeType.file;

  /// File extension without the leading dot, lower-cased. Empty for files
  /// without an extension or for directories.
  String get extension {
    if (isDirectory) return '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Builds a [FileNode] from a [FileSystemEntity] on disk.
  static Future<FileNode> fromEntity(FileSystemEntity entity) async {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (entity is Directory) {
      return FileNode(
        path: entity.path,
        name: name,
        type: FileNodeType.directory,
      );
    } else {
      int? size;
      DateTime? modified;
      try {
        final stat = await entity.stat();
        size = stat.size;
        modified = stat.modified;
      } catch (_) {
        // Ignore stat errors (e.g. broken symlinks); size/modified stay null.
      }
      return FileNode(
        path: entity.path,
        name: name,
        type: FileNodeType.file,
        sizeBytes: size,
        modified: modified,
      );
    }
  }

  /// Returns a copy of this node with [children] and [isExpanded] reset,
  /// useful when invalidating a cached subtree.
  FileNode copyCollapsed() {
    return FileNode(
      path: path,
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      modified: modified,
      isExpanded: false,
      children: null,
    );
  }

  @override
  bool operator ==(Object other) => other is FileNode && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
