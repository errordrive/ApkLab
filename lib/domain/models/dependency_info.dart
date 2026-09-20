class DependencyItem {
  final String source;
  final String target;
  final String type; // Class, Method, Resource, Manifest, Reflection, Native, String
  final bool requiresManualReview;
  final String reviewReason;
  final String confidence;

  const DependencyItem({
    required this.source,
    required this.target,
    required this.type,
    this.requiresManualReview = false,
    this.reviewReason = '',
    this.confidence = 'HIGH',
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'target': target,
        'type': type,
        'requiresManualReview': requiresManualReview,
        'reviewReason': reviewReason,
        'confidence': confidence,
      };

  factory DependencyItem.fromJson(Map<String, dynamic> json) => DependencyItem(
        source: json['source'] as String? ?? '',
        target: json['target'] as String? ?? '',
        type: json['type'] as String? ?? 'Class',
        requiresManualReview: json['requiresManualReview'] as bool? ?? false,
        reviewReason: json['reviewReason'] as String? ?? '',
        confidence: json['confidence'] as String? ?? 'HIGH',
      );
}

class DependencyInfo {
  final String targetComponent;
  final int totalDependencies;
  final int safeToRemoveCount;
  final int manualReviewCount;
  final List<DependencyItem> dependencies;

  const DependencyInfo({
    required this.targetComponent,
    required this.totalDependencies,
    required this.safeToRemoveCount,
    required this.manualReviewCount,
    required this.dependencies,
  });

  Map<String, dynamic> toJson() => {
        'targetComponent': targetComponent,
        'totalDependencies': totalDependencies,
        'safeToRemoveCount': safeToRemoveCount,
        'manualReviewCount': manualReviewCount,
        'dependencies': dependencies.map((e) => e.toJson()).toList(),
      };

  factory DependencyInfo.fromJson(Map<String, dynamic> json) => DependencyInfo(
        targetComponent: json['targetComponent'] as String? ?? '',
        totalDependencies: json['totalDependencies'] as int? ?? 0,
        safeToRemoveCount: json['safeToRemoveCount'] as int? ?? 0,
        manualReviewCount: json['manualReviewCount'] as int? ?? 0,
        dependencies: (json['dependencies'] as List? ?? [])
            .map((e) => DependencyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
