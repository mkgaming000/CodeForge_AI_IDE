import 'package:flutter/material.dart';
import 'package:highlight/highlight_core.dart' show Mode;

import 'package:highlight/languages/bash.dart' as lang_bash;
import 'package:highlight/languages/cpp.dart' as lang_cpp;
import 'package:highlight/languages/cs.dart' as lang_csharp;
import 'package:highlight/languages/css.dart' as lang_css;
import 'package:highlight/languages/dart.dart' as lang_dart;
import 'package:highlight/languages/diff.dart' as lang_diff;
import 'package:highlight/languages/dockerfile.dart' as lang_dockerfile;
import 'package:highlight/languages/go.dart' as lang_go;
import 'package:highlight/languages/haskell.dart' as lang_haskell;
import 'package:highlight/languages/ini.dart' as lang_ini;
import 'package:highlight/languages/java.dart' as lang_java;
import 'package:highlight/languages/javascript.dart' as lang_javascript;
import 'package:highlight/languages/json.dart' as lang_json;
import 'package:highlight/languages/kotlin.dart' as lang_kotlin;
import 'package:highlight/languages/lua.dart' as lang_lua;
import 'package:highlight/languages/makefile.dart' as lang_makefile;
import 'package:highlight/languages/markdown.dart' as lang_markdown;
import 'package:highlight/languages/objectivec.dart' as lang_objectivec;
import 'package:highlight/languages/perl.dart' as lang_perl;
import 'package:highlight/languages/php.dart' as lang_php;
import 'package:highlight/languages/powershell.dart' as lang_powershell;
import 'package:highlight/languages/python.dart' as lang_python;
import 'package:highlight/languages/r.dart' as lang_r;
import 'package:highlight/languages/ruby.dart' as lang_ruby;
import 'package:highlight/languages/rust.dart' as lang_rust;
import 'package:highlight/languages/scala.dart' as lang_scala;
import 'package:highlight/languages/scss.dart' as lang_scss;
import 'package:highlight/languages/shell.dart' as lang_shell;
import 'package:highlight/languages/sql.dart' as lang_sql;
import 'package:highlight/languages/swift.dart' as lang_swift;
import 'package:highlight/languages/typescript.dart' as lang_typescript;
import 'package:highlight/languages/xml.dart' as lang_xml;
import 'package:highlight/languages/yaml.dart' as lang_yaml;

/// Describes how CodeForge should treat a particular programming language.
class LanguageDefinition {
  const LanguageDefinition({
    required this.id,
    required this.displayName,
    required this.mode,
    required this.icon,
    required this.color,
    this.lineComment,
    this.blockCommentStart,
    this.blockCommentEnd,
  });

  final String id;
  final String displayName;

  /// The highlight.js grammar. `null` = plain text, no highlighting.
  final Mode? mode;

  final IconData icon;
  final Color color;
  final String? lineComment;
  final String? blockCommentStart;
  final String? blockCommentEnd;
}

/// Central registry that maps file extensions to [LanguageDefinition]s.
class LanguageRegistry {
  LanguageRegistry._();

  static final LanguageDefinition plainText = LanguageDefinition(
    id: 'plaintext',
    displayName: 'Plain Text',
    mode: null,
    icon: Icons.description_outlined,
    color: const Color(0xFF9E9E9E),
  );

