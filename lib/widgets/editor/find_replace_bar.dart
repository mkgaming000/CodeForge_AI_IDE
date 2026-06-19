import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// TextMatch is defined in editor_provider.dart alongside EditorProvider.
import '../../providers/editor_provider.dart';
import '../common/app_dialogs.dart';

/// An in-editor Find & Replace bar: live match highlighting, next/previous
/// navigation, case-sensitive and regex toggles, and Replace / Replace All.
///
/// Operates on the currently active tab via [EditorProvider].
class FindReplaceBar extends StatefulWidget {
  const FindReplaceBar({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _findFocus = FocusNode();

  bool _caseSensitive = false;
  bool _useRegex = false;
  bool _showReplace = false;

  List<TextMatch> _matches = const [];
  int _currentMatch = -1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _findFocus.requestFocus());
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _runSearch);
  }

  void _runSearch() {
    final editor = context.read<EditorProvider>();
    final query = _findController.text;
    final matches = editor.findAll(query, caseSensitive: _caseSensitive, useRegex: _useRegex);
    setState(() {
      _matches = matches;
      _currentMatch = matches.isEmpty ? -1 : 0;
    });
    _selectCurrent();
  }

  void _selectCurrent() {
    if (_currentMatch < 0 || _currentMatch >= _matches.length) return;
    context.read<EditorProvider>().selectMatch(_matches[_currentMatch]);
  }

  void _next() {
    if (_matches.isEmpty) return;
    setState(() => _currentMatch = (_currentMatch + 1) % _matches.length);
    _selectCurrent();
  }

  void _previous() {
    if (_matches.isEmpty) return;
    setState(() => _currentMatch = (_currentMatch - 1 + _matches.length) % _matches.length);
    _selectCurrent();
  }

  void _replaceCurrent() {
    if (_currentMatch < 0 || _currentMatch >= _matches.length) return;
    final editor = context.read<EditorProvider>();
    final match = _matches[_currentMatch];
    editor.replaceRange(match.start, match.length, _replaceController.text);
    final keepIndex = _currentMatch;
    final matches = editor.findAll(_findController.text, caseSensitive: _caseSensitive, useRegex: _useRegex);
    setState(() {
      _matches = matches;
      _currentMatch = matches.isEmpty ? -1 : keepIndex.clamp(0, matches.length - 1).toInt();
    });
    _selectCurrent();
  }

  void _replaceAll() {
    final editor = context.read<EditorProvider>();
    final count = editor.replaceAll(
      _findController.text,
      _replaceController.text,
      caseSensitive: _caseSensitive,
      useRegex: _useRegex,
    );
    if (count > 0) {
      AppDialogs.showMessage(context, '$count replacement${count == 1 ? '' : 's'} made');
    }
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _findController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _findController,
                  focusNode: _findFocus,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _next(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Find',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixText: hasQuery ? (_matches.isEmpty ? 'No results' : '${_currentMatch + 1}/${_matches.length}') : null,
                    suffixStyle: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Match case',
                isSelected: _caseSensitive,
                icon: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  setState(() => _caseSensitive = !_caseSensitive);
                  _runSearch();
                },
                style: IconButton.styleFrom(
                  foregroundColor: _caseSensitive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Use regular expression',
                isSelected: _useRegex,
                icon: const Text('.*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  setState(() => _useRegex = !_useRegex);
                  _runSearch();
                },
                style: IconButton.styleFrom(
                  foregroundColor: _useRegex ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Previous match',
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                onPressed: _matches.isEmpty ? null : _previous,
              ),
              IconButton(
                tooltip: 'Next match',
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                onPressed: _matches.isEmpty ? null : _next,
              ),
              IconButton(
                tooltip: _showReplace ? 'Hide replace' : 'Replace',
                icon: Icon(_showReplace ? Icons.expand_less : Icons.find_replace, size: 20),
                onPressed: () => setState(() => _showReplace = !_showReplace),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
          if (_showReplace)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replaceController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Replace',
                        prefixIcon: Icon(Icons.find_replace, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _matches.isEmpty ? null : _replaceCurrent,
                    child: const Text('Replace'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: !hasQuery ? null : _replaceAll,
                    child: const Text('All'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
