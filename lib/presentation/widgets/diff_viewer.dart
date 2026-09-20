import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DiffViewer extends StatelessWidget {
  final String originalCode;
  final String proposedCode;
  final String title;

  const DiffViewer({
    super.key,
    required this.originalCode,
    required this.proposedCode,
    this.title = 'Smali Diff Comparison',
  });

  @override
  Widget build(BuildContext context) {
    final origLines = originalCode.split('\n');
    final propLines = proposedCode.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Orig (-)',
                  style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Patch (+)',
                  style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Diff views: Side-by-side or stacked
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    children: [
                      // Original side
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: AppColors.border)),
                          ),
                          child: _buildCodeColumn('BEFORE (ORIGINAL)', origLines, isOriginal: true),
                        ),
                      ),
                      // Patched side
                      Expanded(
                        child: _buildCodeColumn('AFTER (PATCHED)', propLines, isOriginal: false),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: _buildCodeColumn('BEFORE (ORIGINAL)', origLines, isOriginal: true),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _buildCodeColumn('AFTER (PATCHED)', propLines, isOriginal: false),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeColumn(String header, List<String> lines, {required bool isOriginal}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: isOriginal ? AppColors.danger.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOriginal ? AppColors.danger : AppColors.success,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(lines.length, (index) {
                    final line = lines[index];
                    final isModified = line.contains('PATCHED') ||
                        line.contains('return-void') ||
                        line.contains('invoke-virtual') ||
                        line.contains('const/4');

                    return Container(
                      color: isModified
                          ? (isOriginal
                              ? AppColors.danger.withValues(alpha: 0.18)
                              : AppColors.success.withValues(alpha: 0.18))
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.codeLineNumber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            line.isEmpty ? ' ' : line,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isModified
                                  ? (isOriginal ? AppColors.danger : AppColors.success)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
