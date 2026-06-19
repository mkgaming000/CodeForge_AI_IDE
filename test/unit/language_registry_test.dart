import 'package:codeforge/core/services/language_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageRegistry.forFile', () {
    test('maps common extensions to the correct language', () {
      expect(LanguageRegistry.forFile(extension: 'dart').displayName, 'Dart');
      expect(LanguageRegistry.forFile(extension: 'py').displayName, 'Python');
      expect(LanguageRegistry.forFile(extension: 'js').displayName, 'JavaScript');
      expect(LanguageRegistry.forFile(extension: 'ts').displayName, 'TypeScript');
      expect(LanguageRegistry.forFile(extension: 'java').displayName, 'Java');
      expect(LanguageRegistry.forFile(extension: 'kt').displayName, 'Kotlin');
      expect(LanguageRegistry.forFile(extension: 'cpp').displayName, 'C++');
      expect(LanguageRegistry.forFile(extension: 'c').displayName, 'C');
      expect(LanguageRegistry.forFile(extension: 'cs').displayName, 'C#');
      expect(LanguageRegistry.forFile(extension: 'go').displayName, 'Go');
      expect(LanguageRegistry.forFile(extension: 'rs').displayName, 'Rust');
      expect(LanguageRegistry.forFile(extension: 'php').displayName, 'PHP');
      expect(LanguageRegistry.forFile(extension: 'rb').displayName, 'Ruby');
      expect(LanguageRegistry.forFile(extension: 'swift').displayName, 'Swift');
      expect(LanguageRegistry.forFile(extension: 'sql').displayName, 'SQL');
      expect(LanguageRegistry.forFile(extension: 'json').displayName, 'JSON');
      expect(LanguageRegistry.forFile(extension: 'yaml').displayName, 'YAML');
      expect(LanguageRegistry.forFile(extension: 'yml').displayName, 'YAML');
      expect(LanguageRegistry.forFile(extension: 'md').displayName, 'Markdown');
      expect(LanguageRegistry.forFile(extension: 'sh').displayName, 'Shell Script');
    });

    test('is case-insensitive for extensions', () {
      expect(LanguageRegistry.forFile(extension: 'DART').displayName, 'Dart');
      expect(LanguageRegistry.forFile(extension: 'Py').displayName, 'Python');
      expect(LanguageRegistry.forFile(extension: 'JS').displayName, 'JavaScript');
    });

    test('falls back to plain text for unknown extensions', () {
      final result = LanguageRegistry.forFile(extension: 'xyz123');
      expect(result.displayName, 'Plain Text');
      expect(result.mode, isNull);
    });

    test('recognizes Dockerfile and Makefile by filename when there is no extension', () {
      expect(LanguageRegistry.forFile(extension: '', fileName: 'Dockerfile').displayName, 'Dockerfile');
      expect(LanguageRegistry.forFile(extension: '', fileName: 'dockerfile').displayName, 'Dockerfile');
      expect(LanguageRegistry.forFile(extension: '', fileName: 'Makefile').displayName, 'Makefile');
    });

    test('falls back to plain text for an empty extension and unrecognized filename', () {
      final result = LanguageRegistry.forFile(extension: '', fileName: 'README');
      expect(result.displayName, 'Plain Text');
    });

    test('all() returns a non-empty, alphabetically sorted list', () {
      final all = LanguageRegistry.all;
      expect(all, isNotEmpty);
      final names = all.map((l) => l.displayName).toList();
      final sortedNames = [...names]..sort();
      expect(names, sortedNames);
    });

    test('C and C++ share a highlight.js grammar but have distinct display names', () {
      final c = LanguageRegistry.forFile(extension: 'c');
      final cpp = LanguageRegistry.forFile(extension: 'cpp');
      expect(c.displayName, isNot(cpp.displayName));
      expect(c.mode, same(cpp.mode));
    });
  });
}
