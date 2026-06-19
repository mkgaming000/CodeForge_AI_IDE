import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/chat_message.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/language_registry.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_explorer_provider.dart';
import '../../screens/settings_screen.dart';
import '../common/app_dialogs.dart';

/// The AI assistant drawer: free-form chat plus one-tap quick actions
/// (Generate, Explain, Fix Bugs, Optimize, Refactor, Comment, Tests, Docs,
/// Convert, Explain Error, README) that operate on the active editor tab.
class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool? _hasApiKey;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final has = await AiService.instance.hasApiKey();
    if (mounted) setState(() => _hasApiKey = has);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _ensureApiKey() async {
    final has = await AiService.instance.hasApiKey();
    if (!has && mounted) {
      AppDialogs.showError(context, 'Add your Gemini API key in Settings → AI Assistant first.');
      setState(() => _hasApiKey = false);
    }
    return has;
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    if (!await _ensureApiKey()) return;
    if (!mounted) return;
    _inputController.clear();
    _scrollToBottom();
    await context.read<AiChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  /// The code to act on (the active tab's selection if non-empty, otherwise
  /// the whole file), its language, and the file name — or `null` if no
  /// file is open.
  ({String code, String language, String fileName, bool isSelection})? _activeCodeContext() {
    final tab = context.read<EditorProvider>().activeTab;
    if (tab == null) return null;
    final controller = tab.controller;
    final fullText = controller.fullText;
    final selection = controller.selection;
    final isSelection = selection.isValid && !selection.isCollapsed;
    final code = isSelection ? selection.textInside(fullText) : fullText;
    return (code: code, language: tab.language.displayName, fileName: tab.fileName, isSelection: isSelection);
  }

  Future<void> _runFileAction({
    required String label,
    required Future<String> Function(String code, String language) action,
  }) async {
    final ctx = _activeCodeContext();
    if (ctx == null) {
      AppDialogs.showError(context, 'Open a file first.');
      return;
    }
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    final prompt = '$label ${ctx.fileName}${ctx.isSelection ? ' (selection)' : ''}';
    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(prompt, () => action(ctx.code, ctx.language));
    _scrollToBottom();
  }

  Future<void> _generateCode() async {
    final prompt = await AppDialogs.textInput(
      context: context,
      title: 'Generate Code',
      label: 'Describe what to build, e.g. "a login screen with email and password fields"',
      confirmLabel: 'Generate',
      maxLines: 4,
      validate: (v) => v.trim().isEmpty ? 'Describe what you need' : '',
    );
    if (prompt == null || prompt.trim().isEmpty) return;
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    final editor = context.read<EditorProvider>();
    final explorer = context.read<FileExplorerProvider>();
    final tab = editor.activeTab;
    final fileTree = explorer.hasProject ? await explorer.buildFileTreeString() : null;
    if (!mounted) return;

    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(
      'Generate: $prompt',
      () => AiService.instance.generateCode(
        prompt: prompt,
        languageName: tab?.language.displayName,
        projectContext: fileTree,
        currentFileContent: tab?.controller.fullText,
      ),
    );
    _scrollToBottom();
  }

  Future<void> _refactor() async {
    final ctx = _activeCodeContext();
    if (ctx == null) {
      AppDialogs.showError(context, 'Open a file first.');
      return;
    }
    final instruction = await AppDialogs.textInput(
      context: context,
      title: 'Refactor',
      label: 'What should change? e.g. "extract this into smaller functions"',
      confirmLabel: 'Refactor',
      maxLines: 3,
      validate: (v) => v.trim().isEmpty ? 'Describe the change' : '',
    );
    if (instruction == null || instruction.trim().isEmpty) return;
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(
      'Refactor ${ctx.fileName}${ctx.isSelection ? ' (selection)' : ''}: $instruction',
      () => AiService.instance.refactorCode(code: ctx.code, languageName: ctx.language, instruction: instruction),
    );
    _scrollToBottom();
  }

  Future<void> _convertLanguage() async {
    final ctx = _activeCodeContext();
    if (ctx == null) {
      AppDialogs.showError(context, 'Open a file first.');
      return;
    }
    final target = await _pickLanguage(context, excludeDisplayName: ctx.language);
    if (target == null) return;
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(
      'Convert ${ctx.fileName} from ${ctx.language} to $target',
      () => AiService.instance.convertCode(code: ctx.code, fromLanguage: ctx.language, toLanguage: target),
    );
    _scrollToBottom();
  }

  Future<void> _explainError() async {
    final error = await AppDialogs.textInput(
      context: context,
      title: 'Explain Error',
      label: 'Paste the error message or stack trace',
      confirmLabel: 'Explain',
      maxLines: 6,
      validate: (v) => v.trim().isEmpty ? 'Paste an error message' : '',
    );
    if (error == null || error.trim().isEmpty) return;
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    final ctx = _activeCodeContext();
    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(
      'Explain this error',
      () => AiService.instance.explainError(errorMessage: error, code: ctx?.code, languageName: ctx?.language),
    );
    _scrollToBottom();
  }

  Future<void> _generateReadme() async {
    final explorer = context.read<FileExplorerProvider>();
    if (!explorer.hasProject) {
      AppDialogs.showError(context, 'Open a project first.');
      return;
    }
    if (!await _ensureApiKey()) return;
    if (!mounted) return;

    final tree = await explorer.buildFileTreeString();
    if (!mounted) return;
    final tab = context.read<EditorProvider>().activeTab;
    _scrollToBottom();
    await context.read<AiChatProvider>().runAction(
      'Generate a README for this project',
      () => AiService.instance.generateReadme(
        projectName: explorer.root?.name ?? 'Project',
        fileTree: tree,
        sampleFileContent: tab?.controller.fullText,
      ),
    );
    _scrollToBottom();
  }

  Future<String?> _pickLanguage(BuildContext context, {String? excludeDisplayName}) {
    final languages = LanguageRegistry.all.where((l) => l.displayName != excludeDisplayName).toList();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Convert to…', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final lang in languages)
                ListTile(
                  leading: Icon(lang.icon, color: lang.color),
                  title: Text(lang.displayName),
                  onTap: () => Navigator.pop(context, lang.displayName),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<AiChatProvider>();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.92,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, chat),
            const Divider(height: 1),
            _buildQuickActions(context),
            const Divider(height: 1),
            if (_hasApiKey == false) _buildApiKeyBanner(context),
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chat.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _ChatBubble(message: chat.messages[index]);
                      },
                    ),
            ),
            _buildInputBar(context, chat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AiChatProvider chat) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('AI Assistant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: chat.messages.isEmpty ? null : chat.clear,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final ai = AiService.instance;
    final actions = <_QuickAction>[
      _QuickAction('Generate', Icons.add_circle_outline, _generateCode),
      _QuickAction('Explain', Icons.help_outline, () => _runFileAction(label: 'Explain', action: ai.explainCode)),
      _QuickAction(
        'Fix Bugs',
        Icons.bug_report_outlined,
        () => _runFileAction(label: 'Fix bugs in', action: (c, l) => ai.fixBugs(code: c, languageName: l)),
      ),
      _QuickAction('Optimize', Icons.speed_outlined, () => _runFileAction(label: 'Optimize', action: ai.optimizeCode)),
      _QuickAction('Refactor', Icons.auto_fix_high_outlined, _refactor),
      _QuickAction('Comment', Icons.comment_outlined, () => _runFileAction(label: 'Add comments to', action: ai.addComments)),
      _QuickAction('Tests', Icons.science_outlined, () => _runFileAction(label: 'Generate unit tests for', action: ai.generateUnitTests)),
      _QuickAction('Docs', Icons.description_outlined, () => _runFileAction(label: 'Generate documentation for', action: ai.generateDocumentation)),
      _QuickAction('Convert', Icons.swap_horiz, _convertLanguage),
      _QuickAction('Explain Error', Icons.error_outline, _explainError),
      _QuickAction('README', Icons.menu_book_outlined, _generateReadme),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            avatar: Icon(action.icon, size: 16),
            label: Text(action.label),
            onPressed: action.onTap,
          );
        },
      ),
    );
  }

  Widget _buildApiKeyBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withOpacity(0.08),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.key_outlined, color: theme.colorScheme.primary),
        title: const Text('Add your Gemini API key to enable AI features'),
        trailing: TextButton(
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            _checkApiKey();
          },
          child: const Text('Settings'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Ask anything about your code, or tap a quick action above.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AiChatProvider chat) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask the AI assistant…',
                isDense: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: chat.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_upward),
            onPressed: chat.isLoading ? null : _send,
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Renders a single chat message, splitting its content into plain-text and
/// fenced-code-block segments.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  static final RegExp _codeBlockPattern = RegExp(r'```(\w*)\n?([\s\S]*?)```');

  List<_Segment> _parseSegments(String content) {
    final segments = <_Segment>[];
    var lastEnd = 0;
    for (final match in _codeBlockPattern.allMatches(content)) {
      if (match.start > lastEnd) {
        final text = content.substring(lastEnd, match.start).trim();
        if (text.isNotEmpty) segments.add(_Segment.text(text));
      }
      final lang = match.group(1) ?? '';
      final code = (match.group(2) ?? '').trimRight();
      segments.add(_Segment.code(code, lang));
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      final text = content.substring(lastEnd).trim();
      if (text.isNotEmpty) segments.add(_Segment.text(text));
    }
    if (segments.isEmpty) {
      final trimmed = content.trim();
      if (trimmed.isNotEmpty) segments.add(_Segment.text(trimmed));
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final segments = _parseSegments(message.content);

    final bubbleColor = message.isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? theme.colorScheme.primary.withOpacity(0.14)
            : theme.colorScheme.surfaceContainerHighest;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final segment in segments)
                if (segment.isCode)
                  _CodeBlock(code: segment.text, language: segment.language)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      segment.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: message.isError ? theme.colorScheme.onErrorContainer : null,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment {
  _Segment.text(this.text)
      : isCode = false,
        language = '';

  _Segment.code(this.text, this.language) : isCode = true;

  final String text;
  final bool isCode;
  final String language;
}

/// A fenced code block with "Copy" and "Insert into editor" actions.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, required this.language});

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 0),
            child: Row(
              children: [
                Text(
                  language.isEmpty ? 'code' : language,
                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 16, color: Colors.white60),
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    AppDialogs.showMessage(context, 'Copied to clipboard');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.input, size: 16, color: Colors.white60),
                  tooltip: 'Insert into editor',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final inserted = context.read<EditorProvider>().insertTextAtCursor(code);
                    AppDialogs.showMessage(context, inserted ? 'Inserted into editor' : 'Open a file first');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: GoogleFonts.jetBrainsMono(fontSize: 12.5, color: const Color(0xFFD4D4D4), height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Thinking…" indicator shown while waiting for an AI response.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
            const SizedBox(width: 10),
            Text('Thinking…', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
