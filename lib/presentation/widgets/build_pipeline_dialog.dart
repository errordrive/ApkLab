import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/apk_build_pipeline.dart';
import '../../data/services/apk_validator.dart';
import '../../data/services/patch_service.dart';

class BuildPipelineDialog extends StatefulWidget {
  final String title;
  final Future<PatchResult> Function(void Function(BuildProgress)) runAction;

  const BuildPipelineDialog({
    super.key,
    required this.title,
    required this.runAction,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<PatchResult> Function(void Function(BuildProgress)) runAction,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BuildPipelineDialog(
        title: title,
        runAction: runAction,
      ),
    );
  }

  @override
  State<BuildPipelineDialog> createState() => _BuildPipelineDialogState();
}

class _BuildPipelineDialogState extends State<BuildPipelineDialog> {
  static const List<String> allStages = [
    'Prepare private workspace',
    'Decode APK',
    'Analyze DEX/Smali',
    'Apply patch',
    'Rebuild APK',
    'Structural validation',
    'DEX validation',
    'Zipalign',
    'Sign APK',
    'Signature verification',
    'Export through SAF',
    'Verify exported APK',
  ];

  String _currentStage = 'Initializing build pipeline...';
  String _currentMessage = 'Preparing workspace and decoding APK...';
  double _percent = 0.05;
  final Set<String> _completedStages = {};
  bool _isFinished = false;
  PatchResult? _result;
  ValidationReport? _liveReport;
  String? _liveWorkspace;

  @override
  void initState() {
    super.initState();
    _startBuild();
  }

