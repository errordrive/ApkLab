import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../state/app_state.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;

  const ResponsiveScaffold({
    super.key,
    required this.body,
  });

  static const List<IconData> navIcons = [
    Icons.inventory_2_outlined,       // Projects
    Icons.search,                     // Analyzer
    Icons.extension_outlined,         // Classes
    Icons.description_outlined,       // Smali
    Icons.coffee_outlined,            // JADX
    Icons.chat_bubble_outline,        // Dialog Scanner
    Icons.link,                       // References
    Icons.build_outlined,             // Patch Center
    Icons.bar_chart_outlined,         // Reports
    Icons.article_outlined,           // Logs
    Icons.settings_outlined,          // Settings
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'APkLab',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Project Selector Chip - protected against horizontal overflow
            Flexible(
              child: PopupMenuButton<String>(
                tooltip: 'Switch Project',
                onSelected: (id) => appState.selectProjectById(id),
                color: AppColors.card,
                itemBuilder: (context) {
                  return appState.projects.map((proj) {
                    return PopupMenuItem(
                      value: proj.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.android,
                            size: 16,
                            color: proj.id == appState.currentProject.id
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proj.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: proj.id == appState.currentProject.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: proj.id == appState.currentProject.id
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          appState.currentProject.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (appState.isAnalyzing) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${appState.currentProgressPercent}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () => appState.setNavIndex(10),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(context, appState),
      bottomNavigationBar: isWide ? null : Builder(
        builder: (scaffoldCtx) {
          int bottomIndex;
          if (appState.selectedNavIndex == 0) {
            bottomIndex = 0; // Dashboard
          } else if (appState.selectedNavIndex == 1) {
            bottomIndex = 1; // Analyzer
          } else if (appState.selectedNavIndex == 5) {
            bottomIndex = 2; // Dialogs
          } else if (appState.selectedNavIndex == 7) {
            bottomIndex = 3; // Patches
          } else {
            bottomIndex = 4; // Menu / other
          }

          return NavigationBar(
            height: 60,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            selectedIndex: bottomIndex,
            onDestinationSelected: (idx) {
              if (idx == 0) {
                appState.setNavIndex(0);
              } else if (idx == 1) {
                appState.setNavIndex(1);
              } else if (idx == 2) {
                appState.setNavIndex(5);
              } else if (idx == 3) {
                appState.setNavIndex(7);
              } else if (idx == 4) {
                Scaffold.of(scaffoldCtx).openDrawer();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined, size: 20),
                selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                label: 'Projects',
              ),
              NavigationDestination(
                icon: Icon(Icons.search, size: 20),
                selectedIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                label: 'Analyzer',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline, size: 20),
                selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary, size: 20),
                label: 'Dialogs',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined, size: 20),
                selectedIcon: Icon(Icons.build, color: AppColors.primary, size: 20),
                label: 'Patch',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu, size: 20),
                label: 'All Tools',
              ),
            ],
          );
        },
      ),
      body: Row(
        children: [
          if (isWide) _buildNavigationRail(context, appState),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState appState) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APK ANALYZER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mobile Reverse-Engineering IDE',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: AppConstants.navItems.length,
                itemBuilder: (context, index) {
                  final isSelected = appState.selectedNavIndex == index;
                  return ListTile(
                    leading: Icon(
                      navIcons[index],
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      AppConstants.navItems[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                    dense: true,
                    onTap: () {
                      appState.setNavIndex(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, AppState appState) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: AppConstants.navItems.length,
              itemBuilder: (context, index) {
                final isSelected = appState.selectedNavIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => appState.setNavIndex(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              navIcons[index],
                              size: 18,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppConstants.navItems[index],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appState.currentProject.isOriginalUntouched ? 'Original Untouched' : 'Modified',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
