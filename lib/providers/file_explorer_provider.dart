import 'package:flutter/material.dart';

import '../core/models/file_node.dart';
import '../core/services/file_system_service.dart';

/// Manages the file-tree state for the currently open project: lazy
/// loading/expanding directories, and delegating create/rename/delete/move
/// operations to [FileSystemService] before refreshing the affected nodes.
class FileExplorerProvider extends ChangeNotifier {
  final FileSystemService _fs = FileSystemService.instance;

  String? _rootPath;
  FileNode? _root;
  bool _showHidden = false;
  bool _isLoading = false;
  String? _error;
  FileNode? _clipboardNode;
  bool _clipboardIsCut = false;

  String? get rootPath => _rootPath;
  FileNode? get root => _root;
  bool get showHidden => _showHidden;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProject => _rootPath != null;
  FileNode? get clipboardNode => _clipboardNode;
  bool get clipboardIsCut => _clipboardIsCut;

  Future<void> openProject(String path) async {
    _rootPath = path;
    _root = FileNode(
      path: path,
      name: _displayName(path),
      type: FileNodeType.directory,
      isExpanded: true,
    );
    await _loadChildren(_root!);
    notifyListeners();
  }

  void closeProject() {
    _rootPath = null;
    _root = null;
    notifyListeners();
  }

  String _displayName(String path) {
    final parts = path.split('/').where((s) => s.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  Future<void> toggleExpanded(FileNode node) async {
    if (!node.isDirectory) return;
    node.isExpanded = !node.isExpanded;
    if (node.isExpanded && node.children == null) {
      await _loadChildren(node);
    }
    notifyListeners();
  }

  Future<void> _loadChildren(FileNode node) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      node.children = await _fs.listDirectory(node.path, showHidden: _showHidden);
    } catch (e) {
      _error = e.toString();
      node.children = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes [node] (or the project root if `null`), reloading its
  /// children from disk.
  Future<void> refresh([FileNode? node]) async {
    final target = node ?? _root;
    if (target == null) return;
    target.children = null;
    target.isExpanded = true;
    await _loadChildren(target);
  }

  Future<void> setShowHidden(bool value) async {
    if (_showHidden == value) return;
    _showHidden = value;
    if (_root != null) {
      await refresh(_root);
    } else {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // CRUD operations
  // ------------------------------------------------------------------

  Future<void> createFile(FileNode parent, String fileName) async {
    await _fs.createFile(parent.path, fileName);
    await refresh(parent);
  }

  Future<void> createFolder(FileNode parent, String name) async {
    await _fs.createDirectory(parent.path, name);
    await refresh(parent);
  }

  Future<void> deleteNode(FileNode node) async {
    await _fs.deleteEntity(node);
    await refresh(findParent(node));
  }

  Future<String> renameNode(FileNode node, String newName) async {
    final parent = findParent(node);
    final newPath = await _fs.rename(node, newName);
    await refresh(parent);
    return newPath;
  }

  Future<void> duplicateNode(FileNode node) async {
    await _fs.duplicate(node);
    await refresh(findParent(node));
  }

  Future<void> copyNodeTo(FileNode node, FileNode destination) async {
    await _fs.copyEntity(node, destination.path);
    await refresh(destination);
  }

  Future<void> moveNodeTo(FileNode node, FileNode destination) async {
    final sourceParent = findParent(node);
    await _fs.moveEntity(node, destination.path);
    await refresh(destination);
    if (sourceParent != null && sourceParent.path != destination.path) {
      await refresh(sourceParent);
    }
  }

  // ------------------------------------------------------------------
  // Clipboard (cut / copy / paste)
  // ------------------------------------------------------------------

  void copyToClipboard(FileNode node) {
    _clipboardNode = node;
    _clipboardIsCut = false;
    notifyListeners();
  }

  void cutToClipboard(FileNode node) {
    _clipboardNode = node;
    _clipboardIsCut = true;
    notifyListeners();
  }

  void clearClipboard() {
    _clipboardNode = null;
    _clipboardIsCut = false;
    notifyListeners();
  }

  /// Pastes the clipboard contents into [destination] (a directory). If the
  /// clipboard item was cut, it is moved; if copied, it is duplicated.
  Future<void> pasteInto(FileNode destination) async {
    final node = _clipboardNode;
    if (node == null || !destination.isDirectory) return;

    if (_clipboardIsCut) {
      await moveNodeTo(node, destination);
      _clipboardNode = null;
      _clipboardIsCut = false;
    } else {
      await copyNodeTo(node, destination);
    }
    notifyListeners();
  }

  /// Finds the parent of [node] within the loaded tree. Returns the project
  /// root if [node] is `null`, a top-level item, or not found in the loaded
  /// subtree (so a refresh on the root is a safe fallback).
  FileNode? findParent(FileNode? node) {
    if (_root == null) return null;
    if (node == null || node.path == _root!.path) return _root;
    final found = _findParentRecursive(_root!, node);
    return found ?? _root;
  }

  FileNode? _findParentRecursive(FileNode current, FileNode target) {
    final children = current.children;
    if (children == null) return null;
    for (final child in children) {
      if (child.path == target.path) return current;
      final found = _findParentRecursive(child, target);
      if (found != null) return found;
    }
    return null;
  }

  Future<List<FileNode>> searchByName(String query) {
    if (_rootPath == null) return Future.value(const []);
    return _fs.searchByName(_rootPath!, query, showHidden: _showHidden);
  }

  Future<List<SearchMatch>> searchInFiles(String query, {bool caseSensitive = false, bool useRegex = false}) {
    if (_rootPath == null) return Future.value(const []);
    return _fs.searchInFiles(_rootPath!, query, caseSensitive: caseSensitive, useRegex: useRegex, showHidden: _showHidden);
  }

  /// Expands every ancestor directory between the project root and [path],
  /// loading children as needed, so [path] becomes visible in the tree.
  Future<void> revealPath(String path) async {
    final root = _root;
    final rootPath = _rootPath;
    if (root == null || rootPath == null || !path.startsWith(rootPath)) return;

    final relative = path.substring(rootPath.length);
    final segments = relative.split('/').where((s) => s.isNotEmpty).toList();

    var current = root;
    current.isExpanded = true;
    if (current.children == null) await _loadChildren(current);

    for (final segment in segments) {
      final children = current.children;
      if (children == null) break;
      FileNode? next;
      for (final child in children) {
        if (child.name == segment) {
          next = child;
          break;
        }
      }
      if (next == null) break;
      current = next;
      if (current.isDirectory) {
        current.isExpanded = true;
        if (current.children == null) await _loadChildren(current);
      }
    }
    notifyListeners();
  }

  /// Builds a simple textual tree of the project, used as AI context and for
  /// README generation. Capped at [maxEntries] entries and [maxDepth]
  /// directory levels to keep prompts small.
  Future<String> buildFileTreeString({int maxEntries = 200, int maxDepth = 4}) async {
    if (_rootPath == null) return '';
    final buffer = StringBuffer('${_displayName(_rootPath!)}/\n');
    var count = 0;

    Future<void> walk(String path, int depth, String prefix) async {
      if (count >= maxEntries || depth > maxDepth) return;
      final entries = await _fs.listDirectory(path, showHidden: false);
      for (final entry in entries) {
        if (count >= maxEntries) return;
        buffer.writeln('$prefix${entry.isDirectory ? '${entry.name}/' : entry.name}');
        count++;
        if (entry.isDirectory) {
          await walk(entry.path, depth + 1, '$prefix  ');
        }
      }
    }

    await walk(_rootPath!, 1, '  ');
    return buffer.toString();
  }
}
