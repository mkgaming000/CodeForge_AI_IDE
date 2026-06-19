import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/file_node.dart';

/// A single text-search hit produced by [FileSystemService.searchInFiles].
class SearchMatch {
  SearchMatch({
    required this.filePath,
    required this.lineNumber,
    required this.lineText,
  });

  final String filePath;
  final int lineNumber;
  final String lineText;
}

/// Provides every file-system operation the explorer and editor need:
/// listing, reading, writing, creating, renaming, deleting, copying, moving,
/// and searching (by name and by content).
///
/// All paths are plain absolute file-system paths. Callers are responsible
/// for ensuring storage permission has been granted (see
/// [PermissionService]) before invoking these methods on Android.
class FileSystemService {
  FileSystemService._();
  static final FileSystemService instance = FileSystemService._();

  /// Directory names that are skipped during recursive search by default —
  /// these are typically large, generated, or version-control internals.
  static const Set<String> defaultSkipDirs = {
    '.git',
    '.svn',
    '.hg',
    'node_modules',
    'build',
    '.dart_tool',
    '.gradle',
    '.idea',
    'dist',
    '.next',
    'target',
  };

  /// Lists the immediate children of [directoryPath], directories first,
  /// then files, both alphabetically (case-insensitive).
  Future<List<FileNode>> listDirectory(
    String directoryPath, {
    bool showHidden = false,
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    List<FileSystemEntity> entities;
    try {
      entities = await dir.list(followLinks: false).toList();
    } catch (e) {
      throw FileSystemException('Unable to read folder: $e', directoryPath);
    }

    final nodes = <FileNode>[];
    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (!showHidden && name.startsWith('.')) continue;
      nodes.add(await FileNode.fromEntity(entity));
    }

    nodes.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  /// Reads the full text contents of [path].
  Future<String> readFile(String path) {
    return File(path).readAsString();
  }

  /// Writes [content] to [path], creating the file (and any missing parent
  /// directories) if necessary.
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  /// Creates a new empty file named [fileName] inside [directoryPath].
  /// Throws [FileSystemException] if a file or folder with that name
  /// already exists.
  Future<File> createFile(String directoryPath, String fileName) async {
    final path = p.join(directoryPath, fileName);
    if (await File(path).exists() || await Directory(path).exists()) {
      throw FileSystemException('"$fileName" already exists', path);
    }
    final file = File(path);
    await file.create(recursive: true);
    return file;
  }

  /// Creates a new empty folder named [name] inside [parentPath].
  Future<Directory> createDirectory(String parentPath, String name) async {
    final path = p.join(parentPath, name);
    if (await File(path).exists() || await Directory(path).exists()) {
      throw FileSystemException('"$name" already exists', path);
    }
    final dir = Directory(path);
    await dir.create(recursive: true);
    return dir;
  }

  /// Deletes [node] from disk (recursively, for directories).
  Future<void> deleteEntity(FileNode node) async {
    if (node.isDirectory) {
      await Directory(node.path).delete(recursive: true);
    } else {
      await File(node.path).delete();
    }
  }

  /// Renames [node] to [newName] within its current parent directory.
  /// Returns the new absolute path.
  Future<String> rename(FileNode node, String newName) async {
    final parent = p.dirname(node.path);
    final newPath = p.join(parent, newName);
    if (newPath == node.path) return node.path;
    if (await File(newPath).exists() || await Directory(newPath).exists()) {
      throw FileSystemException('"$newName" already exists', newPath);
    }
    if (node.isDirectory) {
      await Directory(node.path).rename(newPath);
    } else {
      await File(node.path).rename(newPath);
    }
    return newPath;
  }

  /// Copies [node] into [destinationDir]. If a file/folder with the same
  /// name already exists there, a numeric suffix is appended (e.g.
  /// "main (1).dart"). Returns the new absolute path.
  Future<String> copyEntity(FileNode node, String destinationDir) async {
    final desired = p.join(destinationDir, node.name);
    final target = await _uniquePath(desired);
    if (node.isDirectory) {
      await _copyDirectory(Directory(node.path), Directory(target));
    } else {
      await File(node.path).copy(target);
    }
    return target;
  }

  /// Moves [node] into [destinationDir]. If a file/folder with the same name
  /// already exists there, a numeric suffix is appended. Returns the new
  /// absolute path.
  Future<String> moveEntity(FileNode node, String destinationDir) async {
    final desired = p.join(destinationDir, node.name);
    final target = await _uniquePath(desired);
    if (node.isDirectory) {
      await Directory(node.path).rename(target);
    } else {
      await File(node.path).rename(target);
    }
    return target;
  }

  /// Duplicates [node] alongside itself with a "copy" suffix, returning the
  /// new path.
  Future<String> duplicate(FileNode node) async {
    final parent = p.dirname(node.path);
    final ext = node.isFile ? p.extension(node.path) : '';
    final base = node.isFile ? p.basenameWithoutExtension(node.path) : node.name;
    final desired = p.join(parent, '$base copy$ext');
    final target = await _uniquePath(desired);
    if (node.isDirectory) {
      await _copyDirectory(Directory(node.path), Directory(target));
    } else {
      await File(node.path).copy(target);
    }
    return target;
  }

  /// Recursively searches [rootPath] for files/folders whose name contains
  /// [query] (case-insensitive).
  Future<List<FileNode>> searchByName(
    String rootPath,
    String query, {
    int maxResults = 100,
    bool showHidden = false,
  }) async {
    final results = <FileNode>[];
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.isEmpty) return results;

    await _walk(
      Directory(rootPath),
      showHidden: showHidden,
      onEntity: (entity) async {
        final name = p.basename(entity.path);
        if (name.toLowerCase().contains(lowerQuery)) {
          results.add(await FileNode.fromEntity(entity));
        }
        return results.length < maxResults;
      },
    );
    return results;
  }

