# Changelog

All notable changes to CodeForge are documented in this file.

## [1.0.0] — Phase 1: Core Editor & AI Assistant

### Added
- **Code editor**: syntax highlighting for 30+ languages, code folding, line numbers, auto-indent, smart bracket/quote auto-closing with skip-over, bounded undo/redo history per tab.
- **Tabs**: unlimited open files with dirty-state indicators, keep-alive across tab switches, unsaved-changes confirmation on close.
- **Find & Replace**: live in-file search with case-sensitive and regex modes, next/previous navigation, single Replace and Replace All.
- **File Explorer**: full tree view with lazy-loaded directories, create/rename/delete/duplicate file and folder, cut/copy/paste, name search, hidden-file toggle.
- **AI Assistant**: Claude-powered chat plus one-tap actions — Generate, Explain, Fix Bugs, Optimize, Refactor, Add Comments, Generate Unit Tests, Generate Documentation, Convert Language, Explain Error, and Generate README — each backed by a real Anthropic API call.
- **Themes**: Dark, Light, and AMOLED, all built on Material 3 with a shared accent palette.
- **Settings**: font family (5 monospace options) and size, tab size, word wrap, line numbers, auto-indent, auto-close brackets, auto-save, and AI model selection.
- **Storage permission flow**: handles both legacy (`READ/WRITE_EXTERNAL_STORAGE`) and modern (`MANAGE_EXTERNAL_STORAGE`, "All files access") Android permission models.
- **Home screen**: quick actions (Open Folder, New Project, AI Assistant, Settings) and a persisted, pinnable Recent Projects list.
- Full unit test suite for the language registry, undo/redo stack, file model, and editor provider's find/replace/save logic.

### Known limitations (tracked for Phase 2+)
- No integrated terminal, Git operations, run/build system, or debugger yet — these are explicitly scoped for the next phase rather than stubbed out with placeholder UI.
- No extension marketplace or real-time collaboration yet.
- Release builds currently sign with the debug keystore; replace with your own keystore before publishing to the Play Store.
