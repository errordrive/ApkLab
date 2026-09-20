import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sandboxIsolation = true;
  bool _rejectZipSlip = true;
  bool _preserveOriginal = true;
  bool _mandatoryBackup = true;
  bool _flagUncertainManualReview = true;
  String _selectedSigningScheme = 'v2 + v3 (Recommended)';
  late TextEditingController _folderController;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController();
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  void _cleanJunk(BuildContext context, AppState appState) async {
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
                Text('Scanning & clearing junk files...'),
                SizedBox(height: 4),
                Text('Deleting temporary caches and orphaned extraction data...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    final freedMb = await appState.cleanJunkStorage();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage cleaned! Freed $freedMb MB of temporary junk and cached data.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (_folderController.text != appState.outputDirectoryDisplayName) {
      _folderController.text = appState.outputDirectoryDisplayName;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Security & Stability Requirements (PRD Section 18)
        _buildSectionHeader('Security & Stability Guardrails (PRD Section 18)'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Never Execute Imported Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Strict static-analysis execution. Untrusted code is never dynamically invoked.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _sandboxIsolation,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _sandboxIsolation = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Enforce Zip-Slip Protection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Rejects archive paths containing "../" or absolute prefixes to protect file system.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _rejectZipSlip,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _rejectZipSlip = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Preserve Original APK & SHA-256', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Original APK is kept read-only. Modified builds are written to separate output directories.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _preserveOriginal,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _preserveOriginal = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Mandatory Backup Before Patching', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Automatically snapshot files before applying Smali modifications.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _mandatoryBackup,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _mandatoryBackup = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Flag Uncertain Dependencies', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Display "REQUIRES MANUAL REVIEW" for reflection and native JNI targets.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                value: _flagUncertainManualReview,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _flagUncertainManualReview = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Custom Output Folder & Rebuild Destination
        _buildSectionHeader('Custom Rebuild Output Folder'),
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
              const Text('Rebuilt APK Destination Path', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'After patching, rebuilt and re-signed APKs are saved to this folder via Storage Access Framework (SAF).',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _folderController,
                      readOnly: true,
                      onTap: () async {
                        await appState.pickOutputDirectory();
                        _folderController.text = appState.outputDirectoryDisplayName;
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.folder_open, size: 18, color: AppColors.accent),
                        hintText: 'Tap to choose folder via SAF',
                        helperText: appState.hasOutputDirectory ? 'Folder access granted via SAF' : 'No folder chosen',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.pickOutputDirectory();
                      _folderController.text = appState.outputDirectoryDisplayName;
                    },
                    icon: const Icon(Icons.folder_open, size: 14),
                    label: const Text('CHOOSE FOLDER'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Storage & Junk Cleaner
        _buildSectionHeader('Storage & Cache Management'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.cleaning_services_outlined, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Up Local Storage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                      'Clear temporary decompiled files, intermediate build junk, and cached logs.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _cleanJunk(context, appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('CLEAN JUNK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Signing & Rebuild Settings (PRD Section 9)
        _buildSectionHeader('APK Rebuild & Signing Engine'),
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
              const Text('Signing Scheme Version', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedSigningScheme,
                dropdownColor: AppColors.card,
                isExpanded: true,
                items: ['v1 (JAR Signature)', 'v2 (APK Signature Scheme v2)', 'v2 + v3 (Recommended)', 'v4 (Streaming)']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSigningScheme = val);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Modifying and re-signing an APK changes its cryptographic certificate. Modified APKs cannot update an existing installation of the original package.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // About ApkLab
        _buildSectionHeader('About'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppConstants.appName} v${AppConstants.appVersion}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              SizedBox(height: 4),
              Text(
                AppConstants.appTagline,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),
              Text(
                'Built for security researchers, reverse engineers, and developers conducting static inspection and controlled bytecode modifications on owned or authorized Android packages.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
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
}
