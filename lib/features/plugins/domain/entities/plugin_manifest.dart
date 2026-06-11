class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String category; // 'Models' | 'Themes' | 'Widgets' | 'Tools' | 'Prompts' | 'Knowledge'
  final List<String> permissions;
  final Map<String, dynamic> content;
  final bool isEnabled;
  final bool isInstalled;

  PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.category,
    required this.permissions,
    required this.content,
    this.isEnabled = false,
    this.isInstalled = false,
  });

  PluginManifest copyWith({
    String? name,
    String? version,
    String? description,
    String? author,
    String? category,
    List<String>? permissions,
    Map<String, dynamic>? content,
    bool? isEnabled,
    bool? isInstalled,
  }) {
    return PluginManifest(
      id: id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      author: author ?? this.author,
      category: category ?? this.category,
      permissions: permissions ?? this.permissions,
      content: content ?? this.content,
      isEnabled: isEnabled ?? this.isEnabled,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'category': category,
      'permissions': permissions,
      'content': content,
      'isEnabled': isEnabled,
      'isInstalled': isInstalled,
    };
  }

  factory PluginManifest.fromMap(Map<dynamic, dynamic> map) {
    return PluginManifest(
      id: map['id'] as String,
      name: map['name'] as String,
      version: map['version'] as String,
      description: map['description'] as String,
      author: map['author'] as String,
      category: map['category'] as String,
      permissions: (map['permissions'] as List?)?.cast<String>() ?? const [],
      content: Map<String, dynamic>.from(map['content'] as Map),
      isEnabled: map['isEnabled'] as bool? ?? false,
      isInstalled: map['isInstalled'] as bool? ?? false,
    );
  }
}
