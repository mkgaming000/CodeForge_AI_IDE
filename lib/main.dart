import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/editor_provider.dart';
import 'providers/file_explorer_provider.dart';
import 'providers/project_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();

  // Created up front so EditorProvider can be seeded with the user's saved
  // editor preferences immediately.
  final settings = SettingsProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => FileExplorerProvider()),
        ChangeNotifierProvider(
          create: (_) => EditorProvider(
            tabSize: settings.tabSize,
            autoIndent: settings.autoIndent,
            autoCloseBrackets: settings.autoCloseBrackets,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
      ],
      child: const CodeForgeApp(),
    ),
  );
}
