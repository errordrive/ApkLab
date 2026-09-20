class ApkInfo {
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int sizeBytes;
  final int minSdk;
  final int targetSdk;
  final int compileSdk;
  final List<String> supportedArchitectures;
  final int dexCount;
  final List<String> nativeLibraries;
  final String certificateInfo;
  final String signingScheme;
  final List<String> permissions;
  final String sha256Checksum;

  const ApkInfo({
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.sizeBytes,
    required this.minSdk,
    required this.targetSdk,
    required this.compileSdk,
    required this.supportedArchitectures,
    required this.dexCount,
    required this.nativeLibraries,
    required this.certificateInfo,
    required this.signingScheme,
    required this.permissions,
    required this.sha256Checksum,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'packageName': packageName,
        'versionName': versionName,
        'versionCode': versionCode,
        'sizeBytes': sizeBytes,
        'minSdk': minSdk,
        'targetSdk': targetSdk,
        'compileSdk': compileSdk,
        'supportedArchitectures': supportedArchitectures,
        'dexCount': dexCount,
        'nativeLibraries': nativeLibraries,
        'certificateInfo': certificateInfo,
        'signingScheme': signingScheme,
        'permissions': permissions,
        'sha256Checksum': sha256Checksum,
      };

  factory ApkInfo.fromJson(Map<String, dynamic> json) => ApkInfo(
        name: json['name'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        versionName: json['versionName'] as String? ?? '',
        versionCode: json['versionCode'] as int? ?? 0,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        minSdk: json['minSdk'] as int? ?? 21,
        targetSdk: json['targetSdk'] as int? ?? 34,
        compileSdk: json['compileSdk'] as int? ?? 34,
        supportedArchitectures: List<String>.from(json['supportedArchitectures'] ?? []),
        dexCount: json['dexCount'] as int? ?? 1,
        nativeLibraries: List<String>.from(json['nativeLibraries'] ?? []),
        certificateInfo: json['certificateInfo'] as String? ?? '',
        signingScheme: json['signingScheme'] as String? ?? 'v2 + v3',
        permissions: List<String>.from(json['permissions'] ?? []),
        sha256Checksum: json['sha256Checksum'] as String? ?? '',
      );
}
