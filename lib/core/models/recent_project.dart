/// A previously opened project (folder) shown on the home screen.
class RecentProject {
  RecentProject({
    required this.path,
    required this.name,
    required this.lastOpened,
    this.isPinned = false,
  });

  /// Absolute path to the project's root folder.
  final String path;

  /// Display name (usually the folder name).
  final String name;

  /// When this project was last opened.
  final DateTime lastOpened;

  /// Whether the user pinned this project to the top of the list.
  final bool isPinned;

  RecentProject copyWith({
    String? path,
    String? name,
    DateTime? lastOpened,
    bool? isPinned,
  }) {
    return RecentProject(
      path: path ?? this.path,
      name: name ?? this.name,
      lastOpened: lastOpened ?? this.lastOpened,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'lastOpened': lastOpened.toIso8601String(),
        'isPinned': isPinned,
      };

  factory RecentProject.fromJson(Map<String, dynamic> json) {
    return RecentProject(
      path: json['path'] as String,
      name: json['name'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) => other is RecentProject && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
