import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/services/ai_service.dart';
import '../core/theme/app_themes.dart';
import '../providers/editor_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/app_dialogs.dart';

/// Settings screen: appearance (theme), editor preferences (font, tab size,
/// auto-save, smart editing), and AI assistant configuration (API key,
/// model).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Appearance'),
          const _AppearanceSection(),
          const SizedBox(height: 24),
          const _SectionHeader('Editor'),
          const _EditorSection(),
          const SizedBox(height: 24),
          const _SectionHeader('AI Assistant'),
          const _AiSection(),
          const SizedBox(height: 24),
          const _SectionHeader('About'),
          const _AboutSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return _SectionCard(
      children: [
        Text('Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SegmentedButton<AppThemeMode>(
          segments: [
            for (final mode in AppThemeMode.values) ButtonSegment(value: mode, label: Text(mode.label), icon: Icon(mode.icon, size: 18)),
          ],
          selected: {theme.mode},
          onSelectionChanged: (selection) => theme.setMode(selection.first),
        ),
      ],
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final editor = context.read<EditorProvider>();

    return _SectionCard(
      children: [
        Text('Font', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final font in EditorFontFamily.values)
          RadioListTile<EditorFontFamily>(
            value: font,
            groupValue: settings.fontFamily,
            contentPadding: EdgeInsets.zero,
            title: Text('${font.label}  —  Aa 123', style: font.textStyle(fontSize: 15)),
            onChanged: (value) {
              if (value != null) settings.setFontFamily(value);
            },
          ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Font size', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text('${settings.fontSize.toStringAsFixed(0)} pt'),
          ],
        ),
        Slider(
          value: settings.fontSize,
          min: AppConstants.minFontSize,
          max: AppConstants.maxFontSize,
          divisions: (AppConstants.maxFontSize - AppConstants.minFontSize).toInt(),
          label: settings.fontSize.toStringAsFixed(0),
          onChanged: (value) => settings.setFontSize(value),
        ),
        const Divider(height: 24),
        Text('Tab size', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2 spaces')),
            ButtonSegment(value: 4, label: Text('4 spaces')),
            ButtonSegment(value: 8, label: Text('8 spaces')),
          ],
          selected: {settings.tabSize},
          onSelectionChanged: (selection) {
            final value = selection.first;
            settings.setTabSize(value);
            editor.updateEditorSettings(tabSize: value);
          },
        ),
        const Divider(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Word wrap'),
          subtitle: const Text('Wrap long lines instead of scrolling horizontally'),
          value: settings.wordWrap,
          onChanged: settings.setWordWrap,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Line numbers & folding'),
          subtitle: const Text('Show the gutter with line numbers and code folding handles'),
          value: settings.showLineNumbers,
          onChanged: settings.setShowLineNumbers,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-indent'),
          subtitle: const Text('Match the previous line\'s indentation on Enter'),
          value: settings.autoIndent,
          onChanged: (value) {
            settings.setAutoIndent(value);
            editor.updateEditorSettings(autoIndent: value);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-close brackets & quotes'),
          subtitle: const Text('Automatically insert ), ], }, " and \' pairs'),
          value: settings.autoCloseBrackets,
          onChanged: (value) {
            settings.setAutoCloseBrackets(value);
            editor.updateEditorSettings(autoCloseBrackets: value);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-save'),
          subtitle: const Text('Save the active file automatically while typing'),
          value: settings.autoSave,
          onChanged: settings.setAutoSave,
        ),
      ],
    );
  }
}

class _AiSection extends StatefulWidget {
  const _AiSection();

  @override
  State<_AiSection> createState() => _AiSectionState();
}

class _AiSectionState extends State<_AiSection> {
  final _apiKeyController = TextEditingController();
  bool _obscure = true;
  bool _loading = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final key = await AiService.instance.getApiKey();
    if (!mounted) return;
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      _apiKeyController.text = key ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final value = _apiKeyController.text.trim();
    if (value.isEmpty) {
      AppDialogs.showError(context, 'Enter an API key');
      return;
    }
    await AiService.instance.setApiKey(value);
    if (!mounted) return;
    setState(() => _hasKey = true);
    AppDialogs.showMessage(context, 'API key saved');
  }

  Future<void> _clear() async {
    await AiService.instance.clearApiKey();
    _apiKeyController.clear();
    if (!mounted) return;
    setState(() => _hasKey = false);
    AppDialogs.showMessage(context, 'API key removed');
  }

  Future<void> _editModel(SettingsProvider settings) async {
    final value = await AppDialogs.textInput(
      context: context,
      title: 'AI Model',
      label: 'Model ID',
      initialValue: settings.aiModel,
      confirmLabel: 'Save',
      validate: (v) => v.trim().isEmpty ? 'Enter a model ID' : '',
    );
    if (value != null && value.trim().isNotEmpty) {
      settings.setAiModel(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return _SectionCard(
      children: [
        Text('Gemini API key', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          TextField(
            controller: _apiKeyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'AIza…',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: _save, child: const Text('Save'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: _hasKey ? _clear : null, child: const Text('Remove'))),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Stored securely on this device using the Android keystore, and sent directly to Google\'s Gemini API — never through a CodeForge server.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Divider(height: 32),
        Text('Model', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(settings.aiModel),
          subtitle: const Text('Used for chat, code generation, and all AI actions'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editModel(settings),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bolt_rounded),
          title: const Text(AppConstants.appName),
          subtitle: Text('Version ${AppConstants.appVersion}'),
        ),
        const SizedBox(height: 4),
        Text(
          'A professional mobile code editor with an integrated AI assistant. '
          'More features — Git, terminal, debugging, and extensions — are on the roadmap.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
