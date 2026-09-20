import 'apk_info.dart';
import 'manifest_info.dart';
import 'dex_info.dart';
import 'jadx_source.dart';
import 'smali_info.dart';
import 'dialog_finding.dart';
import 'dependency_info.dart';
import 'patch_candidate.dart';
import 'analysis_report.dart';
import 'analysis_log.dart';

class ApkProject {
  final String id;
  final String name;
  final String apkPath;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isOriginalUntouched;
  final String sha256Checksum;
  final ApkInfo apkInfo;
  final ManifestInfo manifestInfo;
  final List<DexInfo> dexList;
  final List<JadxSource> jadxSources;
  final List<SmaliInfo> smaliFiles;
  final List<DialogFinding> dialogFindings;
  final List<DependencyInfo> dependencies;
  final List<PatchCandidate> patchCandidates;
  final AnalysisReport report;
  final List<AnalysisLog> logs;
  final List<PatchHistoryEntry> patchHistory;
  final List<String> modifiedApkPaths;

  const ApkProject({
    required this.id,
    required this.name,
    required this.apkPath,
    required this.createdAt,
    required this.lastModified,
    this.isOriginalUntouched = true,
    required this.sha256Checksum,
    required this.apkInfo,
    required this.manifestInfo,
    required this.dexList,
    required this.jadxSources,
    required this.smaliFiles,
    required this.dialogFindings,
    required this.dependencies,
    required this.patchCandidates,
    required this.report,
    required this.logs,
    this.patchHistory = const [],
    this.modifiedApkPaths = const [],
  });

  ApkProject copyWith({
    String? name,
    DateTime? lastModified,
    bool? isOriginalUntouched,
    List<PatchCandidate>? patchCandidates,
    List<SmaliInfo>? smaliFiles,
    List<DialogFinding>? dialogFindings,
    List<PatchHistoryEntry>? patchHistory,
    List<String>? modifiedApkPaths,
    List<AnalysisLog>? logs,
  }) {
    return ApkProject(
      id: id,
      name: name ?? this.name,
      apkPath: apkPath,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
      isOriginalUntouched: isOriginalUntouched ?? this.isOriginalUntouched,
      sha256Checksum: sha256Checksum,
      apkInfo: apkInfo,
      manifestInfo: manifestInfo,
      dexList: dexList,
      jadxSources: jadxSources,
      smaliFiles: smaliFiles ?? this.smaliFiles,
      dialogFindings: dialogFindings ?? this.dialogFindings,
      dependencies: dependencies,
      patchCandidates: patchCandidates ?? this.patchCandidates,
      report: report,
      logs: logs ?? this.logs,
      patchHistory: patchHistory ?? this.patchHistory,
      modifiedApkPaths: modifiedApkPaths ?? this.modifiedApkPaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'apkPath': apkPath,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'isOriginalUntouched': isOriginalUntouched,
        'sha256Checksum': sha256Checksum,
        'apkInfo': apkInfo.toJson(),
        'manifestInfo': manifestInfo.toJson(),
        'dexList': dexList.map((e) => e.toJson()).toList(),
        'jadxSources': jadxSources.map((e) => e.toJson()).toList(),
        'smaliFiles': smaliFiles.map((e) => e.toJson()).toList(),
        'dialogFindings': dialogFindings.map((e) => e.toJson()).toList(),
        'dependencies': dependencies.map((e) => e.toJson()).toList(),
        'patchCandidates': patchCandidates.map((e) => e.toJson()).toList(),
        'report': report.toJson(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'patchHistory': patchHistory.map((e) => e.toJson()).toList(),
        'modifiedApkPaths': modifiedApkPaths,
      };

  factory ApkProject.fromJson(Map<String, dynamic> json) => ApkProject(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        apkPath: json['apkPath'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
        isOriginalUntouched: json['isOriginalUntouched'] as bool? ?? true,
        sha256Checksum: json['sha256Checksum'] as String? ?? '',
        apkInfo: ApkInfo.fromJson(json['apkInfo'] as Map<String, dynamic>? ?? {}),
        manifestInfo: ManifestInfo.fromJson(json['manifestInfo'] as Map<String, dynamic>? ?? {}),
        dexList: (json['dexList'] as List? ?? [])
            .map((e) => DexInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        jadxSources: (json['jadxSources'] as List? ?? [])
            .map((e) => JadxSource.fromJson(e as Map<String, dynamic>))
            .toList(),
        smaliFiles: (json['smaliFiles'] as List? ?? [])
            .map((e) => SmaliInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        dialogFindings: (json['dialogFindings'] as List? ?? [])
            .map((e) => DialogFinding.fromJson(e as Map<String, dynamic>))
            .toList(),
        dependencies: (json['dependencies'] as List? ?? [])
            .map((e) => DependencyInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        patchCandidates: (json['patchCandidates'] as List? ?? [])
            .map((e) => PatchCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        report: AnalysisReport.fromJson(json['report'] as Map<String, dynamic>? ?? {}),
        logs: (json['logs'] as List? ?? [])
            .map((e) => AnalysisLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        patchHistory: (json['patchHistory'] as List? ?? [])
            .map((e) => PatchHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        modifiedApkPaths: List<String>.from(json['modifiedApkPaths'] ?? []),
      );
}