  /// Recursively searches text files under [rootPath] for [query].
  Future<List<SearchMatch>> searchInFiles(
    String rootPath,
    String query, {
    bool caseSensitive = false,
    bool useRegex = false,
    int maxResults = 200,
    bool showHidden = false,
  }) async {
    final results = <SearchMatch>[];
    if (query.isEmpty) return results;

    RegExp? regex;
    if (useRegex) {
      try {
        regex = RegExp(query, caseSensitive: caseSensitive);
      } catch (e) {
        throw FormatException('Invalid regular expression: $e');
      }
    }
    final lowerQuery = caseSensitive ? query : query.toLowerCase();

    await _walk(
      Directory(rootPath),
      showHidden: showHidden,
      onEntity: (entity) async {
        if (entity is! File) return true;

        String content;
        try {
          content = await entity.readAsString();
        } catch (_) {
          return true; // binary or unreadable — skip silently
        }

        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final bool matched;
          if (regex != null) {
            matched = regex.hasMatch(line);
          } else if (caseSensitive) {
            matched = line.contains(lowerQuery);
          } else {
            matched = line.toLowerCase().contains(lowerQuery);
          }
          if (matched) {
            results.add(SearchMatch(filePath: entity.path, lineNumber: i + 1, lineText: line.trim()));
            if (results.length >= maxResults) return false;
          }
        }
        return true;
      },
    );
    return results;
  }

  /// Returns the total size, in bytes, of a directory tree (best-effort —
  /// unreadable entries are skipped).
  Future<int> directorySize(String path) async {
    var total = 0;
    await _walk(
      Directory(path),
      showHidden: true,
      onEntity: (entity) async {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
        return true;
      },
    );
    return total;
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  Future<String> _uniquePath(String desiredPath) async {
    if (!await File(desiredPath).exists() && !await Directory(desiredPath).exists()) {
      return desiredPath;
    }
    final dir = p.dirname(desiredPath);
    final ext = p.extension(desiredPath);
    final base = p.basenameWithoutExtension(desiredPath);
    var counter = 1;
    String candidate;
    do {
      candidate = p.join(dir, '$base (${counter++})$ext');
    } while (await File(candidate).exists() || await Directory(candidate).exists());
    return candidate;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Link) {
        // Skip symlinks when copying to avoid cycles.
      }
    }
  }

  /// Walks [dir] depth-first. [onEntity] is invoked for every visible entity
  /// (files and directories alike, before recursing into directories).
  /// Returning `false` stops the entire walk immediately.
  Future<void> _walk(
    Directory dir, {
    required bool showHidden,
    required Future<bool> Function(FileSystemEntity entity) onEntity,
    Set<String> skipDirNames = defaultSkipDirs,
  }) async {
    List<FileSystemEntity> entities;
    try {
      entities = await dir.list(followLinks: false).toList();
    } catch (_) {
      return;
    }
    entities.sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (!showHidden && name.startsWith('.')) continue;
      if (entity is Directory && skipDirNames.contains(name)) continue;

      final keepGoing = await onEntity(entity);
      if (!keepGoing) return;

      if (entity is Directory) {
        await _walk(entity, showHidden: showHidden, onEntity: onEntity, skipDirNames: skipDirNames);
      }
    }
  }
}
