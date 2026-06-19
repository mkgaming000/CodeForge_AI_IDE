# CodeForge

> A professional, production-ready **mobile code editor** for Android — built with Flutter and powered by the Anthropic Claude API.

---

## Features

| Category | What's included |
|---|---|
| **Editor** | Syntax highlighting (30+ languages), code folding, line numbers, auto-indent, smart bracket/quote closing, undo/redo history |
| **Tabs** | Unlimited open files, dirty-state indicators, per-tab undo history, keep-alive between switches |
| **Find & Replace** | In-file search, regex mode, case-sensitive toggle, previous/next navigation, Replace, Replace All |
| **File Explorer** | Full tree view, create/rename/delete/duplicate/cut/copy/paste/move files and folders, hidden-file toggle, file-name search |
| **AI Assistant** | Claude-powered chat, code generation, explain, fix bugs, optimize, refactor, comment, unit tests, documentation, convert language, explain error, README generation |
| **Themes** | Dark, Light, and AMOLED modes — all Material 3 |
| **Editor fonts** | JetBrains Mono, Fira Code, Source Code Pro, Roboto Mono, IBM Plex Mono |
| **Settings** | Font size, tab size, word wrap, line numbers, auto-indent, auto-close brackets, auto-save, API key, AI model |

---

## Getting started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.19.0  
- Android SDK (API 23+), connected device or emulator  
- A Claude API key from [console.anthropic.com](https://console.anthropic.com)

### Install dependencies

```bash
cd codeforge
flutter pub get
```

### Run on Android

```bash
flutter run
```

For a release build:

```bash
flutter build apk --release
# or for an App Bundle:
flutter build appbundle --release
```

---

## Project structure

```
lib/
├── main.dart                         App entry point, provider tree
├── app.dart                          Root MaterialApp
├── core/
│   ├── constants/app_constants.dart  Global constants and SharedPrefs keys
│   ├── models/                       Pure data models (FileNode, EditorTab, ChatMessage, …)
│   ├── services/                     AI, file-system, permissions, storage, language registry
│   ├── theme/                        AppColors + AppThemes (Dark / Light / AMOLED)
│   └── utils/                        SmartCodeController, UndoRedoStack
├── providers/                        State managers (ChangeNotifier)
│   ├── theme_provider.dart
│   ├── settings_provider.dart
│   ├── project_provider.dart
│   ├── file_explorer_provider.dart
│   ├── editor_provider.dart
│   └── ai_chat_provider.dart
├── screens/
│   ├── home_screen.dart              Landing screen with recent projects
│   ├── editor_screen.dart            Main IDE layout
│   └── settings_screen.dart         Preferences
└── widgets/
    ├── common/                       FileIcon, AppDialogs
    ├── home/                         QuickActionCard, RecentProjectTile
    ├── editor/                       CodeEditorView, EditorTabBar, FindReplaceBar
    ├── explorer/                     FileExplorerPanel, FileTreeItem
    └── ai/                           AiChatPanel
```

---

## AI setup

1. Open **Settings → AI Assistant**  
2. Paste your Claude API key (`sk-ant-…`)  
3. Tap **Save** — the key is stored in the Android Keystore, never on a server  

All AI requests are sent **directly from your device to the Anthropic API** — no proxy or third-party server is involved.

---

## Supported languages

C, C++, C#, Dart, Go, Haskell, Java, JavaScript, JSON, Kotlin, Lua, Markdown, Objective-C, Perl, PHP, Python, R, Ruby, Rust, Scala, SCSS/CSS, Shell/Bash, SQL, Swift, TypeScript, YAML, XML/HTML, Dockerfile, Makefile, PowerShell, INI/TOML, Diff/Patch

---

## Testing

CodeForge ships with a real unit test suite (no placeholder tests) covering the core logic layer:

```bash
flutter test
```

| Test file | Coverage |
|---|---|
| `test/unit/language_registry_test.dart` | Extension → language mapping, case-insensitivity, Dockerfile/Makefile detection, sorting |
| `test/unit/undo_redo_stack_test.dart` | Push/undo/redo semantics, redo-stack invalidation, max-entries eviction |
| `test/unit/file_node_test.dart` | Extension parsing, path-based equality, directory/file type checks |
| `test/unit/editor_provider_test.dart` | Opening real files from disk, find/replace (plain + regex + case-sensitive), undo/redo, save/dirty-state tracking |

---

## Known environment caveats

- **`android/gradle/wrapper/gradle-wrapper.jar`** is intentionally not bundled as a pre-built binary — it's a compiled artifact distributed by the Gradle project itself, not source code. The first `flutter build apk` / `flutter run` with an internet connection will have Gradle fetch it automatically as part of the normal build bootstrap (driven by `gradle-wrapper.properties`, which **is** included). This is standard for any Flutter Android project and is not specific to CodeForge.
- **`android/local.properties`** is machine-specific (local SDK paths) and is generated automatically the first time you open the project in Android Studio or run `flutter pub get`. See `android/local.properties.template` for the expected format if you ever need to create it by hand.

---

## Roadmap (Phase 2+)

- [ ] Integrated terminal (xterm.js via WebView)  
- [ ] Git operations (clone, commit, push, pull, diff, branch)  
- [ ] One-tap run & build (Flutter, Python, Node, …)  
- [ ] Live preview for HTML/Flutter  
- [ ] Debugger (breakpoints, watch, call stack)  
- [ ] Extension marketplace  
- [ ] Cloud sync & backup  
- [ ] Real-time collaboration  

---

## License

MIT
