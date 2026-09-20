class ComponentInfo {
  final String name;
  final bool isExported;
  final String? permission;
  final List<String> intentFilters;

  const ComponentInfo({
    required this.name,
    required this.isExported,
    this.permission,
    this.intentFilters = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isExported': isExported,
        'permission': permission,
        'intentFilters': intentFilters,
      };

  factory ComponentInfo.fromJson(Map<String, dynamic> json) => ComponentInfo(
        name: json['name'] as String? ?? '',
        isExported: json['isExported'] as bool? ?? false,
        permission: json['permission'] as String?,
        intentFilters: List<String>.from(json['intentFilters'] ?? []),
      );
}

class ManifestInfo {
  final List<ComponentInfo> activities;
  final List<ComponentInfo> services;
  final List<ComponentInfo> receivers;
  final List<ComponentInfo> providers;
  final List<String> permissions;
  final List<String> deepLinks;
  final Map<String, String> metadata;
  final Map<String, dynamic> appConfig;

  const ManifestInfo({
    required this.activities,
    required this.services,
    required this.receivers,
    required this.providers,
    required this.permissions,
    required this.deepLinks,
    required this.metadata,
    required this.appConfig,
  });

  Map<String, dynamic> toJson() => {
        'activities': activities.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'receivers': receivers.map((e) => e.toJson()).toList(),
        'providers': providers.map((e) => e.toJson()).toList(),
        'permissions': permissions,
        'deepLinks': deepLinks,
        'metadata': metadata,
        'appConfig': appConfig,
      };

  factory ManifestInfo.fromJson(Map<String, dynamic> json) => ManifestInfo(
        activities: (json['activities'] as List? ?? [])
            .map((e) => ComponentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        services: (json['services'] as List? ?? [])
            .map((e) => ComponentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        receivers: (json['receivers'] as List? ?? [])
            .map((e) => ComponentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        providers: (json['providers'] as List? ?? [])
            .map((e) => ComponentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        permissions: List<String>.from(json['permissions'] ?? []),
        deepLinks: List<String>.from(json['deepLinks'] ?? []),
        metadata: Map<String, String>.from(json['metadata'] ?? {}),
        appConfig: Map<String, dynamic>.from(json['appConfig'] ?? {}),
      );
}
