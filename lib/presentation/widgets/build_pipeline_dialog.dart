import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/apk_build_pipeline.dart';
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
    'APK decoded',
    'DEX analyzed',
    'Smali analyzed',
    'Target identified',
    'Transformation applied',
    'APK rebuilt',
    'APK signed',
    'APK verified',
  ];

  String _currentStage = 'Initializing build pipeline...';
  String _currentMessage = 'Preparing workspace and decoding APK...';
  double _percent = 0.05;
  final Set<String> _completedStages = {};
  bool _isFinished = false;
  PatchResult? _result;

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
              ...allStages.map((stage) {
                final isDone = _completedStages.contains(stage);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 15,
                        color: isDone ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '✓ $stage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                          color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    final res = _result!;
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
                    res.success ? 'Build Successful' : 'Build Failed',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (res.success) ...[
                // Checklist of completed stages
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: allStages.map((stage) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              '✓ $stage',
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Output:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  res.outputApkName ?? 'patched-example.apk',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                const SizedBox(height: 8),
                const Text('Size:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '${(res.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (res.modifiedApkPath != null) ...[
                  const SizedBox(height: 8),
                  const Text('Saved Path:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                // Error view
                Text(
                  res.message,
                  style: const TextStyle(fontSize: 13, color: AppColors.danger),
                ),
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
                    height: 140,
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
}
