import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/export_service.dart';
import '../state/app_state.dart';
import '../widgets/metric_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showExportModal(BuildContext context, String title, String content, String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.file_download, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Export $format Report', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Generated $format content ready for export:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                height: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format report copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('COPY TO CLIPBOARD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.currentProject;
    final report = project.report;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Report Banner & Status (PRD Section 15)
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 20, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'ANALYSIS COMPLETE',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Text(
                      'Generated ${Formatters.formatDateTime(report.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'APK: ${project.apkInfo.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Package: ${project.apkInfo.packageName} (Version: ${project.apkInfo.versionName})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Big Summary Cards (PRD Section 15)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isWide ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 2.0 : 3.0,
                children: [
                  MetricCard(
                    label: 'Classes',
                    value: Formatters.formatNumber(report.totalClasses),
                    icon: Icons.code,
                    color: AppColors.info,
                  ),
                  MetricCard(
                    label: 'Methods',
                    value: Formatters.formatNumber(report.totalMethods),
                    icon: Icons.functions,
                    color: AppColors.accent,
                  ),
                  MetricCard(
                    label: 'Dialogs',
                    value: '${report.dialogsDetected}',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Secondary Stats Box (PRD Section 15)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSubStat('Custom Dialogs', '${report.customDialogs}')),
                _buildDivider(),
                Expanded(child: _buildSubStat('Potential Issues', '${report.potentialIssues}')),
                _buildDivider(),
                Expanded(child: _buildSubStat('Patch Candidates', '${report.patchCandidates}')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: [ EXPORT PDF ] [ EXPORT HTML ] [ EXPORT JSON ] [ OPEN ANALYZER ] (PRD Section 15)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final html = ExportService.exportToHtml(project);
                  _showExportModal(context, 'HTML Report', html, 'HTML');
                },
                icon: const Icon(Icons.code, size: 16),
                label: const Text('EXPORT HTML'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final txt = ExportService.exportToTxt(project);
                  _showExportModal(context, 'PDF / Text Report', txt, 'PDF / Printable');
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('EXPORT PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final jsonStr = ExportService.exportToJson(project);
                  _showExportModal(context, 'JSON Report', jsonStr, 'JSON');
                },
                icon: const Icon(Icons.data_object, size: 16),
                label: const Text('EXPORT JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  appState.setNavIndex(1); // Open Analyzer
                },
                icon: const Icon(Icons.search, size: 16),
                label: const Text('OPEN ANALYZER'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Executive Summary Section (PRD Section 13)
          _buildSectionHeader('Executive Summary'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              report.executiveSummary,
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),

          // Detected Dialog Findings Overview
          _buildSectionHeader('Detected Dialog Findings (${project.dialogFindings.length})'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: project.dialogFindings.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final d = project.dialogFindings[idx];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.accent),
                  title: Text(
                    '${d.title}: ${d.className}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Triggered by ${d.triggeredFrom}.${d.triggeringMethod} &bull; Call: ${d.showCall}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Text(
                    d.confidence.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: d.confidence.name == 'high' ? AppColors.success : AppColors.warning,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
      ),
    );
  }
}
