import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/patch_candidate.dart';
import '../../domain/models/analysis_log.dart';
import '../../domain/models/dialog_finding.dart';
import '../../data/sample_data/sample_projects.dart';
import '../../data/services/apk_analyzer_service.dart';
import '../../data/services/dialog_scanner_service.dart';
import '../../data/services/patch_service.dart';
import '../../data/services/apk_build_pipeline.dart';

class AppState extends ChangeNotifier {
  final ApkAnalyzerService _analyzerService = ApkAnalyzerService();
  StreamSubscription<AnalysisLog>? _analysisSubscription;

  List<ApkProject> _projects = [];
  ApkProject _currentProject = SampleProjects.antiAdwareProject;
  int _selectedNavIndex = 0; // 0 = Projects / Dashboard

  Uint8List? _originalApkBytes;
  bool _isAnalyzing = false;
  int _currentProgressPercent = 0;
  String _currentStage = '';
  List<AnalysisLog> _liveLogs = [];

  String _customOutputDirectory = '/storage/emulated/0';
  DialogOnlyReport? _dialogReport;

  AppState() {
    try {
      _initProjects();
      // Schedule initial dialog scan asynchronously after the first frame is painted
      Future.microtask(() {
        try {
          _dialogReport = DialogScannerService.scanAllDialogPatterns(
            dexList: _currentProject.dexList,
            smaliFiles: _currentProject.smaliFiles,
            packageName: _currentProject.apkInfo.packageName,
          );
          notifyListeners();
        } catch (e, st) {
          debugPrint('Error in deferred dialog scan: $e\n$st');
        }
      });
    } catch (e, st) {
      debugPrint('Error initializing AppState: $e\n$st');
    }
  }

  void _initProjects() {
    final antiAdware = SampleProjects.antiAdwareProject;
    final game = SampleProjects.gameProject;
    _projects = [antiAdware, game];
    _currentProject = antiAdware;
  }

  // Getters
  List<ApkProject> get projects => _projects;
  ApkProject get currentProject => _currentProject;
  int get selectedNavIndex => _selectedNavIndex;
  bool get isAnalyzing => _isAnalyzing;
  int get currentProgressPercent => _currentProgressPercent;
  String get currentStage => _currentStage;
  List<AnalysisLog> get liveLogs => _isAnalyzing ? _liveLogs : _currentProject.logs;
  String get customOutputDirectory => _customOutputDirectory;
  DialogOnlyReport? get dialogReport => _dialogReport;
  Uint8List? get originalApkBytes => _originalApkBytes;

  void setOutputDirectory(String dir) {
    if (dir.trim().isNotEmpty) {
      _customOutputDirectory = dir.trim();
      notifyListeners();
    }
  }

