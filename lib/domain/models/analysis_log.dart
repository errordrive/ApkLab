enum LogLevel { info, success, warning, error }

class AnalysisLog {
  final DateTime timestamp;
  final String stage;
  final String message;
  final LogLevel level;
  final int progressPercent;
  final String? currentDex;
  final int? processedFiles;

  const AnalysisLog({
    required this.timestamp,
    required this.stage,
    required this.message,
    this.level = LogLevel.info,
    this.progressPercent = 0,
    this.currentDex,
    this.processedFiles,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'stage': stage,
        'message': message,
        'level': level.name,
        'progressPercent': progressPercent,
        'currentDex': currentDex,
        'processedFiles': processedFiles,
      };

  factory AnalysisLog.fromJson(Map<String, dynamic> json) => AnalysisLog(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        stage: json['stage'] as String? ?? '',
        message: json['message'] as String? ?? '',
        level: LogLevel.values.firstWhere(
          (e) => e.name == (json['level'] as String? ?? 'info').toLowerCase(),
          orElse: () => LogLevel.info,
        ),
        progressPercent: json['progressPercent'] as int? ?? 0,
        currentDex: json['currentDex'] as String?,
        processedFiles: json['processedFiles'] as int?,
      );
}
