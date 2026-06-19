import 'package:codeforge/core/models/file_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileNode', () {
    test('isFile / isDirectory reflect the node type', () {
      final file = FileNode(path: '/a/b.dart', name: 'b.dart', type: FileNodeType.file);
      final dir = FileNode(path: '/a', name: 'a', type: FileNodeType.directory);

      expect(file.isFile, isTrue);
      expect(file.isDirectory, isFalse);
      expect(dir.isDirectory, isTrue);
      expect(dir.isFile, isFalse);
    });

    test('extension is lower-cased and excludes the leading dot', () {
      final node = FileNode(path: '/a/Main.DART', name: 'Main.DART', type: FileNodeType.file);
      expect(node.extension, 'dart');
    });

    test('extension is empty for files with no dot', () {
      final node = FileNode(path: '/a/README', name: 'README', type: FileNodeType.file);
      expect(node.extension, '');
    });

    test('extension is empty for a trailing-dot filename', () {
      final node = FileNode(path: '/a/file.', name: 'file.', type: FileNodeType.file);
      expect(node.extension, '');
    });

    test('extension is always empty for directories regardless of name', () {
      final node = FileNode(path: '/a/my.folder', name: 'my.folder', type: FileNodeType.directory);
      expect(node.extension, '');
    });

    test('two nodes with the same path are equal regardless of other fields', () {
      final a = FileNode(path: '/a/b.dart', name: 'b.dart', type: FileNodeType.file, isExpanded: false);
      final b = FileNode(path: '/a/b.dart', name: 'different-name', type: FileNodeType.file, isExpanded: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('nodes with different paths are not equal', () {
      final a = FileNode(path: '/a/b.dart', name: 'b.dart', type: FileNodeType.file);
      final b = FileNode(path: '/a/c.dart', name: 'c.dart', type: FileNodeType.file);
      expect(a, isNot(equals(b)));
    });

    test('copyCollapsed resets children and isExpanded but keeps identity fields', () {
      final node = FileNode(
        path: '/a',
        name: 'a',
        type: FileNodeType.directory,
        isExpanded: true,
        children: [FileNode(path: '/a/b', name: 'b', type: FileNodeType.file)],
      );
      final collapsed = node.copyCollapsed();
      expect(collapsed.path, node.path);
      expect(collapsed.isExpanded, isFalse);
      expect(collapsed.children, isNull);
    });
  });
}
