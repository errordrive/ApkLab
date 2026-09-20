import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/dex_info.dart';
import '../state/app_state.dart';
import '../widgets/status_badge.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  int _selectedDexIndex = 0;
  String _searchQuery = '';
  DexClass? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final project = context.watch<AppState>().currentProject;
    final dexList = project.dexList;

    if (dexList.isEmpty) {
      return const Center(child: Text('No DEX data available.'));
    }

    final currentDex = dexList[_selectedDexIndex.clamp(0, dexList.length - 1)];
    final filteredClasses = currentDex.classes.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.packageName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // DEX Selector & Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_copy_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedDexIndex,
                    dropdownColor: AppColors.card,
                    underline: const SizedBox.shrink(),
                    items: List.generate(dexList.length, (idx) {
                      final d = dexList[idx];
                      return DropdownMenuItem(
                        value: idx,
                        child: Text(
                          '${d.dexName} (${Formatters.formatNumber(d.classesCount)})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDexIndex = val;
                          _selectedClass = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              Text(
                '${Formatters.formatNumber(currentDex.methodsCount)} Methods • ${Formatters.formatNumber(currentDex.stringsCount)} Strings',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search classes, packages, or identifiers...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        // Two-pane or list/detail
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (isWide && _selectedClass != null) {
                return Row(
                  children: [
                    // Class list
                    SizedBox(
                      width: 320,
                      child: _buildClassList(filteredClasses),
                    ),
                    const VerticalDivider(width: 1),
                    // Class detail
                    Expanded(
                      child: _buildClassDetail(_selectedClass!),
                    ),
                  ],
                );
              }

              return _selectedClass != null
                  ? _buildClassDetail(_selectedClass!, onBack: () => setState(() => _selectedClass = null))
                  : _buildClassList(filteredClasses);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassList(List<DexClass> classes) {
    if (classes.isEmpty) {
      return const Center(
        child: Text('No classes match filter.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      itemCount: classes.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = classes[index];
        final isSelected = _selectedClass?.name == c.name;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
          leading: Icon(
            c.isDialogRelated ? Icons.chat_bubble_outline : Icons.class_outlined,
            size: 16,
            color: c.isDialogRelated ? AppColors.warning : AppColors.info,
          ),
          title: Text(
            c.simpleName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
          ),
          subtitle: Text(
            c.packageName,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.isObfuscated)
                const StatusBadge(label: 'OBFUSCATED', color: AppColors.danger),
              if (c.isDialogRelated) ...[
                const SizedBox(width: 4),
                const StatusBadge(label: 'DIALOG', color: AppColors.warning),
              ],
            ],
          ),
          onTap: () => setState(() => _selectedClass = c),
        );
      },
    );
  }

  Widget _buildClassDetail(DexClass c, {VoidCallback? onBack}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onBack != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to class list'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Class Header
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
              Row(
                children: [
                  const Icon(Icons.class_, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Extends: ${c.superClass}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
              if (c.interfaces.isNotEmpty)
                Text('Implements: ${c.interfaces.join(', ')}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Methods list
        _buildSectionTitle('Methods (${c.methods.length})'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: c.methods.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final m = c.methods[idx];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.functions, size: 14, color: AppColors.accent),
                title: Text(
                  '${m.modifiers.join(' ')} ${m.returnType} ${m.name}(${m.parameterTypes.join(', ')})',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Fields list
        _buildSectionTitle('Fields (${c.fields.length})'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: c.fields.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final f = c.fields[idx];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.label_outline, size: 14, color: AppColors.info),
                title: Text(
                  '${f.modifiers.join(' ')} ${f.type} ${f.name}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
      ),
    );
  }
}
