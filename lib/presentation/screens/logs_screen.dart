import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/analysis_log.dart';
import '../state/app_state.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAnalyzing = appState.isAnalyzing;
    final progress = appState.currentProgressPercent;
    final logs = appState.liveLogs;

    // Determine current active stage index
    int activeStageIndex = 0;
    for (int i = 0; i < AppConstants.analysisStages.length; i++) {
      final stage = AppConstants.analysisStages[i];
      if (logs.any((l) => l.stage.toLowerCase() == stage.toLowerCase())) {
        activeStageIndex = i;
      }
    }
    if (!isAnalyzing && progress == 100) {
      activeStageIndex = AppConstants.analysisStages.length; // all complete
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Real-time Pipeline Progress Box (PRD Section 11)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'APK ANALYSIS PIPELINE',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primary),
                    ),
                    const Spacer(),
                    if (isAnalyzing) ...[
                      OutlinedButton.icon(
                        onPressed: () => appState.cancelAnalysis(),
                        icon: const Icon(Icons.cancel, size: 14, color: AppColors.danger),
                        label: const Text('CANCEL', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Overall Progress Bar & Percentage (PRD Section 11)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100.0,
                          backgroundColor: AppColors.card,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$progress%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isAnalyzing ? 'Current Stage: ${appState.currentStage}' : 'Status: Pipeline Complete',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // 11 Pipeline Stage Checklist (PRD Section 11)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(AppConstants.analysisStages.length, (idx) {
                    final stageName = AppConstants.analysisStages[idx];
                    final isComplete = idx < activeStageIndex;
                    final isCurrent = idx == activeStageIndex && isAnalyzing;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isComplete)
                          const Icon(Icons.check, size: 14, color: AppColors.success)
                        else if (isCurrent)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          const Icon(Icons.radio_button_unchecked, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          stageName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isComplete
                                ? AppColors.textPrimary
                                : (isCurrent ? AppColors.accent : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Execution Log Stream (PRD Section 11)
          Row(
            children: [
              const Icon(Icons.terminal, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text(
                'Execution Logs',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${logs.length} entries',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.codeBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, idx) {
                final log = logs[idx];
                Color levelColor;
                IconData levelIcon;

                switch (log.level) {
                  case LogLevel.success:
                    levelColor = AppColors.success;
                    levelIcon = Icons.check_circle_outline;
                    break;
                  case LogLevel.warning:
                    levelColor = AppColors.warning;
                    levelIcon = Icons.warning_amber_rounded;
                    break;
                  case LogLevel.error:
                    levelColor = AppColors.danger;
                    levelIcon = Icons.error_outline;
                    break;
                  default:
                    levelColor = AppColors.info;
                    levelIcon = Icons.info_outline;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.formatCompactTime(log.timestamp),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.codeLineNumber),
                      ),
                      const SizedBox(width: 12),
                      Icon(levelIcon, size: 14, color: levelColor),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          log.stage.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: levelColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.message,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
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
    );
  }
}
