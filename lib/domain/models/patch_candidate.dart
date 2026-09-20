class PatchHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String target;
  final String action;
  final String details;
  final bool isRevertible;

  const PatchHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.target,
    required this.action,
    required this.details,
    this.isRevertible = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'target': target,
        'action': action,
        'details': details,
        'isRevertible': isRevertible,
      };

  factory PatchHistoryEntry.fromJson(Map<String, dynamic> json) => PatchHistoryEntry(
        id: json['id'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        target: json['target'] as String? ?? '',
        action: json['action'] as String? ?? '',
        details: json['details'] as String? ?? '',
        isRevertible: json['isRevertible'] as bool? ?? true,
      );
}

class PatchCandidate {
  final String id;
  final String targetName;
  final String detectionConfidence; // HIGH, MEDIUM, LOW
  final String affectedClass;
  final int dependenciesCount;
  final int resourcesCount;
  final String risk; // LOW, MEDIUM, HIGH
  final String description;
  final String originalSmali;
  final String proposedSmali;
  final bool isApplied;

  const PatchCandidate({
    required this.id,
    required this.targetName,
    required this.detectionConfidence,
    required this.affectedClass,
    required this.dependenciesCount,
    required this.resourcesCount,
    required this.risk,
    required this.description,
    required this.originalSmali,
    required this.proposedSmali,
    this.isApplied = false,
  });

  PatchCandidate copyWith({
    bool? isApplied,
    String? proposedSmali,
  }) {
    return PatchCandidate(
      id: id,
      targetName: targetName,
      detectionConfidence: detectionConfidence,
      affectedClass: affectedClass,
      dependenciesCount: dependenciesCount,
      resourcesCount: resourcesCount,
      risk: risk,
      description: description,
      originalSmali: originalSmali,
      proposedSmali: proposedSmali ?? this.proposedSmali,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetName': targetName,
        'detectionConfidence': detectionConfidence,
        'affectedClass': affectedClass,
        'dependenciesCount': dependenciesCount,
        'resourcesCount': resourcesCount,
        'risk': risk,
        'description': description,
        'originalSmali': originalSmali,
        'proposedSmali': proposedSmali,
        'isApplied': isApplied,
      };

  factory PatchCandidate.fromJson(Map<String, dynamic> json) => PatchCandidate(
        id: json['id'] as String? ?? '',
        targetName: json['targetName'] as String? ?? '',
        detectionConfidence: json['detectionConfidence'] as String? ?? 'HIGH CONFIDENCE',
        affectedClass: json['affectedClass'] as String? ?? '',
        dependenciesCount: json['dependenciesCount'] as int? ?? 0,
        resourcesCount: json['resourcesCount'] as int? ?? 0,
        risk: json['risk'] as String? ?? 'MEDIUM',
        description: json['description'] as String? ?? '',
        originalSmali: json['originalSmali'] as String? ?? '',
        proposedSmali: json['proposedSmali'] as String? ?? '',
        isApplied: json['isApplied'] as bool? ?? false,
      );
}
