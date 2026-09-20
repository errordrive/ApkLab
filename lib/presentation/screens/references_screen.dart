import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/dependency_info.dart';
import '../state/app_state.dart';
import '../widgets/status_badge.dart';

class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.watch<AppState>().currentProject;
    final dependencies = project.dependencies;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.link, color: AppColors.accent, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cross-Reference & Dependency Verification (PRD Section 10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Analyzes class references, reflection calls, JNI native bindings, and resources before removal. Flags uncertain targets as "REQUIRES MANUAL REVIEW" to prevent silent regressions.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (dependencies.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No dependency targets analyzed yet.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...dependencies.map((dep) => _buildDependencyTargetCard(context, dep)),
      ],
    );
  }

  Widget _buildDependencyTargetCard(BuildContext context, DependencyInfo dep) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET COMPONENT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dep.targetComponent,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.textPrimary),
                    ),
                  ],
                ),
                if (dep.manualReviewCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text(
                          'REQUIRES MANUAL REVIEW (${dep.manualReviewCount})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                      ],
                    ),
                  )
                else
                  const StatusBadge(label: 'SAFE TO REMOVE', color: AppColors.success),
              ],
            ),
          ),

          // Dependencies List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dep.dependencies.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final item = dep.dependencies[idx];

              return Container(
                color: item.requiresManualReview ? AppColors.danger.withValues(alpha: 0.05) : Colors.transparent,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.requiresManualReview ? Icons.report_problem : Icons.arrow_right_alt,
                      size: 16,
                      color: item.requiresManualReview ? AppColors.danger : AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.requiresManualReview ? AppColors.danger : AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.source,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '&rarr; ${item.target}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary),
                          ),
                          if (item.requiresManualReview) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                item.reviewReason,
                                style: const TextStyle(fontSize: 11, color: AppColors.danger),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge.confidence(item.confidence),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
