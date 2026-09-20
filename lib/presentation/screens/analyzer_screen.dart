import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../state/app_state.dart';
import '../widgets/status_badge.dart';

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<AppState>().currentProject;
    final apkInfo = project.apkInfo;
    final manifest = project.manifestInfo;

    return Column(
      children: [
        // Tab Bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 16), text: 'APK Info'),
              Tab(icon: Icon(Icons.apps_outlined, size: 16), text: 'Components'),
              Tab(icon: Icon(Icons.security_outlined, size: 16), text: 'Permissions'),
              Tab(icon: Icon(Icons.link, size: 16), text: 'Deep Links & Meta'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildApkInfoTab(apkInfo, project.sha256Checksum),
              _buildComponentsTab(manifest),
              _buildPermissionsTab(manifest.permissions),
              _buildMetaTab(manifest),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApkInfoTab(dynamic apkInfo, String sha256) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('APK Package & Version'),
        _buildInfoCard([
          _buildInfoRow('APK File Name', apkInfo.name),
          _buildInfoRow('Package Name', apkInfo.packageName),
          _buildInfoRow('Version Name', apkInfo.versionName),
          _buildInfoRow('Version Code', '${apkInfo.versionCode}'),
          _buildInfoRow('File Size', Formatters.formatBytes(apkInfo.sizeBytes)),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader('SDK & Platform Compatibility'),
        _buildInfoCard([
          _buildInfoRow('Min SDK', 'API ${apkInfo.minSdk}'),
          _buildInfoRow('Target SDK', 'API ${apkInfo.targetSdk}'),
          _buildInfoRow('Compile SDK', 'API ${apkInfo.compileSdk}'),
          _buildInfoRow('Architectures', apkInfo.supportedArchitectures.join(', ')),
          _buildInfoRow('DEX Count', '${apkInfo.dexCount} files'),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader('Security & Signing Scheme'),
        _buildInfoCard([
          _buildInfoRow('Signing Scheme', apkInfo.signingScheme),
          _buildInfoRow('Certificate', apkInfo.certificateInfo),
          _buildInfoRow('SHA-256 Checksum', sha256),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader('Native Libraries (.so)'),
        _buildInfoCard([
          _buildInfoRow(
            'Libraries (${apkInfo.nativeLibraries.length})',
            apkInfo.nativeLibraries.isEmpty ? 'None' : apkInfo.nativeLibraries.join('\n'),
          ),
        ]),
      ],
    );
  }

  Widget _buildComponentsTab(dynamic manifest) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildComponentSection('Activities (${manifest.activities.length})', manifest.activities, Icons.window),
        const SizedBox(height: 16),
        _buildComponentSection('Services (${manifest.services.length})', manifest.services, Icons.sync),
        const SizedBox(height: 16),
        _buildComponentSection('Broadcast Receivers (${manifest.receivers.length})', manifest.receivers, Icons.cell_tower),
        const SizedBox(height: 16),
        _buildComponentSection('Content Providers (${manifest.providers.length})', manifest.providers, Icons.dataset),
      ],
    );
  }

  Widget _buildComponentSection(String title, List<dynamic> components, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        if (components.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No components declared in manifest.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: components.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = components[index];
                return ListTile(
                  dense: true,
                  leading: Icon(icon, size: 16, color: AppColors.accent),
                  title: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
                  ),
                  subtitle: c.permission != null
                      ? Text(
                          'Permission: ${c.permission}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        )
                      : null,
                  trailing: c.isExported
                      ? const StatusBadge(label: 'EXPORTED', color: AppColors.warning)
                      : const StatusBadge(label: 'PRIVATE', color: AppColors.textSecondary),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionsTab(List<String> permissions) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Declared Permissions (${permissions.length})'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: permissions.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final perm = permissions[index];
              final isDangerous = perm.contains('WINDOW') || perm.contains('BOOT') || perm.contains('NOTIF');
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.shield,
                  size: 16,
                  color: isDangerous ? AppColors.warning : AppColors.info,
                ),
                title: Text(
                  perm,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
                trailing: StatusBadge(
                  label: isDangerous ? 'POTENTIAL RISK' : 'NORMAL',
                  color: isDangerous ? AppColors.warning : AppColors.success,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetaTab(dynamic manifest) {
    final deepLinks = manifest.deepLinks as List<String>;
    final metadata = manifest.metadata as Map<String, String>;
    final appConfig = manifest.appConfig as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Deep Links (${deepLinks.length})'),
        _buildInfoCard(deepLinks.map((link) => _buildInfoRow('URI Schema', link)).toList()),
        const SizedBox(height: 20),

        _buildSectionHeader('Manifest Metadata'),
        _buildInfoCard(metadata.entries.map((e) => _buildInfoRow(e.key, e.value)).toList()),
        const SizedBox(height: 20),

        _buildSectionHeader('Application Configuration'),
        _buildInfoCard(appConfig.entries.map((e) => _buildInfoRow(e.key, e.value.toString())).toList()),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
