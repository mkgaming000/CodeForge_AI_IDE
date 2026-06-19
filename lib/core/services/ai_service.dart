import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';

/// Base exception type for AI-related failures. The [message] is suitable
/// for direct display to the user.
class AiServiceException implements Exception {
  AiServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thrown when no Gemini API key has been configured yet.
class MissingApiKeyException extends AiServiceException {
  MissingApiKeyException()
      : super(
          'No Gemini API key configured. '
          'Add one in Settings → AI Assistant to enable AI features.',
        );
}

/// All AI-powered features in CodeForge — chat, code generation, debugging,
/// refactoring, documentation, and more — are implemented as focused calls
/// to the Google Gemini generateContent API through this service.
///
/// The user supplies their own API key (stored securely via [StorageService]);
/// CodeForge never bundles or proxies a key of its own.
///
/// API reference:
///   https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
///
/// Request format:
/// ```json
/// {
///   "system_instruction": { "parts": [{ "text": "..." }] },
///   "generation_config": { "temperature": 0.3, "maxOutputTokens": 4096 },
///   "contents": [
///     { "role": "user",  "parts": [{ "text": "..." }] },
///     { "role": "model", "parts": [{ "text": "..." }] }
///   ]
/// }
/// ```
///
/// Response shape:
/// ```json
/// {
///   "candidates": [
///     {
///       "content": {
///         "parts": [{ "text": "..." }],
///         "role": "model"
///       }
///     }
///   ]
/// }
/// ```
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  static const String _defaultChatSystemPrompt =
      'You are the AI assistant built into CodeForge, a mobile code editor '
      'for Android. You help the user understand, write, debug, and improve '
      'code directly on their device. When you include code, always use '
      'fenced code blocks with the correct language tag. Be concise and '
      'actionable — the user is reading on a small screen, so prefer short '
      'paragraphs and bullet points over long prose. If the user shares a '
      'file path or project context, take it into account.';

  // -------------------------------------------------------------------
  // API key management
  // -------------------------------------------------------------------

  /// Returns the currently configured Gemini API key, or `null` if none set.
  Future<String?> getApiKey() =>
      StorageService.instance.getSecure(AppConstants.secureKeyGeminiApiKey);

  /// Stores [key] securely, replacing any previous key.
  Future<void> setApiKey(String key) => StorageService.instance
      .setSecure(AppConstants.secureKeyGeminiApiKey, key.trim());

  /// Removes the stored API key.
  Future<void> clearApiKey() =>
      StorageService.instance.deleteSecure(AppConstants.secureKeyGeminiApiKey);

  /// True if a Gemini API key has been configured.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// The Gemini model ID used for all requests, configurable in Settings.
  String get model =>
      StorageService.instance.getString(AppConstants.prefAiModel) ??
      AppConstants.defaultAiModel;

  // -------------------------------------------------------------------
  // Gemini request construction
  // -------------------------------------------------------------------

