/// Who authored a chat message in the AI assistant panel.
enum ChatRole { user, assistant, system }

/// A single message in an AI chat conversation.
class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isError = false,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// True if this message represents an error returned from the API.
  final bool isError;

  /// True while a response is still being generated.
  final bool isStreaming;

  ChatMessage copyWith({
    String? content,
    bool? isError,
    bool? isStreaming,
  }) {
    return ChatMessage(
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isError: isError ?? this.isError,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  /// Converts to the JSON shape expected by the Gemini generateContent API.
  ///
  /// Gemini uses [contents] with a [role] field ("user" / "model") and a
  /// [parts] list. System messages are not included here — they are injected
  /// as a leading "user" turn followed by a "model" acknowledgement in
  /// [AiService._buildContents].
  Map<String, dynamic>? toGeminiJson() {
    if (role == ChatRole.system) return null;
    return {
      'role': role == ChatRole.user ? 'user' : 'model',
      'parts': [
        {'text': content},
      ],
    };
  }
}
