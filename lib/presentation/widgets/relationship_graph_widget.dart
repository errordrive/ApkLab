import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RelationshipGraphWidget extends StatelessWidget {
  final List<String> callChain;
  final String title;

  const RelationshipGraphWidget({
    super.key,
    required this.callChain,
    this.title = 'Dialog Relationship Graph',
  });

  IconData _getStepIcon(int index, int total, String step) {
    if (index == 0) return Icons.launch;
    if (index == total - 1) return Icons.visibility;
    if (step.contains('(')) return Icons.functions;
    if (step.contains('Dialog') || step.contains('Warning') || step.contains('Notice')) return Icons.chat_bubble_outline;
    return Icons.widgets_outlined;
  }

  Color _getStepColor(int index, int total) {
    if (index == 0) return AppColors.info;
    if (index == total - 1) return AppColors.primary;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    if (callChain.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flowchart nodes with connecting arrows
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;

              if (isWide) {
                // Horizontal Flowchart
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(callChain.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                        );
                      }
                      final stepIndex = i ~/ 2;
                      return _buildNode(stepIndex, callChain.length, callChain[stepIndex]);
                    }),
                  ),
                );
              } else {
                // Vertical Flowchart
                return Column(
                  children: List.generate(callChain.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Icon(Icons.arrow_downward, size: 16, color: AppColors.textSecondary),
                      );
                    }
                    final stepIndex = i ~/ 2;
                    return _buildNode(stepIndex, callChain.length, callChain[stepIndex]);
                  }),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNode(int index, int total, String text) {
    final color = _getStepColor(index, total);
    final icon = _getStepIcon(index, total, text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