  /// Builds the [contents] array for the Gemini API from a [system] prompt
  /// and a list of [messages].
  ///
  /// Gemini has no dedicated "system" role. The conventional approach is to
  /// use the top-level [system_instruction] field (supported from Gemini 1.5+)
  /// which is what we do here. If a system prompt is supplied it is placed in
  /// [system_instruction]; the [contents] list contains only the
  /// user/assistant turns.
  ///
  /// For models that do not support [system_instruction] the fallback is to
  /// prepend a "user" turn with the system text followed by a "model"
  /// acknowledgement — but gemini-2.5-flash supports [system_instruction]
  /// natively, so we use the clean path.
  Map<String, dynamic> _buildBody({
    required List<Map<String, dynamic>> contents,
    String? system,
    int maxTokens = 4096,
    double temperature = 0.3,
  }) {
    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    };
    if (system != null && system.isNotEmpty) {
      body['system_instruction'] = {
        'parts': [
          {'text': system},
        ],
      };
    }
    return body;
  }

  // -------------------------------------------------------------------
  // Low-level API call
  // -------------------------------------------------------------------

  Future<String> _complete({
    required List<Map<String, dynamic>> contents,
    String? system,
    int maxTokens = 4096,
    double temperature = 0.3,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw MissingApiKeyException();
    }

    // Gemini endpoint: /v1beta/models/{model}:generateContent?key={apiKey}
    final uri = Uri.parse(
      '${AppConstants.geminiApiBaseUrl}/$model:generateContent?key=$apiKey',
    );

    final body = _buildBody(
      contents: contents,
      system: system,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));
    } on Exception catch (e) {
      throw AiServiceException('Network error while contacting Gemini: $e');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AiServiceException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200) {
      // Gemini error shape: { "error": { "message": "...", "code": 400 } }
      final error = decoded['error'];
      final message = error is Map && error['message'] is String
          ? error['message'] as String
          : 'Request failed with status ${response.statusCode}.';
      throw AiServiceException(message, statusCode: response.statusCode);
    }

    // Gemini response: candidates[0].content.parts[0].text
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final content = candidates[0]['content'];
    if (content is! Map) return '';

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------
  // Chat helper — converts ChatMessage list → Gemini contents array
  // -------------------------------------------------------------------

  List<Map<String, dynamic>> _chatContents(List<ChatMessage> history) {
    return history
        .map((m) => m.toGeminiJson())
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // -------------------------------------------------------------------
  // AI Chat
  // -------------------------------------------------------------------

  /// Sends a full conversation (including the latest user message) and
  /// returns the assistant's reply as plain text / markdown.
  Future<String> sendChatMessage(
    List<ChatMessage> history, {
    String? systemPrompt,
  }) {
    return _complete(
      contents: _chatContents(history),
      system: systemPrompt ?? _defaultChatSystemPrompt,
      maxTokens: 4096,
      temperature: 0.4,
    );
  }

  // -------------------------------------------------------------------
  // Code understanding & generation
  // -------------------------------------------------------------------

  Future<String> explainCode(String code, String languageName) {
    return _complete(
      system: 'You are a senior $languageName engineer. Explain the given '
          'code clearly and concisely for another developer reading it on a '
          'small screen. Cover what it does, how it works (key steps / '
          'algorithms), and any notable edge cases or side effects. Use short '
          'paragraphs and, if helpful, a brief bullet list. Do not repeat the '
          'entire source code back.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'Explain this $languageName code:\n\n```$languageName\n$code\n```'},
          ],
        },
      ],
      maxTokens: 2048,
    );
  }

  Future<String> generateCode({
    required String prompt,
    String? languageName,
    String? projectContext,
    String? currentFileContent,
  }) {
    final contextParts = <String>[];
    if (projectContext != null && projectContext.isNotEmpty) {
      contextParts.add('Project structure:\n$projectContext');
    }
    if (currentFileContent != null && currentFileContent.isNotEmpty) {
      contextParts.add('Current file contents:\n```\n$currentFileContent\n```');
    }
    final contextBlock =
        contextParts.isEmpty ? '' : '\n\n${contextParts.join('\n\n')}';

    return _complete(
      system: 'You are an expert software engineer generating production-ready '
          'code inside CodeForge, a mobile IDE. Respond with the requested '
          'code in fenced code blocks using accurate language tags. If '
          'multiple files are needed, label each with its filename as a '
          'heading before its code block (e.g. "### lib/main.dart"). Write '
          'complete, working code with no placeholders or TODO comments. Add '
          'a brief 1-2 sentence summary before the code.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  '${languageName != null ? 'Target language/framework: $languageName\n\n' : ''}'
                  'Request: $prompt$contextBlock',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> fixBugs({
    required String code,
    required String languageName,
    String? errorMessage,
  }) {
    final errorBlock = errorMessage != null && errorMessage.isNotEmpty
        ? '\n\nThe following error/output was produced:\n```\n$errorMessage\n```'
        : '';
    return _complete(
      system: 'You are an expert $languageName debugger. Find and fix bugs, '
          'compile errors, or runtime errors in the given code. Return the '
          'corrected code in a single fenced code block, followed by a short '
          'bullet list explaining each fix. Do not change unrelated code or '
          'formatting beyond what is needed for the fix.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Fix the bugs in this $languageName code.$errorBlock\n\n```$languageName\n$code\n```',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> optimizeCode(String code, String languageName) {
    return _complete(
      system: 'You are a performance engineer specializing in $languageName. '
          'Optimize the given code for performance and memory usage while '
          'preserving its behavior. Return the optimized code in a single '
          'fenced code block, followed by a short bullet list of what changed '
          'and why.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'Optimize this $languageName code:\n\n```$languageName\n$code\n```'},
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> refactorCode({
    required String code,
    required String languageName,
    required String instruction,
  }) {
    return _complete(
      system: 'You are an expert $languageName engineer performing a refactor. '
          'Apply the requested change while preserving behavior and following '
          '$languageName best practices and idioms. Return the refactored code '
          'in a single fenced code block, followed by a short summary of the '
          'changes.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Refactor this $languageName code: $instruction\n\n```$languageName\n$code\n```',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> addComments(String code, String languageName) {
    return _complete(
      system: 'You are an expert $languageName engineer. Add clear, '
          'professional documentation comments and inline comments to the '
          'given code, explaining non-obvious logic, parameters, and return '
          'values. Follow $languageName documentation-comment conventions '
          '(e.g. doc comments, docstrings, Javadoc). Do not change the '
          "code's behavior. Return only the commented code in a single "
          'fenced code block.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Add documentation and inline comments to this $languageName code:\n\n```$languageName\n$code\n```',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> generateUnitTests(String code, String languageName) {
    return _complete(
      system: 'You are an expert $languageName test engineer. Write a thorough '
          'unit test suite for the given code using the standard or most '
          'popular testing framework for $languageName. Cover normal cases, '
          'edge cases, and error conditions. Return the test code in a single '
          'fenced code block, with a short note on which framework it assumes '
          'and how to run it.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'Write unit tests for this $languageName code:\n\n```$languageName\n$code\n```'},
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> generateDocumentation(String code, String languageName) {
    return _complete(
      system: 'You are a technical writer and $languageName expert. Generate '
          'clear API/reference documentation in Markdown for the given code, '
          'describing its purpose, public classes/functions, parameters, '
          'return values, and a short usage example.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Generate documentation for this $languageName code:\n\n```$languageName\n$code\n```',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }

  Future<String> generateReadme({
    required String projectName,
    required String fileTree,
    String? sampleFileContent,
  }) {
    final sampleBlock =
        sampleFileContent != null && sampleFileContent.isNotEmpty
            ? '\n\nSample file contents:\n```\n$sampleFileContent\n```'
            : '';
    return _complete(
      system: 'You are a technical writer. Generate a polished README.md in '
          'Markdown for a software project: a title and short description, '
          'key features, a project structure overview, setup/run instructions, '
          'and a short license section. Base the content on the provided file '
          'tree and any sample code shown. Return only the Markdown content.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Project name: $projectName\n\nFile tree:\n```\n$fileTree\n```$sampleBlock',
            },
          ],
        },
      ],
      maxTokens: 4096,
    );
  }

  Future<String> generateCommitMessage(String diff) {
    return _complete(
      system: 'You write excellent git commit messages following the '
          'Conventional Commits style ("feat:", "fix:", "refactor:", "docs:", '
          'etc.). Given a diff, write a concise subject line (max ~72 '
          'characters) and, if useful, a short body with bullet points '
          'describing the change. Return only the commit message text.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'Write a commit message for this diff:\n\n```diff\n$diff\n```'},
          ],
        },
      ],
      maxTokens: 1024,
      temperature: 0.2,
    );
  }

  Future<String> explainError({
    required String errorMessage,
    String? code,
    String? languageName,
  }) {
    final codeBlock = code != null && code.isNotEmpty
        ? '\n\nRelevant code:\n```${languageName ?? ''}\n$code\n```'
        : '';
    return _complete(
      system: 'You are an expert software engineer. Explain the given error or '
          'stack trace in plain language: what it means, the most likely '
          'cause, and concrete steps to fix it. If relevant code is provided, '
          'point to the specific line(s) responsible.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Explain this error and how to fix it:\n\n```\n$errorMessage\n```$codeBlock',
            },
          ],
        },
      ],
      maxTokens: 4096,
    );
  }

  Future<String> convertCode({
    required String code,
    required String fromLanguage,
    required String toLanguage,
  }) {
    return _complete(
      system: 'You are an expert in both $fromLanguage and $toLanguage. '
          'Translate the given $fromLanguage code into idiomatic, '
          'production-ready $toLanguage, preserving behavior. Return only the '
          'translated code in a single fenced code block, followed by a short '
          'note on any libraries or APIs that differ between the two '
          'languages.',
      contents: [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Translate this $fromLanguage code to $toLanguage:\n\n```$fromLanguage\n$code\n```',
            },
          ],
        },
      ],
      maxTokens: 8192,
    );
  }
}
