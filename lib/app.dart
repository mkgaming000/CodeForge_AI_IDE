import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

/// Root widget: applies the current [ThemeProvider] theme and shows the
/// home screen.
class CodeForgeApp extends StatelessWidget {
  const CodeForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: HomeScreen(),
    );
  }
}
