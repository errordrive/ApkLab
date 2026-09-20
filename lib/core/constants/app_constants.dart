class AppConstants {
  static const String appName = 'ApkLab';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Mobile Reverse-Engineering & Controlled Patching Workstation';

  // Navigation Items matching PRD Section 19
  static const List<String> navItems = [
    'Projects',
    'Analyzer',
    'Classes',
    'Smali',
    'JADX',
    'Dialog Scanner',
    'References',
    'Patch Center',
    'Reports',
    'Logs',
    'Settings',
  ];

  // Analysis Stages matching PRD Section 11
  static const List<String> analysisStages = [
    'APK Validation',
    'APK Extraction',
    'Manifest Analysis',
    'DEX Discovery',
    'DEX Indexing',
    'JADX Analysis',
    'Smali Analysis',
    'Dialog Detection',
    'Resource Analysis',
    'Dependency Analysis',
    'Report Generation',
  ];

  // Dialog Detection Levels matching PRD Section 6
  static const String level1Name = 'Level 1 — Known Android APIs';
  static const String level2Name = 'Level 2 — Class Structure Detection';
  static const String level3Name = 'Level 3 — Smali Pattern Detection';
  static const String level4Name = 'Level 4 — Call Graph Analysis';
  static const String level5Name = 'Level 5 — Resource Correlation';
}
