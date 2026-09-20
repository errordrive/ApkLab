class AnalysisReport {
  final String id;
  final String apkName;
  final String packageName;
  final String version;
  final int sizeBytes;
  final String status;
  final int totalClasses;
  final int totalMethods;
  final int totalDexFiles;
  final int totalResources;
  final int totalNativeLibs;
  final int dialogsDetected;
  final int customDialogs;
  final int potentialIssues;
  final int patchCandidates;
  final String executiveSummary;
  final DateTime createdAt;

  const AnalysisReport({
    required this.id,
    required this.apkName,
    required this.packageName,
    required this.version,
    required this.sizeBytes,
    required this.status,
    required this.totalClasses,
    required this.totalMethods,
    required this.totalDexFiles,
    required this.totalResources,
    required this.totalNativeLibs,
    required this.dialogsDetected,
    required this.customDialogs,
    required this.potentialIssues,
    required this.patchCandidates,
    required this.executiveSummary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'apk': {
          'name': apkName,
          'package': packageName,
          'version': version,
          'sizeBytes': sizeBytes,
        },
        'analysis': {
          'status': status,
          'classes': totalClasses,
          'methods': totalMethods,
          'dexFiles': totalDexFiles,
          'resources': totalResources,
          'nativeLibraries': totalNativeLibs,
          'dialogsDetected': dialogsDetected,
          'customDialogs': customDialogs,
          'potentialIssues': potentialIssues,
          'patchCandidates': patchCandidates,
        },
        'executiveSummary': executiveSummary,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    final apk = json['apk'] as Map<String, dynamic>? ?? {};
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return AnalysisReport(
      id: json['id'] as String? ?? '',
      apkName: apk['name'] as String? ?? json['apkName'] as String? ?? '',
      packageName: apk['package'] as String? ?? json['packageName'] as String? ?? '',
      version: apk['version'] as String? ?? json['version'] as String? ?? '',
      sizeBytes: apk['sizeBytes'] as int? ?? json['sizeBytes'] as int? ?? 0,
      status: analysis['status'] as String? ?? json['status'] as String? ?? 'COMPLETED',
      totalClasses: analysis['classes'] as int? ?? json['totalClasses'] as int? ?? 0,
      totalMethods: analysis['methods'] as int? ?? json['totalMethods'] as int? ?? 0,
      totalDexFiles: analysis['dexFiles'] as int? ?? json['totalDexFiles'] as int? ?? 1,
      totalResources: analysis['resources'] as int? ?? json['totalResources'] as int? ?? 0,
      totalNativeLibs: analysis['nativeLibraries'] as int? ?? json['totalNativeLibs'] as int? ?? 0,
      dialogsDetected: analysis['dialogsDetected'] as int? ?? json['dialogsDetected'] as int? ?? 0,
      customDialogs: analysis['customDialogs'] as int? ?? json['customDialogs'] as int? ?? 0,
      potentialIssues: analysis['potentialIssues'] as int? ?? json['potentialIssues'] as int? ?? 0,
      patchCandidates: analysis['patchCandidates'] as int? ?? json['patchCandidates'] as int? ?? 0,
      executiveSummary: json['executiveSummary'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
