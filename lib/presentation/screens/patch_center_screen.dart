import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/patch_candidate.dart';
import '../state/app_state.dart';
import '../widgets/diff_viewer.dart';
import '../widgets/status_badge.dart';

class PatchCenterScreen extends StatefulWidget {
  const PatchCenterScreen({super.key});

  @override
  State<PatchCenterScreen> createState() => _PatchCenterScreenState();
}

class _PatchCenterScreenState extends State<PatchCenterScreen> {
  PatchCandidate? _previewCandidate;

  void _applyPatch(BuildContext context, PatchCandidate candidate) async {
    final appState = context.read<AppState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Creating backup & applying Smali patch...'),
                SizedBox(height: 4),
                Text('Rebuilding APK & signing with v2/v3 scheme...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    final result = await appState.applyPatch(candidate);

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
      setState(() {
        _previewCandidate = null;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _revertPatch(BuildContext context, PatchCandidate candidate) async {
    final appState = context.read<AppState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await appState.revertPatch(candidate);
    setState(() {
      _previewCandidate = null;
    });

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _rebuildAndExportApk(BuildContext context, AppState appState) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.success),
                SizedBox(height: 16),
                Text('Rebuilding patched APK...'),
                SizedBox(height: 4),
                Text('Signing with v2/v3 scheme & saving to storage...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await appState.rebuildAndExportPatchedApk();

    if (context.mounted) {
      Navigator.pop(context); // close loading
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(result.success ? Icons.check_circle : Icons.error, color: result.success ? AppColors.success : AppColors.danger, size: 22),
              const SizedBox(width: 8),
              Text(result.success ? 'Patched APK Saved!' : 'Rebuild Result', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message, style: const TextStyle(fontSize: 13)),
              if (result.modifiedApkPath != null) ...[
                const SizedBox(height: 12),
                const Text('Saved Local Path:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    result.modifiedApkPath!,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmClearHistory(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text('Delete Patch History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all patch history and audit logs? This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.clearPatchHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Patch history & audit log deleted.'),
                  backgroundColor: AppColors.info,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('DELETE HISTORY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.currentProject;
    final candidates = project.patchCandidates;
    final history = project.patchHistory;

    return Column(
      children: [
        // Patch Preview Modal/View if active
        if (_previewCandidate != null) ...[
          Container(
            height: 320,
            padding: const EdgeInsets.all(12),
            color: AppColors.background,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.preview, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'PREVIEW PATCH: ${_previewCandidate!.targetName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _previewCandidate = null),
                    ),
                  ],
                ),
                Expanded(
                  child: DiffViewer(
                    originalCode: _previewCandidate!.originalSmali,
                    proposedCode: _previewCandidate!.proposedSmali,
                    title: 'Smali Bytecode Diff: ${_previewCandidate!.affectedClass}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // Custom Output Folder Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_special_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REBUILD DESTINATION FOLDER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        appState.customOutputDirectory,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditFolderDialog(context, appState),
                    icon: const Icon(Icons.edit, size: 13),
                    label: const Text('CHANGE FOLDER', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _rebuildAndExportApk(context, appState),
                    icon: const Icon(Icons.save_alt, size: 14),
                    label: const Text('SAVE / REBUILD APK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main List of Candidates and Patch History
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('Available Patch Targets (${candidates.length})'),
              ...candidates.map((candidate) => _buildCandidateCard(context, candidate)),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Patch History & Audit Log (${history.length})'),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClearHistory(context, appState),
                      icon: const Icon(Icons.delete_sweep, size: 15, color: AppColors.danger),
                      label: const Text('DELETE HISTORY', style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              _buildHistoryCard(history),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditFolderDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.customOutputDirectory);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.folder, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Custom Rebuild Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the local folder where rebuilt and re-signed APKs will be saved:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Output Directory Path',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open, color: AppColors.accent),
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
              final newPath = controller.text.trim();
              if (newPath.isNotEmpty) {
                appState.setOutputDirectory(newPath);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE FOLDER'),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, PatchCandidate candidate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: candidate.isApplied ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (PRD Section 22)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      candidate.targetName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge.confidence(candidate.detectionConfidence),
                    StatusBadge.risk(candidate.risk),
                    if (candidate.isApplied)
                      const StatusBadge(label: 'APPLIED', color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldRow('Affected Class', candidate.affectedClass, isCode: true),
                const SizedBox(height: 8),
                _buildFieldRow('Dependencies', '${candidate.dependenciesCount} references verified'),
                const SizedBox(height: 8),
                _buildFieldRow('Resources', '${candidate.resourcesCount} related layouts/drawables'),
                const SizedBox(height: 8),
                _buildFieldRow('Description', candidate.description),
                const SizedBox(height: 16),

                // Actions: [ INSPECT ] [ PREVIEW PATCH ] [ APPLY PATCH ] (PRD Section 22)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AppState>().setNavIndex(3); // Go to Smali
                      },
                      icon: const Icon(Icons.search, size: 14),
                      label: const Text('INSPECT', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _previewCandidate = candidate),
                      icon: const Icon(Icons.preview, size: 14),
                      label: const Text('PREVIEW PATCH', style: TextStyle(fontSize: 11)),
                    ),
                    if (!candidate.isApplied)
                      ElevatedButton.icon(
                        onPressed: () => _applyPatch(context, candidate),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('APPLY PATCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _revertPatch(context, candidate),
                        icon: const Icon(Icons.undo, size: 14, color: AppColors.warning),
                        label: const Text('REVERT PATCH', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(List<PatchHistoryEntry> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No modifications applied to this project yet.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final h = history[idx];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history_toggle_off, size: 18, color: AppColors.accent),
            title: Text(
              '${h.action}: ${h.target}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.details, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(Formatters.formatDateTime(h.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {bool isCode = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: isCode ? 'monospace' : null,
              color: isCode ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
      ),
    );
  }
}
