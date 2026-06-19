import 'dart:io';

import 'package:codeforge/core/models/file_node.dart';
import 'package:codeforge/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('EditorProvider find & replace', () {
    late Directory tempDir;
    late EditorProvider editor;
    late String filePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('codeforge_test_');
      filePath = p.join(tempDir.path, 'sample.txt');
      await File(filePath).writeAsString('foo bar foo baz FOO\nsecond line foo');

      editor = EditorProvider(tabSize: 4, autoIndent: true, autoCloseBrackets: true);
      await editor.openFile(FileNode(path: filePath, name: 'sample.txt', type: FileNodeType.file));
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('opening a file creates exactly one active tab with the file contents', () {
      expect(editor.tabs, hasLength(1));
      expect(editor.activeTab?.controller.fullText, 'foo bar foo baz FOO\nsecond line foo');
    });

    test('opening the same file again does not duplicate the tab', () async {
      await editor.openFile(FileNode(path: filePath, name: 'sample.txt', type: FileNodeType.file));
      expect(editor.tabs, hasLength(1));
    });

    test('findAll is case-insensitive by default', () {
      final matches = editor.findAll('foo');
      // "foo", "foo", "FOO", "foo" -> 4 case-insensitive matches.
      expect(matches, hasLength(4));
    });

    test('findAll respects caseSensitive', () {
      final matches = editor.findAll('foo', caseSensitive: true);
      // Only the three lowercase "foo" occurrences.
      expect(matches, hasLength(3));
    });

    test('findAll supports regular expressions', () {
      final matches = editor.findAll(r'\bfoo\b', useRegex: true, caseSensitive: true);
      expect(matches, hasLength(3));
    });

    test('findAll returns an empty list for an invalid regex', () {
      final matches = editor.findAll('(unclosed', useRegex: true);
      expect(matches, isEmpty);
    });

    test('replaceRange replaces text at a specific offset', () {
      final text = editor.activeTab!.controller.fullText;
      final offset = text.indexOf('bar');
      editor.replaceRange(offset, 'bar'.length, 'BAZ');
      expect(editor.activeTab!.controller.fullText, startsWith('foo BAZ foo'));
    });

    test('replaceAll replaces every case-insensitive match and reports the count', () {
      final count = editor.replaceAll('foo', 'qux');
      expect(count, 4);
      final text = editor.activeTab!.controller.fullText;
      expect(text.toLowerCase().contains('foo'), isFalse);
      expect(RegExp('qux').allMatches(text).length, 4);
    });

    test('replaceAll with caseSensitive only replaces matching case', () {
      final count = editor.replaceAll('foo', 'qux', caseSensitive: true);
      expect(count, 3);
      final text = editor.activeTab!.controller.fullText;
      expect(text.contains('FOO'), isTrue);
      expect(text.contains('foo'), isFalse);
    });

    test('insertTextAtCursor inserts at the end when there is no selection', () {
      final tab = editor.activeTab!;
      tab.controller.selection = const TextSelection.collapsed(offset: -1); // invalid -> falls back to end
      final inserted = editor.insertTextAtCursor('XYZ');
      expect(inserted, isTrue);
      expect(tab.controller.fullText.endsWith('XYZ'), isTrue);
    });

    test('insertTextAtCursor returns false when there is no open tab', () {
      final empty = EditorProvider(tabSize: 4, autoIndent: true, autoCloseBrackets: true);
      expect(empty.insertTextAtCursor('x'), isFalse);
    });

    test('undo/redo restore previous content after a programmatic replace', () {
      editor.replaceActiveContent('completely new content');
      expect(editor.activeTab!.controller.fullText, 'completely new content');
      expect(editor.canUndo, isTrue);

      editor.undo();
      expect(editor.activeTab!.controller.fullText, 'foo bar foo baz FOO\nsecond line foo');
    });

    test('isDirty becomes true after a content change and false after saving', () async {
      expect(editor.activeTab!.isDirty, isFalse);
      editor.replaceActiveContent('changed');
      expect(editor.activeTab!.isDirty, isTrue);

      await editor.saveActiveTab();
      expect(editor.activeTab!.isDirty, isFalse);
      expect(await File(filePath).readAsString(), 'changed');
    });
  });
}