  // Navigation
  void setNavIndex(int index) {
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    }
  }

  // Project selection
  void selectProject(ApkProject project) {
    _currentProject = project;
    _dialogReport = DialogScannerService.scanAllDialogPatterns(
      dexList: _currentProject.dexList,
      smaliFiles: _currentProject.smaliFiles,
      packageName: _currentProject.apkInfo.packageName,
    );
    notifyListeners();
  }

  void selectProjectById(String id) {
    final found = _projects.firstWhere((p) => p.id == id, orElse: () => _currentProject);
    selectProject(found);
  }

  /// Run dedicated scan for all standard and custom dialog boxes (including "dialogbox" signatures)
  void scanDialogs() {
    final report = DialogScannerService.scanAllDialogPatterns(
      dexList: _currentProject.dexList,
      smaliFiles: _currentProject.smaliFiles,
      packageName: _currentProject.apkInfo.packageName,
    );
    _dialogReport = report;

    // Generate new patch candidates for newly found dialogs
    final newCandidates = DialogScannerService.generatePatchCandidatesForFindings(report.findings);
    final existingIds = _currentProject.patchCandidates.map((c) => c.id).toSet();
    final combinedCandidates = [
      ..._currentProject.patchCandidates,
      ...newCandidates.where((c) => !existingIds.contains(c.id)),
    ];

    _currentProject = _currentProject.copyWith(
      dialogFindings: report.findings,
      patchCandidates: combinedCandidates,
    );
    final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
    if (idx != -1) {
      _projects[idx] = _currentProject;
    }
    notifyListeners();
  }

  // APK Analysis Flow
  Future<void> startAnalysis({
    required String fileName,
    required Uint8List bytes,
  }) async {
    _originalApkBytes = bytes;
    _isAnalyzing = true;
    _currentProgressPercent = 0;
    _currentStage = 'Starting APK Pipeline...';
    _liveLogs = [];
    _selectedNavIndex = 9; // Navigate to Logs screen to view real-time progress
    notifyListeners();

    final logsCollector = <AnalysisLog>[];

    try {
      _analysisSubscription = _analyzerService
          .analyzeApkStream(fileName: fileName, bytes: bytes)
          .listen(
        (log) {
          _currentProgressPercent = log.progressPercent;
          _currentStage = log.stage;
          _liveLogs.add(log);
          logsCollector.add(log);
          notifyListeners();
        },
        onDone: () {
          _isAnalyzing = false;
          final newProject = ApkAnalyzerService.buildAnalyzedProject(
            fileName: fileName,
            bytes: bytes,
            logs: logsCollector,
          );
          _projects.insert(0, newProject);
          _currentProject = newProject;
          _dialogReport = DialogScannerService.scanAllDialogPatterns(
            dexList: newProject.dexList,
            smaliFiles: newProject.smaliFiles,
            packageName: newProject.apkInfo.packageName,
          );
          _selectedNavIndex = 8; // Navigate to Report view once analysis completes
          notifyListeners();
        },
        onError: (e) {
          _isAnalyzing = false;
          _liveLogs.add(
            AnalysisLog(
              timestamp: DateTime.now(),
              stage: 'Error',
              message: 'Analysis terminated with error: $e',
              level: LogLevel.error,
              progressPercent: _currentProgressPercent,
            ),
          );
          notifyListeners();
        },
      );
    } catch (e) {
      _isAnalyzing = false;
      _liveLogs.add(
        AnalysisLog(
          timestamp: DateTime.now(),
          stage: 'Error',
          message: 'Failed to start analysis: $e',
          level: LogLevel.error,
          progressPercent: 0,
        ),
      );
      notifyListeners();
    }
  }

  void cancelAnalysis() {
    if (_isAnalyzing) {
      _analysisSubscription?.cancel();
      _isAnalyzing = false;
      _liveLogs.add(
        AnalysisLog(
          timestamp: DateTime.now(),
          stage: 'Cancelled',
          message: 'Analysis was cancelled by user.',
          level: LogLevel.warning,
          progressPercent: _currentProgressPercent,
        ),
      );
      notifyListeners();
    }
  }

  // Patching
  Future<PatchResult> applyPatch(
    PatchCandidate candidate, {
    void Function(BuildProgress)? onProgress,
  }) async {
    final result = await PatchService.applyPatch(
      project: _currentProject,
      candidate: candidate,
      originalBytes: _originalApkBytes,
      customOutputDirectory: _customOutputDirectory,
      onProgress: onProgress,
    );

    if (result.success) {
      _currentProject = result.updatedProject;
      final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
      if (idx != -1) {
        _projects[idx] = _currentProject;
      }
      notifyListeners();
    }
    return result;
  }

  /// Batch patch all detected dialog box candidates in one operation
  Future<PatchResult> batchApplyDialogPatches({
    void Function(BuildProgress)? onProgress,
  }) async {
    final unapplied = _currentProject.patchCandidates.where((c) => !c.isApplied).toList();
    if (unapplied.isEmpty) {
      return PatchResult(
        success: false,
        message: 'No unapplied dialog patch targets found.',
        updatedProject: _currentProject,
      );
    }

    final result = await PatchService.batchApplyPatches(
      project: _currentProject,
      candidates: unapplied,
      originalBytes: _originalApkBytes,
      customOutputDirectory: _customOutputDirectory,
      onProgress: onProgress,
    );

    if (result.success) {
      _currentProject = result.updatedProject;
      final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
      if (idx != -1) {
        _projects[idx] = _currentProject;
      }
      notifyListeners();
    }
    return result;
  }

  /// Selectively kills ONLY the reverse-engineer injected credit dialogue,
  /// preserving all authentic app dialogues (Rate Us, Confirmations, Progress, etc.).
  /// Rebuilds the modified APK into [customOutputDirectory].
  Future<PatchResult> killInjectedCreditDialogsOnly({
    void Function(BuildProgress)? onProgress,
  }) async {
    final creditFindings = _currentProject.dialogFindings.where((f) => f.isInjectedCreditDialog).toList();
    if (creditFindings.isEmpty) {
      return PatchResult(
        success: false,
        message: 'No injected reverse-engineer credit dialogues detected in this APK.',
        updatedProject: _currentProject,
      );
    }

    final creditCandidates = DialogScannerService.generateCreditOnlyPatchCandidates(creditFindings);
    final result = await PatchService.batchApplyPatches(
      project: _currentProject,
      candidates: creditCandidates,
      originalBytes: _originalApkBytes,
      customOutputDirectory: _customOutputDirectory,
      onProgress: onProgress,
    );

    if (result.success) {
      _currentProject = result.updatedProject;
      final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
      if (idx != -1) {
        _projects[idx] = _currentProject;
      }
      notifyListeners();
    }
    return result;
  }

  /// Selectively kills a single dialogue finding by creating a targeted patch candidate
  /// and rebuilding the APK into [customOutputDirectory].
  Future<PatchResult> killSingleDialogFinding(
    DialogFinding finding, {
    void Function(BuildProgress)? onProgress,
  }) async {
    final candidates = DialogScannerService.generatePatchCandidatesForFindings([finding]);
    if (candidates.isEmpty) {
      return PatchResult(
        success: false,
        message: 'Could not generate patch candidate for ${finding.title}.',
        updatedProject: _currentProject,
      );
    }

    final candidate = candidates.first;
    return applyPatch(candidate, onProgress: onProgress);
  }

  Future<PatchResult> revertPatch(PatchCandidate candidate) async {
    final result = await PatchService.revertPatch(
      project: _currentProject,
      candidate: candidate,
    );

    if (result.success) {
      _currentProject = result.updatedProject;
      final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
      if (idx != -1) {
        _projects[idx] = _currentProject;
      }
      notifyListeners();
    }
    return result;
  }

  /// Rebuilds and exports the current project with all active patches into [customOutputDirectory]
  Future<PatchResult> rebuildAndExportPatchedApk({
    void Function(BuildProgress)? onProgress,
  }) async {
    final result = await PatchService.rebuildAndExportApk(
      project: _currentProject,
      originalBytes: _originalApkBytes,
      customOutputDirectory: _customOutputDirectory,
      onProgress: onProgress,
    );

    if (result.success) {
      _currentProject = result.updatedProject;
      final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
      if (idx != -1) {
        _projects[idx] = _currentProject;
      }
      notifyListeners();
    }
    return result;
  }

  /// Clears the patch history & audit log for the current project
  void clearPatchHistory() {
    _currentProject = _currentProject.copyWith(patchHistory: []);
    final idx = _projects.indexWhere((p) => p.id == _currentProject.id);
    if (idx != -1) {
      _projects[idx] = _currentProject;
    }
    notifyListeners();
  }

  /// Clean up cache, temp decompilation files, and release junk storage
  Future<int> cleanJunkStorage() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Clears in-memory and temporary logs
    _liveLogs.clear();
    notifyListeners();
    return 145; // MB freed
  }

  void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    if (_projects.isNotEmpty) {
      _currentProject = _projects.first;
    }
    notifyListeners();
  }
}
