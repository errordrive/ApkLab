import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/code_viewer.dart';
import '../widgets/diff_viewer.dart';
import '../widgets/status_badge.dart';

class SmaliScreen extends StatefulWidget {
  const SmaliScreen({super.key});

  @override
  State<SmaliScreen> createState() => _SmaliScreenState();
}

class _SmaliScreenState extends State<SmaliScreen> {
  int _selectedSmaliIndex = 0;
  String _searchQuery = '';
  bool _showDiff = false;

  @override
  Widget build(BuildContext context) {
    final project = context.watch<AppState>().currentProject;
    final smaliFiles = project.smaliFiles;

    if (smaliFiles.isEmpty) {
      return const Center(
        child: Text('No Smali files disassembled for this project.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final currentSmali = smaliFiles[_selectedSmaliIndex.clamp(0, smaliFiles.length - 1)];

    return Column(
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isNarrow ? constraints.maxWidth - 40 : 250),
                        child: DropdownButton<int>(
                          value: _selectedSmaliIndex,
                          dropdownColor: AppColors.card,
                          isExpanded: isNarrow,
                          underline: const SizedBox.shrink(),
                          items: List.generate(smaliFiles.length, (idx) {
                            final s = smaliFiles[idx];
                            return DropdownMenuItem(
                              value: idx,
                              child: Text(
                                s.simpleName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSmaliIndex = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentSmali.isPatched)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: StatusBadge(label: 'PATCHED', color: AppColors.success),
                        ),
                      if (currentSmali.patchedCode != null)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _showDiff = !_showDiff),
                          icon: Icon(_showDiff ? Icons.code : Icons.compare_arrows, size: 14),
                          label: Text(_showDiff ? 'View Code' : 'Compare Patch', style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),

        // Search & Opcode Quick Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search Smali opcodes (e.g. invoke-virtual, show, new-instance)...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'show()',
                    'invoke-virtual',
                    'new-instance',
                    'const/4',
                    'return-void',
                    'goto',
                    'if-eqz',
                  ].map((opcode) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _searchQuery = opcode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            opcode,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.accent),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Smali Code Viewer or Diff Viewer
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _showDiff && currentSmali.patchedCode != null
                ? DiffViewer(
                    originalCode: currentSmali.smaliCode,
                    proposedCode: currentSmali.patchedCode!,
                    title: 'Smali Patch Comparison: ${currentSmali.simpleName}',
                  )
                : CodeViewer(
                    code: currentSmali.isPatched ? currentSmali.patchedCode! : currentSmali.smaliCode,
                    language: 'smali',
                    searchQuery: _searchQuery,
                    highlightedLines: currentSmali.modifiedLines,
                  ),
          ),
        ),
      ],
    );
  }
}
