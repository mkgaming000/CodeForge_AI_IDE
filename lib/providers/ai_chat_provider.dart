import 'package:flutter/material.dart';

import '../core/models/chat_message.dart';
import '../core/services/ai_service.dart';

/// Holds the AI assistant's conversation history and exposes both free-form
/// chat ([sendMessage]) and structured quick actions ([runAction], used for
/// "Explain Code", "Fix Bugs", etc.).
class AiChatProvider extends ChangeNotifier {
  final AiService _ai = AiService.instance;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastError;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isEmpty => _messages.isEmpty;

  /// Sends a free-form chat message from the user.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _lastError = null;
    _messages.add(ChatMessage(role: ChatRole.user, content: trimmed));
    notifyListeners();

    await _runAndAppend(() => _ai.sendChatMessage(_messages));
  }

  /// Runs a structured AI action (e.g. "Explain this code"). [userFacingPrompt]
  /// is appended as the user's message so the conversation reads naturally,
  /// and [action] performs the actual API call.
  Future<void> runAction(String userFacingPrompt, Future<String> Function() action) async {
    if (_isLoading) return;

    _lastError = null;
    _messages.add(ChatMessage(role: ChatRole.user, content: userFacingPrompt));
    notifyListeners();

    await _runAndAppend(action);
  }

  Future<void> _runAndAppend(Future<String> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await action();
      _messages.add(ChatMessage(role: ChatRole.assistant, content: response));
    } catch (e) {
      final message = e.toString();
      _lastError = message;
      _messages.add(ChatMessage(role: ChatRole.assistant, content: message, isError: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _lastError = null;
    notifyListeners();
  }
}
