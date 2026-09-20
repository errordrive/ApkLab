import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/dialog_finding.dart';
import '../../data/services/dialog_scanner_service.dart';
import '../state/app_state.dart';
import '../widgets/relationship_graph_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/build_pipeline_dialog.dart';

class DialogScannerScreen extends StatefulWidget {
  const DialogScannerScreen({super.key});

  @override
  State<DialogScannerScreen> createState() => _DialogScannerScreenState();
}

class _DialogScannerScreenState extends State<DialogScannerScreen> {
  String _selectedFilter = 'All Dialogs';
  DialogFinding? _selectedFinding;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.currentProject;
    final findings = project.dialogFindings;
    final dialogReport = appState.dialogReport;

    final creditFindingsCount = findings.where((f) => f.isInjectedCreditDialog).length;

    final filteredFindings = findings.where((f) {
      if (_selectedFilter == 'All Dialogs') return true;
      if (_selectedFilter.startsWith('Credit Dialogs')) return f.isInjectedCreditDialog;
      if (_selectedFilter == 'Authentic App Only') return !f.isInjectedCreditDialog;
      return f.detectionLevel.startsWith(_selectedFilter);
    }).toList();

    return Column(
      children: [
        // Dialog Scanning & Batch Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.scanDialogs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comprehensive dialog scan complete! Detected custom "dialogbox" and standard dialog patterns.'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.radar, size: 15),
                    label: const Text('SCAN CUSTOM DIALOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showDialogReportModal(context, dialogReport),
                    icon: const Icon(Icons.assessment_outlined, size: 15),
                    label: const Text('DIALOG REPORT', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _killInjectedCreditOnly(context, appState),
                    icon: const Icon(Icons.remove_circle_outline, size: 15),
                    label: Text(
                      'KILL INJECTED CREDIT DIALOG ($creditFindingsCount)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _autoPatchAllDialogs(context, appState),
                    icon: const Icon(Icons.auto_fix_high, size: 15),
                    label: const Text('AUTO-PATCH ALL', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter bar: Credit vs Authentic + Detection Levels 1-5 (PRD Section 6)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.surface.withValues(alpha: 0.6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    'All Dialogs',
                    'Credit Dialogs ($creditFindingsCount)',
                    'Authentic App Only',
                    'Level 1',
                    'Level 2',
                    'Level 3',
                    'Level 4',
                    'Level 5',
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() {
                        _selectedFilter = filter;
                        _selectedFinding = null;
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Split or Full list/detail
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;

              if (isWide && _selectedFinding != null) {
                return Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: _buildFindingsList(filteredFindings),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _buildFindingDetail(_selectedFinding!),
                    ),
                  ],
                );
              }

              return _selectedFinding != null
                  ? _buildFindingDetail(_selectedFinding!, onBack: () => setState(() => _selectedFinding = null))
                  : _buildFindingsList(filteredFindings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFindingsList(List<DialogFinding> findings) {
    if (findings.isEmpty) {
      return const Center(
        child: Text('No dialog findings match the selected filter.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      itemCount: findings.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final f = findings[index];
        final isSelected = _selectedFinding?.id == f.id;
        final isCredit = f.isInjectedCreditDialog;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCredit ? AppColors.danger.withValues(alpha: 0.15) : AppColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isCredit ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border),
            ),
            child: Icon(
              isCredit ? Icons.warning_amber_rounded : Icons.chat_bubble_outline,
              size: 16,
              color: isCredit ? AppColors.danger : AppColors.accent,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  f.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCredit ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isCredit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'MODDER CREDIT',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.danger),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.className,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                isCredit
                    ? 'Target: Injected credit popup (${f.triggeredFrom}.${f.triggeringMethod})'
                    : 'Authentic: Original app dialogue (${f.triggeredFrom}.${f.triggeringMethod})',
                style: TextStyle(
                  fontSize: 11,
                  color: isCredit ? AppColors.danger.withValues(alpha: 0.8) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: StatusBadge.confidence(f.confidence.name),
          onTap: () => setState(() => _selectedFinding = f),
        );
      },
    );
  }

  Widget _buildFindingDetail(DialogFinding f, {VoidCallback? onBack}) {
    final appState = context.watch<AppState>();
    final isCredit = f.isInjectedCreditDialog;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onBack != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to list'),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Injected Credit vs Authentic Notice Card
        if (isCredit)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'INJECTED REVERSE-ENGINEER CREDIT DIALOGUE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _killSingleFinding(context, appState, f),
                      icon: const Icon(Icons.delete_forever, size: 14),
                      label: const Text('KILL THIS DIALOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  f.injectionReason ??
                      'This dialogue was added by a reverse engineer or modder to display author credits/channel. Neutralizing it removes the popup while leaving all genuine app features 100% intact.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                ),
                if (f.creditAuthor != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Author / Credit: ${f.creditAuthor}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Authentic Application Dialogue: Part of the original app logic (e.g. feedback, ratings, alerts). This dialogue is preserved by default.',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),

        // Finding Header Card (PRD Section 7 & 17)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    f.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${f.confidenceRating} (${f.confidenceScore} pts)',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.risk(f.riskLevel),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    f.classification,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    f.frameworkType,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Correlated Evidence Checklist (PRD Section 17)
        if (f.evidenceList.isNotEmpty) ...[
          _buildSectionHeader('Multi-Signal Correlated Evidence (${f.evidenceList.length} Signals)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: f.evidenceList.map((ev) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ev,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Object & Data Flow Correlation (PRD Section 3, 14 & 17)
        _buildSectionHeader('Object Identity & Register Data Flow'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFlowRow('Data Flow', f.objectRegisterFlow.isNotEmpty ? f.objectRegisterFlow : 'Correlated across method execution path'),
              const Divider(height: 16),
              _buildFlowRow('Creation Location', f.creationLocation.isNotEmpty ? f.creationLocation : 'Method entry'),
              const Divider(height: 16),
              _buildFlowRow('Content Location', f.contentLocation.isNotEmpty ? f.contentLocation : 'Default layout hierarchy'),
              const Divider(height: 16),
              _buildFlowRow('Show Location', f.showLocation.isNotEmpty ? f.showLocation : f.showCall),
              const Divider(height: 16),
              _buildFlowRow('Trigger Location', f.triggerLocation.isNotEmpty ? f.triggerLocation : f.triggerCondition),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dialog Relationship Graph (PRD Section 8)
        RelationshipGraphWidget(
          callChain: f.callChain,
          title: 'Dialog Relationship Graph & Call Chain',
        ),
        const SizedBox(height: 16),

        // Technical Finding Details (PRD Section 7 & 17)
        _buildSectionHeader('Technical Specifications'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildDetailRow('Class', f.className),
              _buildDetailRow('Method', f.triggeringMethod),
              if (f.methodSignature.isNotEmpty)
                _buildDetailRow('Method Signature', f.methodSignature),
              _buildDetailRow('DEX File', f.dexFile),
              _buildDetailRow('Smali Path', 'smali/${f.className.replaceAll(".", "/")}.smali'),
              _buildDetailRow('Parent Class', f.parentClass),
              _buildDetailRow('Framework', f.frameworkType),
              if (f.associatedUiComponents.isNotEmpty)
                _buildDetailRow('UI Components', f.associatedUiComponents.join(', ')),
              _buildDetailRow('Layout / Root', f.layout),
              _buildDetailRow('Related Strings', f.relatedStrings.map((s) => '"$s"').join(', ')),
              _buildDetailRow('Network Relationship', f.networkRelationship),
              _buildDetailRow('Related Resources', f.relatedResources.join('\n')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Actions: [Inspect Smali] + [Kill / Patch] + [JADX]
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showInspectSmaliModal(context, f),
              icon: const Icon(Icons.code, size: 16),
              label: const Text('Inspect Smali', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (isCredit)
              ElevatedButton.icon(
                onPressed: () => _killSingleFinding(context, appState, f),
                icon: const Icon(Icons.delete_forever, size: 16),
                label: const Text('Kill Injected Credit Dialogue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AppState>().setNavIndex(7); // Patch Center
              },
              icon: const Icon(Icons.build_outlined, size: 16),
              label: const Text('Open in Patch Center'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                context.read<AppState>().setNavIndex(4); // JADX
              },
              icon: const Icon(Icons.coffee_outlined, size: 16),
              label: const Text('Inspect Source (JADX)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlowRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.accent),
          ),
        ),
      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.textPrimary),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.textPrimary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInspectSmaliModal(BuildContext context, DialogFinding f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.code, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Smali: ${f.simpleName}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 650,
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class: ${f.className}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text(
                'Method: ${f.methodSignature.isNotEmpty ? f.methodSignature : f.triggeringMethod}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.codeBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      f.smaliCode.isNotEmpty ? f.smaliCode : '# Disassembled Smali bytecode for ${f.className}\n.method public show()V\n    # Dialog show invocation\n.end method',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                    ),
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
              Navigator.pop(ctx);
              context.read<AppState>().setNavIndex(3); // Smali Screen
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('OPEN IN SMALI EXPLORER'),
          ),
        ],
      ),
    );
  }

  void _showDialogReportModal(BuildContext context, DialogOnlyReport? report) {
    if (report == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.assessment_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Dialog-Only Technical Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIALOG PATTERN SCAN BREAKDOWN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      _buildReportStatRow('Total Dialog Findings', '${report.totalDialogs}', isHighlight: true),
                      _buildReportStatRow('Injected Modder Credit Dialogs (Target for Removal)', '${report.injectedCreditDialogsCount}', isHighlight: true),
                      _buildReportStatRow('Custom DialogBoxes ("dialogbox" patterns)', '${report.customDialogBoxesCount}'),
                      _buildReportStatRow('Standard Authentic Android Dialogs (Preserved)', '${report.standardDialogsCount}'),
                      _buildReportStatRow('Material / BottomSheet Dialogs', '${report.materialDialogsCount}'),
                      _buildReportStatRow('DialogFragments', '${report.fragmentDialogsCount}'),
                      _buildReportStatRow('Ad / Nag Notice Dialogs', '${report.adNoticeDialogsCount}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TECHNICAL SUMMARY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.codeBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    report.summaryText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().setNavIndex(7); // Patch Center
            },
            icon: const Icon(Icons.build_outlined, size: 16),
            label: const Text('OPEN IN PATCH CENTER'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isHighlight ? AppColors.primary : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _killInjectedCreditOnly(BuildContext context, AppState appState) async {
    if (!appState.hasOutputDirectory) {
      final picked = await appState.pickOutputDirectory();
      if (!picked || !appState.hasOutputDirectory) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an output folder to save the rebuilt APK.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;

    BuildPipelineDialog.show(
      context,
      title: 'Neutralizing Injected Credit Dialogue',
      runAction: (onProgress) => appState.killInjectedCreditDialogsOnly(onProgress: onProgress),
    );
  }

  void _killSingleFinding(BuildContext context, AppState appState, DialogFinding finding) async {
    if (!appState.hasOutputDirectory) {
      final picked = await appState.pickOutputDirectory();
      if (!picked || !appState.hasOutputDirectory) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an output folder to save the rebuilt APK.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;

    BuildPipelineDialog.show(
      context,
      title: 'Killing ${finding.title}',
      runAction: (onProgress) => appState.killSingleDialogFinding(finding, onProgress: onProgress),
    );
  }

  void _autoPatchAllDialogs(BuildContext context, AppState appState) async {
    if (!appState.hasOutputDirectory) {
      final picked = await appState.pickOutputDirectory();
      if (!picked || !appState.hasOutputDirectory) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an output folder to save the rebuilt APK.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;

    BuildPipelineDialog.show(
      context,
      title: 'Auto-patching All Dialogues',
      runAction: (onProgress) => appState.batchApplyDialogPatches(onProgress: onProgress),
    );
  }
}
