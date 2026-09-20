import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/jadx_source.dart';
import '../state/app_state.dart';
import '../widgets/code_viewer.dart';

class JadxScreen extends StatefulWidget {
  const JadxScreen({super.key});

  @override
  State<JadxScreen> createState() => _JadxScreenState();
}

class _JadxScreenState extends State<JadxScreen> {
  int _selectedSourceIndex = 0;
  String _searchQuery = '';
  int _activeDrawerTab = 0; // 0 = Methods, 1 = Callers, 2 = References, 3 = Usages

  @override
  Widget build(BuildContext context) {
    final project = context.watch<AppState>().currentProject;
    final sources = project.jadxSources;

    if (sources.isEmpty) {
      return const Center(
        child: Text('No JADX decompiled sources available for this project.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final currentSource = sources[_selectedSourceIndex.clamp(0, sources.length - 1)];

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
                      const Icon(Icons.coffee_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isNarrow ? constraints.maxWidth - 50 : 250),
                        child: DropdownButton<int>(
                          value: _selectedSourceIndex,
                          dropdownColor: AppColors.card,
                          isExpanded: isNarrow,
                          underline: const SizedBox.shrink(),
                          items: List.generate(sources.length, (idx) {
                            final s = sources[idx];
                            return DropdownMenuItem(
                              value: idx,
                              child: Text(
                                '${s.simpleName}.java',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSourceIndex = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNarrow)
                        IconButton(
                          icon: const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.accent),
                          tooltip: 'Cross Navigation',
                          onPressed: () => _showNavigationModal(context, currentSource),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AppState>().setNavIndex(3); // Switch to Smali
                        },
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: const Text('View in Smali', style: TextStyle(fontSize: 11)),
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

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search source code (methods, variables, strings)...',
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
        ),

        // Main content area: Code Viewer + Cross Navigation Panel
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return Row(
                children: [
                  // Code Viewer
                  Expanded(
                    flex: isWide ? 3 : 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 12, right: isWide ? 6 : 12),
                      child: CodeViewer(
                        code: currentSource.sourceCode,
                        language: 'java',
                        searchQuery: _searchQuery,
                      ),
                    ),
                  ),

                  // Side Panel: Cross Navigation (Methods, Callers, References, Usages)
                  if (isWide)
                    SizedBox(
                      width: 260,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 12, left: 6),
                        child: _buildNavigationPanel(currentSource),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNavigationModal(BuildContext context, JadxSource source) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SizedBox(
              height: 380,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildNavigationPanel(source),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationPanel(JadxSource source) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation Tabs
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Methods', source.methods.length),
                _buildTabButton(1, 'Callers', source.callers.length),
                _buildTabButton(2, 'Refs', source.references.length),
                _buildTabButton(3, 'Usages', source.usages.length),
              ],
            ),
          ),
          // Tab Items List
          Expanded(
            child: _buildPanelList(source),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, int count) {
    final isSelected = _activeDrawerTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeDrawerTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelList(JadxSource source) {
    List<String> items;
    IconData icon;

    switch (_activeDrawerTab) {
      case 1:
        items = source.callers;
        icon = Icons.call_made;
        break;
      case 2:
        items = source.references;
        icon = Icons.link;
        break;
      case 3:
        items = source.usages;
        icon = Icons.find_in_page;
        break;
      default:
        items = source.methods;
        icon = Icons.functions;
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('None found', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final item = items[idx];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: Icon(icon, size: 13, color: AppColors.accent),
          title: Text(
            item,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
          onTap: () {
            setState(() => _searchQuery = item.split('(').first.split('.').last);
          },
        );
      },
    );
  }
}