  static final Map<String, LanguageDefinition> _definitions = {
    'dart': LanguageDefinition(
      id: 'dart', displayName: 'Dart', mode: lang_dart.dart,
      icon: Icons.flutter_dash, color: const Color(0xFF0175C2),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'python': LanguageDefinition(
      id: 'python', displayName: 'Python', mode: lang_python.python,
      icon: Icons.code, color: const Color(0xFF3776AB), lineComment: '#',
    ),
    'javascript': LanguageDefinition(
      id: 'javascript', displayName: 'JavaScript', mode: lang_javascript.javascript,
      icon: Icons.javascript, color: const Color(0xFFF7DF1E),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'typescript': LanguageDefinition(
      id: 'typescript', displayName: 'TypeScript', mode: lang_typescript.typescript,
      icon: Icons.code, color: const Color(0xFF3178C6),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'java': LanguageDefinition(
      id: 'java', displayName: 'Java', mode: lang_java.java,
      icon: Icons.coffee, color: const Color(0xFFE76F00),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'kotlin': LanguageDefinition(
      id: 'kotlin', displayName: 'Kotlin', mode: lang_kotlin.kotlin,
      icon: Icons.code, color: const Color(0xFF7F52FF),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'cpp': LanguageDefinition(
      id: 'cpp', displayName: 'C++', mode: lang_cpp.cpp,
      icon: Icons.memory, color: const Color(0xFF00599C),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'c': LanguageDefinition(
      id: 'c', displayName: 'C', mode: lang_cpp.cpp,
      icon: Icons.memory, color: const Color(0xFF5C6BC0),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'csharp': LanguageDefinition(
      id: 'csharp', displayName: 'C#', mode: lang_csharp.cs,
      icon: Icons.code, color: const Color(0xFF9B4F96),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'go': LanguageDefinition(
      id: 'go', displayName: 'Go', mode: lang_go.go,
      icon: Icons.directions_run, color: const Color(0xFF00ADD8),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'rust': LanguageDefinition(
      id: 'rust', displayName: 'Rust', mode: lang_rust.rust,
      icon: Icons.settings_suggest, color: const Color(0xFFDEA584),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'php': LanguageDefinition(
      id: 'php', displayName: 'PHP', mode: lang_php.php,
      icon: Icons.php, color: const Color(0xFF777BB4),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'ruby': LanguageDefinition(
      id: 'ruby', displayName: 'Ruby', mode: lang_ruby.ruby,
      icon: Icons.diamond_outlined, color: const Color(0xFFCC342D), lineComment: '#',
    ),
    'swift': LanguageDefinition(
      id: 'swift', displayName: 'Swift', mode: lang_swift.swift,
      icon: Icons.code, color: const Color(0xFFFA7343),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'lua': LanguageDefinition(
      id: 'lua', displayName: 'Lua', mode: lang_lua.lua,
      icon: Icons.code, color: const Color(0xFF000080), lineComment: '--',
    ),
    'scala': LanguageDefinition(
      id: 'scala', displayName: 'Scala', mode: lang_scala.scala,
      icon: Icons.code, color: const Color(0xFFDC322F),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'r': LanguageDefinition(
      id: 'r', displayName: 'R', mode: lang_r.r,
      icon: Icons.bar_chart, color: const Color(0xFF276DC3), lineComment: '#',
    ),
    'perl': LanguageDefinition(
      id: 'perl', displayName: 'Perl', mode: lang_perl.perl,
      icon: Icons.code, color: const Color(0xFF39457E), lineComment: '#',
    ),
    'sql': LanguageDefinition(
      id: 'sql', displayName: 'SQL', mode: lang_sql.sql,
      icon: Icons.storage, color: const Color(0xFFE38C00), lineComment: '--',
    ),
    'html': LanguageDefinition(
      id: 'html', displayName: 'HTML', mode: lang_xml.xml,
      icon: Icons.html, color: const Color(0xFFE34F26),
    ),
    'xml': LanguageDefinition(
      id: 'xml', displayName: 'XML', mode: lang_xml.xml,
      icon: Icons.code, color: const Color(0xFF005FAD),
    ),
    'css': LanguageDefinition(
      id: 'css', displayName: 'CSS', mode: lang_css.css,
      icon: Icons.css, color: const Color(0xFF1572B6),
      blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'scss': LanguageDefinition(
      id: 'scss', displayName: 'SCSS', mode: lang_scss.scss,
      icon: Icons.css, color: const Color(0xFFCC6699),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'json': LanguageDefinition(
      id: 'json', displayName: 'JSON', mode: lang_json.json,
      icon: Icons.data_object, color: const Color(0xFFCBCB41),
    ),
    'yaml': LanguageDefinition(
      id: 'yaml', displayName: 'YAML', mode: lang_yaml.yaml,
      icon: Icons.data_array, color: const Color(0xFFCB171E), lineComment: '#',
    ),
    'markdown': LanguageDefinition(
      id: 'markdown', displayName: 'Markdown', mode: lang_markdown.markdown,
      icon: Icons.article_outlined, color: const Color(0xFF755838),
    ),
    'bash': LanguageDefinition(
      id: 'bash', displayName: 'Shell Script', mode: lang_bash.bash,
      icon: Icons.terminal, color: const Color(0xFF4EAA25), lineComment: '#',
    ),
    'shell': LanguageDefinition(
      id: 'shell', displayName: 'Shell', mode: lang_shell.shell,
      icon: Icons.terminal, color: const Color(0xFF4EAA25), lineComment: '#',
    ),
    'powershell': LanguageDefinition(
      id: 'powershell', displayName: 'PowerShell', mode: lang_powershell.powershell,
      icon: Icons.terminal, color: const Color(0xFF012456), lineComment: '#',
    ),
    'haskell': LanguageDefinition(
      id: 'haskell', displayName: 'Haskell', mode: lang_haskell.haskell,
      icon: Icons.functions, color: const Color(0xFF5D4F85), lineComment: '--',
    ),
    'objectivec': LanguageDefinition(
      id: 'objectivec', displayName: 'Objective-C', mode: lang_objectivec.objectivec,
      icon: Icons.code, color: const Color(0xFF438EFF),
      lineComment: '//', blockCommentStart: '/*', blockCommentEnd: '*/',
    ),
    'ini': LanguageDefinition(
      id: 'ini', displayName: 'INI / Config', mode: lang_ini.ini,
      icon: Icons.settings_outlined, color: const Color(0xFF8C8C8C), lineComment: ';',
    ),
    'dockerfile': LanguageDefinition(
      id: 'dockerfile', displayName: 'Dockerfile', mode: lang_dockerfile.dockerfile,
      icon: Icons.developer_board, color: const Color(0xFF2496ED), lineComment: '#',
    ),
    'makefile': LanguageDefinition(
      id: 'makefile', displayName: 'Makefile', mode: lang_makefile.makefile,
      icon: Icons.build_outlined, color: const Color(0xFF8C8C8C), lineComment: '#',
    ),
    'diff': LanguageDefinition(
      id: 'diff', displayName: 'Diff / Patch', mode: lang_diff.diff,
      icon: Icons.difference_outlined, color: const Color(0xFF8C8C8C),
    ),
  };

  static final Map<String, String> _extensionMap = {
    'dart': 'dart',
    'py': 'python', 'pyw': 'python',
    'js': 'javascript', 'mjs': 'javascript', 'cjs': 'javascript', 'jsx': 'javascript',
    'ts': 'typescript', 'tsx': 'typescript',
    'java': 'java',
    'kt': 'kotlin', 'kts': 'kotlin',
    'cpp': 'cpp', 'cc': 'cpp', 'cxx': 'cpp', 'hpp': 'cpp', 'hh': 'cpp',
    'c': 'c', 'h': 'c',
    'cs': 'csharp',
    'go': 'go',
    'rs': 'rust',
    'php': 'php',
    'rb': 'ruby',
    'swift': 'swift',
    'lua': 'lua',
    'scala': 'scala', 'sc': 'scala',
    'r': 'r',
    'pl': 'perl', 'pm': 'perl',
    'sql': 'sql',
    'html': 'html', 'htm': 'html',
    'xml': 'xml', 'gradle': 'xml',
    'css': 'css',
    'scss': 'scss', 'sass': 'scss',
    'json': 'json', 'webmanifest': 'json',
    'yaml': 'yaml', 'yml': 'yaml',
    'md': 'markdown', 'markdown': 'markdown',
    'sh': 'bash', 'bash': 'bash',
    'zsh': 'shell',
    'ps1': 'powershell',
    'hs': 'haskell',
    'm': 'objectivec', 'mm': 'objectivec',
    'ini': 'ini', 'cfg': 'ini', 'toml': 'ini', 'env': 'ini',
    'dockerfile': 'dockerfile',
    'makefile': 'makefile', 'mk': 'makefile',
    'diff': 'diff', 'patch': 'diff',
  };

  /// Returns the [LanguageDefinition] for a file based on extension + optional filename.
  static LanguageDefinition forFile({required String extension, String? fileName}) {
    final ext = extension.toLowerCase();
    final id = _extensionMap[ext];
    if (id != null) return _definitions[id] ?? plainText;

    if (fileName != null) {
      final lower = fileName.toLowerCase();
      if (lower == 'dockerfile') return _definitions['dockerfile']!;
      if (lower == 'makefile') return _definitions['makefile']!;
    }
    return plainText;
  }

  /// All registered language definitions, sorted by display name.
  static List<LanguageDefinition> get all {
    final list = _definitions.values.toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }
}
