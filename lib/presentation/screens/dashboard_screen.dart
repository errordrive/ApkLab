import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../state/app_state.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _pickAndAnalyzeApk(BuildContext context) async {
    final appState = context.read<AppState>();
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.any,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (bytes.isNotEmpty) {
          appState.startAnalysis(
            fileName: pickedFile.name,
            bytes: bytes,
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected file is empty.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final controller = TextEditingController(text: 'TargetApp_v1.2.apk');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Analyze New APK', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an APK from your device storage or simulate an APK target:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _pickAndAnalyzeApk(context);
              },
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('CHOOSE FROM STORAGE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR SIMULATE', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Target APK Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.android, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Static-analysis-first: Code is never executed. Analysis runs in sandboxed isolates.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final bytes = [
                  0x50, 0x4B, 0x03, 0x04,
                  ...utf8.encode('AndroidManifest.xml\x00classes.dex\x00resources.arsc')
                ];
                appState.startAnalysis(
                  fileName: name.endsWith('.apk') ? name : '$name.apk',
                  bytes: Uint8List.fromList(bytes),
                );
              }
            },
            child: const Text('RUN ANALYSIS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.currentProject;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner & Analyze APK button (PRD Section 20)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.security, size: 38, color: AppColors.primary),
                const SizedBox(height: 10),
                const Text(
                  'APK Static-Analysis Workstation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Decompile, scan dialog patterns, inspect call graphs & patch bytecode safely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndAnalyzeApk(context),
                      icon: const Icon(Icons.file_open_outlined, size: 16),
                      label: const Text(
                        'IMPORT FROM STORAGE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showImportDialog(context),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text(
                        'SIMULATE TARGET',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Project Quick Stats
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Active Project Stats',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${project.name})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => appState.setNavIndex(8),
                icon: const Icon(Icons.receipt_long, size: 14),
                label: const Text('View Full Report', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 1.4 : 1.25,
                children: [
                  MetricCard(
                    label: 'Classes',
                    value: Formatters.formatNumber(project.report.totalClasses),
                    icon: Icons.code,
                    color: AppColors.info,
                    subtitle: '${project.report.totalDexFiles} DEX files',
                  ),
                  MetricCard(
                    label: 'Methods',
                    value: Formatters.formatNumber(project.report.totalMethods),
                    icon: Icons.functions,
                    color: AppColors.accent,
                    subtitle: 'Cross-referenced',
                  ),
                  MetricCard(
                    label: 'Dialogs',
                    value: '${project.report.dialogsDetected}',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.warning,
                    subtitle: '${project.report.customDialogs} custom dialogs',
                  ),
                  MetricCard(
                    label: 'Patch Targets',
                    value: '${project.report.patchCandidates}',
                    icon: Icons.build_outlined,
                    color: AppColors.success,
                    subtitle: 'Ready to inspect',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent Projects Section (PRD Section 20)
          Row(
            children: [
              const Icon(Icons.history, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text(
                'Recent Projects',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${appState.projects.length} loaded',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appState.projects.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final proj = appState.projects[index];
              final isCurrent = proj.id == project.id;

              return Container(
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.surface : AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary.withValues(alpha: 0.6) : AppColors.border,
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.android,
                      size: 20,
                      color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          proj.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${proj.report.dialogsDetected} Dialogs • ${proj.report.totalDexFiles} DEX • ${Formatters.formatBytes(proj.apkInfo.sizeBytes)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.receipt_long, size: 18, color: AppColors.accent),
                        tooltip: 'View Report',
                        onPressed: () {
                          appState.selectProject(proj);
                          appState.setNavIndex(8);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
                        tooltip: 'Open Analyzer',
                        onPressed: () {
                          appState.selectProject(proj);
                          appState.setNavIndex(1);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
