import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/models/recent_project.dart';
import '../core/services/storage_service.dart';

/// Tracks which project (folder) is currently open and maintains the
/// "Recent Projects" list shown on the home screen.
class ProjectProvider extends ChangeNotifier {
  ProjectProvider() {
    _load();
  }

  List<RecentProject> _recentProjects = [];
  String? _currentProjectPath;

  List<RecentProject> get recentProjects => List.unmodifiable(_recentProjects);
  String? get currentProjectPath => _currentProjectPath;
  bool get hasOpenProject => _currentProjectPath != null;

  String? get currentProjectName {
    final path = _currentProjectPath;
    if (path == null) return null;
    return _baseName(path);
  }

  String _baseName(String path) {
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? path : parts.last;
  }

  void _load() {
    final stored = StorageService.instance.getJson<List<dynamic>>(
      AppConstants.prefRecentProjects,
      (decoded) => decoded as List<dynamic>,
    );
    if (stored == null) return;
    _recentProjects = stored.map((e) => RecentProject.fromJson(e as Map<String, dynamic>)).toList();
    _sort();
    notifyListeners();
  }

  void _sort() {
    _recentProjects.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.lastOpened.compareTo(a.lastOpened);
    });
  }

  Future<void> _persist() {
    return StorageService.instance.setJson(
      AppConstants.prefRecentProjects,
      _recentProjects.map((p) => p.toJson()).toList(),
    );
  }

  /// Marks [path] as the active project and records it in recent projects.
  Future<void> openProject(String path) async {
    final existingIndex = _recentProjects.indexWhere((p) => p.path == path);
    if (existingIndex != -1) {
      _recentProjects[existingIndex] = _recentProjects[existingIndex].copyWith(lastOpened: DateTime.now());
    } else {
      _recentProjects.insert(0, RecentProject(path: path, name: _baseName(path), lastOpened: DateTime.now()));
    }
    _trimAndSort();
    _currentProjectPath = path;
    notifyListeners();
    await _persist();
  }

  void _trimAndSort() {
    _sort();
    if (_recentProjects.length > AppConstants.maxRecentProjects) {
      final pinned = _recentProjects.where((p) => p.isPinned).toList();
      final unpinned = _recentProjects.where((p) => !p.isPinned).toList();
      final keep = (AppConstants.maxRecentProjects - pinned.length).clamp(0, unpinned.length).toInt();
      _recentProjects = [...pinned, ...unpinned.take(keep)];
      _sort();
    }
  }

  void closeProject() {
    _currentProjectPath = null;
    notifyListeners();
  }

  Future<void> togglePinned(RecentProject project) async {
    final index = _recentProjects.indexWhere((p) => p.path == project.path);
    if (index == -1) return;
    _recentProjects[index] = _recentProjects[index].copyWith(isPinned: !_recentProjects[index].isPinned);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> removeRecentProject(RecentProject project) async {
    _recentProjects.removeWhere((p) => p.path == project.path);
    notifyListeners();
    await _persist();
  }
}
