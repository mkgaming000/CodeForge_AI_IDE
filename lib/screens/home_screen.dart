import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/recent_project.dart';
import '../core/services/file_system_service.dart';
import '../core/services/permission_service.dart';
import '../providers/file_explorer_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/ai/ai_chat_panel.dart';
import '../widgets/common/app_dialogs.dart';
import '../widgets/home/quick_action_card.dart';
import '../widgets/home/recent_project_tile.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

/// CodeForge's landing screen: quick actions (open folder, new project, AI
/// assistant, settings) and the recent-projects list.
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  /// Requests broad storage access if it hasn't been granted yet. Returns
  /// `true` if the app can proceed to open/create project folders.
  Future<bool> _ensureStorageAccess(BuildContext context) async {
    final status = await PermissionService.instance.checkStorageAccess();
    if (status == StorageAccessStatus.granted || status == StorageAccessStatus.notApplicable) {
      return true;
    }

    if (!context.mounted) return false;
    final proceed = await AppDialogs.confirm(
      context: context,
      title: 'Storage access needed',
      message: 'CodeForge needs access to your device storage to open, create, and edit project files.',
      confirmLabel: 'Continue',
    );
    if (!proceed) return false;

    final result = await PermissionService.instance.requestStorageAccess();
    if (result == StorageAccessStatus.granted) return true;

    if (result == StorageAccessStatus.permanentlyDenied && context.mounted) {
      final openSettings = await AppDialogs.confirm(
        context: context,
        title: 'Permission required',
        message: 'Storage access was denied. Open system Settings and enable "All files access" for CodeForge to continue.',
        confirmLabel: 'Open Settings',
      );
      if (openSettings) await PermissionService.instance.openSettings();
    } else if (context.mounted) {
      AppDialogs.showError(context, 'Storage permission is required to open projects.');
    }
    return false;
  }

  Future<void> _openProjectAt(BuildContext context, String path) async {
    final projects = context.read<ProjectProvider>();
    final explorer = context.read<FileExplorerProvider>();

    await projects.openProject(path);
    await explorer.openProject(path);

    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorScreen()));
  }

  Future<void> _openFolder(BuildContext context) async {
    if (!await _ensureStorageAccess(context)) return;

    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select a project folder');
    if (path == null) return;
    if (!context.mounted) return;
    await _openProjectAt(context, path);
  }

  Future<void> _createProject(BuildContext context) async {
    if (!await _ensureStorageAccess(context)) return;

    final parentPath = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose a location for the new project');
    if (parentPath == null) return;
    if (!context.mounted) return;

    final name = await AppDialogs.textInput(
      context: context,
      title: 'New Project',
      label: 'Project name',
      initialValue: 'MyProject',
      confirmLabel: 'Create',
      validate: (v) => AppDialogs.validateName(v) ?? '',
    );
    if (name == null) return;
    if (!context.mounted) return;

    try {
      final dir = await FileSystemService.instance.createDirectory(parentPath, name);
      if (!context.mounted) return;
      await _openProjectAt(context, dir.path);
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showError(context, e.toString().replaceFirst(RegExp(r'^(FileSystemException|Exception):\s*'), ''));
      }
    }
  }

  Future<void> _removeRecent(BuildContext context, RecentProject project) async {
    await context.read<ProjectProvider>().removeRecentProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      endDrawer: const AiChatPanel(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('CodeForge'),
          ],
        ),
        actions: [
          Builder(
            builder: (innerContext) => IconButton(
              tooltip: 'AI Assistant',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Quick actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                QuickActionCard(
                  icon: Icons.folder_open_outlined,
                  title: 'Open Folder',
                  subtitle: 'Open an existing project from storage',
                  onTap: () => _openFolder(context),
                ),
                QuickActionCard(
                  icon: Icons.create_new_folder_outlined,
                  title: 'New Project',
                  subtitle: 'Create a fresh project folder',
                  onTap: () => _createProject(context),
                ),
                Builder(
                  builder: (innerContext) => QuickActionCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'AI Assistant',
                    subtitle: 'Chat, generate, and debug with Gemini',
                    onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                  ),
                ),
                QuickActionCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Theme, editor, and AI preferences',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Recent projects', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (projects.recentProjects.isEmpty)
              _buildEmptyState(context)
            else
              for (final project in projects.recentProjects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RecentProjectTile(
                    project: project,
                    onTap: () => _openProjectAt(context, project.path),
                    onTogglePin: () => context.read<ProjectProvider>().togglePinned(project),
                    onRemove: () => _removeRecent(context, project),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No projects yet',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Open an existing folder or create a new project to get started.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