  void _startBuild() async {
    try {
      final res = await widget.runAction((progress) {
        if (mounted) {
          setState(() {
            _currentStage = progress.stage;
            _currentMessage = progress.message;
            _percent = progress.percent;
            _completedStages.addAll(progress.completedStages);
            if (progress.validationReport != null) {
              _liveReport = progress.validationReport;
            }
            if (progress.workspacePath != null) {
              _liveWorkspace = progress.workspacePath;
            }
          });
        }
      });

      if (mounted) {
        setState(() {
          _isFinished = true;
          _result = res;
          if (res.success) {
            _completedStages.addAll(allStages);
          }
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _result = PatchResult(
            success: false,
            message: 'Build process crashed: $e',
            error: e.toString(),
            stackTrace: st.toString(),
            workspacePath: _liveWorkspace,
            validationReport: _liveReport,
            updatedProject: (context.findAncestorStateOfType() as dynamic)?.currentProject,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFinished) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${(_percent * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _percent.clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              Text(
                _currentStage,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                _currentMessage,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allStages.length,
                  itemBuilder: (context, idx) {
                    final stage = allStages[idx];
                    final isDone = _completedStages.contains(stage);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: isDone ? AppColors.success : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stage,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                                color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final res = _result!;
    final report = res.validationReport ?? _liveReport;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    res.success ? Icons.check_circle : Icons.error,
                    color: res.success ? AppColors.success : AppColors.danger,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    res.success ? 'BUILD SUCCESSFUL' : 'BUILD FAILED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: res.success ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (res.success) ...[
                // BUILD VALIDATION REPORT (PRD Section 14)
                if (report != null) ...[
                  _buildComparisonTable(report),
                  const SizedBox(height: 14),
                  _buildStatusChecklist(report, res),
                  const SizedBox(height: 14),
                ],

                // Output info
                const Text('Output APK:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  res.outputApkName ?? 'patched-app.apk',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Size: ${(res.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    if (res.signerInfo != null)
                      Text(
                        'Signer: ${res.signerInfo}',
                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                if (res.modifiedApkPath != null) ...[
                  const SizedBox(height: 8),
                  const Text('Saved Location (SAF):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SelectableText(
                      res.modifiedApkPath!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.success),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Three action buttons: [Open] [Share] [Install]
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: res.modifiedApkPath != null
                            ? () => ApkBuildPipeline.openFile(res.modifiedApkPath!)
                            : null,
                        icon: const Icon(Icons.folder_open, size: 14),
                        label: const Text('Open', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: res.modifiedApkPath != null
                            ? () => ApkBuildPipeline.shareApk(res.modifiedApkPath!)
                            : null,
                        icon: const Icon(Icons.share, size: 14),
                        label: const Text('Share', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: res.modifiedApkPath != null
                            ? () => ApkBuildPipeline.installApk(res.modifiedApkPath!)
                            : null,
                        icon: const Icon(Icons.android, size: 14),
                        label: const Text('Install', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // BUILD FAILURE HANDLING (PRD Section 16 & 17)
                Text(
                  res.message,
                  style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
                if (res.workspacePath != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRESERVED DEBUG WORKSPACE:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          res.workspacePath!,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Inspect build.log, validation-report.json, unsigned.apk, aligned.apk in this folder.',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
                if (res.error != null) ...[
                  const SizedBox(height: 12),
                  const Text('Error Details:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: SelectableText(
                      res.error!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.danger),
                    ),
                  ),
                ],
                if (res.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  const Text('Stack Trace:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        res.stackTrace!,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable(ValidationReport report) {
    final orig = report.originalInventory;
    final rebu = report.rebuiltInventory;

    final rows = [
      {'Component': 'DEX', 'Original': '${orig.dexCount}', 'Rebuilt': '${rebu.dexCount}', 'Match': orig.dexCount == rebu.dexCount},
      {'Component': 'Native libs', 'Original': '${orig.nativeLibCount}', 'Rebuilt': '${rebu.nativeLibCount}', 'Match': orig.nativeLibCount == rebu.nativeLibCount},
      {'Component': 'Assets', 'Original': '${orig.assetCount}', 'Rebuilt': '${rebu.assetCount}', 'Match': orig.assetCount == rebu.assetCount},
      {'Component': 'Resources', 'Original': '${orig.resourceCount}', 'Rebuilt': '${rebu.resourceCount}', 'Match': (orig.resourceCount - rebu.resourceCount).abs() < 5},
      {'Component': 'Activities', 'Original': '${orig.activities.length}', 'Rebuilt': '${rebu.activities.length}', 'Match': orig.activities.length == rebu.activities.length},
      {'Component': 'Services', 'Original': '${orig.services.length}', 'Rebuilt': '${rebu.services.length}', 'Match': orig.services.length == rebu.services.length},
      {'Component': 'Receivers', 'Original': '${orig.receivers.length}', 'Rebuilt': '${rebu.receivers.length}', 'Match': orig.receivers.length == rebu.receivers.length},
      {'Component': 'Providers', 'Original': '${orig.providers.length}', 'Rebuilt': '${rebu.providers.length}', 'Match': orig.providers.length == rebu.providers.length},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORIGINAL VS REBUILT INVENTORY COMPARISON',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(height: 6),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.0),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Component', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Original', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Rebuilt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Diff', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                ],
              ),
              ...rows.map((r) {
                final match = r['Match'] as bool;
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r['Component'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r['Original'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(r['Rebuilt'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        match ? 'PASS' : 'DIFF',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: match ? AppColors.success : AppColors.warning),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChecklist(ValidationReport report, PatchResult res) {
    final checks = [
      {'title': 'DEX Integrity', 'pass': report.dexValid},
      {'title': 'Resources (arsc/res)', 'pass': report.resourcesValid},
      {'title': 'Manifest Structure', 'pass': report.manifestValid},
      {'title': 'Native Libraries (lib/)', 'pass': report.nativeLibsValid},
      {'title': 'Assets Preserved', 'pass': report.assetsValid},
      {'title': 'Zip Alignment (4/4096)', 'pass': report.alignmentValid},
      {'title': 'Cryptographic Signature', 'pass': report.signatureValid},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS CHECKLIST',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(height: 6),
          ...checks.map((c) {
            final pass = c['pass'] as bool;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(pass ? Icons.check : Icons.close, size: 13, color: pass ? AppColors.success : AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    c['title'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    pass ? 'PASS' : 'FAIL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pass ? AppColors.success : AppColors.danger),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 12),
          Text(
            report.runtimeStatusMessage,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: report.runtimeValid ? AppColors.textSecondary : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
