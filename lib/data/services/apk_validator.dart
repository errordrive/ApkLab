import 'dart:convert';
import 'package:archive/archive.dart';
import 'dex_parser.dart';
import 'dialog_candidate_detector.dart';

/// Inventory of all critical components in an APK
class ApkInventory {
  final int dexCount;
  final List<String> dexNames;
  final int totalClassesCount;
  final int resourceCount;
  final bool hasResourcesArsc;
  final bool isResourcesArscStored;
  final int assetCount;
  final int nativeLibCount;
  final Map<String, List<String>> nativeLibsByAbi;
  final bool hasManifest;
  final List<String> activities;
  final List<String> services;
  final List<String> receivers;
  final List<String> providers;
  final List<String> permissions;
  final String? launcherActivity;
  final String? packageName;

  const ApkInventory({
    required this.dexCount,
    required this.dexNames,
    required this.totalClassesCount,
    required this.resourceCount,
    required this.hasResourcesArsc,
    required this.isResourcesArscStored,
    required this.assetCount,
    required this.nativeLibCount,
    required this.nativeLibsByAbi,
    required this.hasManifest,
    required this.activities,
    required this.services,
    required this.receivers,
    required this.providers,
    required this.permissions,
    this.launcherActivity,
    this.packageName,
  });

  Map<String, dynamic> toJson() => {
    'dexCount': dexCount,
    'dexNames': dexNames,
    'totalClassesCount': totalClassesCount,
    'resourceCount': resourceCount,
    'hasResourcesArsc': hasResourcesArsc,
    'isResourcesArscStored': isResourcesArscStored,
    'assetCount': assetCount,
    'nativeLibCount': nativeLibCount,
    'nativeLibsByAbi': nativeLibsByAbi,
    'hasManifest': hasManifest,
    'activitiesCount': activities.length,
    'servicesCount': services.length,
    'receiversCount': receivers.length,
    'providersCount': providers.length,
    'permissionsCount': permissions.length,
    'launcherActivity': launcherActivity,
    'packageName': packageName,
  };

  /// Extracts the inventory from an APK's raw bytes
  static ApkInventory fromArchive(Archive archive) {
    int dexCount = 0;
    final dexNames = <String>[];
    int resourceCount = 0;
    bool hasArsc = false;
    bool arscStored = false;
    int assetCount = 0;
    int nativeCount = 0;
    final libsByAbi = <String, List<String>>{
      'arm64-v8a': [],
      'armeabi-v7a': [],
      'x86': [],
      'x86_64': [],
    };
    bool hasManifest = false;
    final activities = <String>[];
    final services = <String>[];
    final receivers = <String>[];
    final providers = <String>[];
    final permissions = <String>[];
    String? launcher;
    String? pkgName;

    for (final file in archive.files) {
      final name = file.name;
      if (name.endsWith('.dex')) {
        dexCount++;
        dexNames.add(name);
      } else if (name == 'resources.arsc') {
        hasArsc = true;
        arscStored = file.compression == CompressionType.none;
      } else if (name.startsWith('res/')) {
        resourceCount++;
      } else if (name.startsWith('assets/')) {
        assetCount++;
      } else if (name.startsWith('lib/')) {
        nativeCount++;
        final parts = name.split('/');
        if (parts.length >= 3) {
          final abi = parts[1];
          final libName = parts.sublist(2).join('/');
          libsByAbi.putIfAbsent(abi, () => []).add(libName);
        }
      } else if (name == 'AndroidManifest.xml') {
        hasManifest = true;
        _parseManifest(file, activities, services, receivers, providers, permissions);
      }
    }

    return ApkInventory(
      dexCount: dexCount,
      dexNames: dexNames,
      totalClassesCount: 0,
      resourceCount: resourceCount,
      hasResourcesArsc: hasArsc,
      isResourcesArscStored: arscStored,
      assetCount: assetCount,
      nativeLibCount: nativeCount,
      nativeLibsByAbi: libsByAbi,
      hasManifest: hasManifest,
      activities: activities,
      services: services,
      receivers: receivers,
      providers: providers,
      permissions: permissions,
      launcherActivity: launcher,
      packageName: pkgName,
    );
  }

  static void _parseManifest(
    ArchiveFile file,
    List<String> activities,
    List<String> services,
    List<String> receivers,
    List<String> providers,
    List<String> permissions,
  ) {
    try {
      final bytes = file.content as List<int>;
      // Scan strings in Android binary XML
      final text = utf8.decode(bytes, allowMalformed: true);
      final regex = RegExp(r'([a-zA-Z0-9_\.]+(?:Activity|Service|Receiver|Provider))');
      for (final match in regex.allMatches(text)) {
        final str = match.group(1)!;
        if (str.endsWith('Activity') && !activities.contains(str)) {
          activities.add(str);
        } else if (str.endsWith('Service') && !services.contains(str)) {
          services.add(str);
        } else if (str.endsWith('Receiver') && !receivers.contains(str)) {
          receivers.add(str);
        } else if (str.endsWith('Provider') && !providers.contains(str)) {
          providers.add(str);
        }
      }
    } catch (_) {}
  }
}

/// Comprehensive Validation Report for the rebuild pipeline
class ValidationReport {
  final bool isValid;
  final bool dexValid;
  final bool resourcesValid;
  final bool manifestValid;
  final bool nativeLibsValid;
  final bool assetsValid;
  final bool alignmentValid;
  final bool signatureValid;
  final bool runtimeValid;
  final String runtimeStatusMessage;
  final ApkInventory originalInventory;
  final ApkInventory rebuiltInventory;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> signatureDetails;
  final Map<String, dynamic> runtimeDiagnostics;

  const ValidationReport({
    required this.isValid,
    required this.dexValid,
    required this.resourcesValid,
    required this.manifestValid,
    required this.nativeLibsValid,
    required this.assetsValid,
    required this.alignmentValid,
    required this.signatureValid,
    required this.runtimeValid,
    required this.runtimeStatusMessage,
    required this.originalInventory,
    required this.rebuiltInventory,
    this.errors = const [],
    this.warnings = const [],
    this.signatureDetails = const {},
    this.runtimeDiagnostics = const {},
  });

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'dexValid': dexValid,
    'resourcesValid': resourcesValid,
    'manifestValid': manifestValid,
    'nativeLibsValid': nativeLibsValid,
    'assetsValid': assetsValid,
    'alignmentValid': alignmentValid,
    'signatureValid': signatureValid,
    'runtimeValid': runtimeValid,
    'runtimeStatusMessage': runtimeStatusMessage,
    'originalInventory': originalInventory.toJson(),
    'rebuiltInventory': rebuiltInventory.toJson(),
    'errors': errors,
    'warnings': warnings,
    'signatureDetails': signatureDetails,
    'runtimeDiagnostics': runtimeDiagnostics,
  };
}

/// Dedicated APK Validation and Verification Service
class ApkValidator {
  /// Validates original vs rebuilt APK inventories and post-build structures
  static ValidationReport validate({
    required ApkInventory original,
    required ApkInventory rebuilt,
    required List<DexParser> rebuiltParsers,
    required List<DetectedCandidate> appliedPatches,
    bool isAligned = true,
    bool isSigned = true,
    Map<String, dynamic> signatureInfo = const {},
    Map<String, dynamic> runtimeDiagnostics = const {},
    bool runtimeTested = false,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. DEX Validation
    bool dexValid = true;
    if (rebuilt.dexCount == 0) {
      dexValid = false;
      errors.add('No DEX files found in rebuilt APK.');
    }
    if (rebuilt.dexCount < original.dexCount) {
      dexValid = false;
      errors.add('Missing DEX files: Original had ${original.dexCount}, Rebuilt has ${rebuilt.dexCount}.');
    }

    for (final parser in rebuiltParsers) {
      final dexRes = parser.validateDexStructure();
      if (!dexRes.isValid) {
        dexValid = false;
        errors.addAll(dexRes.errors.map((e) => '[${parser.dexName}] $e'));
      }
    }

    // Verify applied patches survived in rebuilt DEX
    for (final patch in appliedPatches) {
      final targetDex = rebuiltParsers.firstWhere(
        (p) => p.dexName == patch.dexName,
        orElse: () => rebuiltParsers.first,
      );
      final cls = targetDex.classes.cast<DexClassDef?>().firstWhere(
        (c) => c?.className == patch.finding.className,
        orElse: () => null,
      );
      if (cls == null) {
        dexValid = false;
        errors.add('Patched class ${patch.finding.className} missing from rebuilt ${patch.dexName}.');
      } else {
        final m = cls.allMethods.cast<DexMethodDef?>().firstWhere(
          (m) =>
              m?.methodRef.methodName == patch.finding.triggeringMethod ||
              m?.methodRef.fullSignature == patch.finding.methodSignature,
          orElse: () => null,
        );
        if (m == null || !m.hasCode) {
          dexValid = false;
          errors.add('Patched method ${patch.finding.triggeringMethod} missing or has no code in ${patch.dexName}.');
        }
      }
    }

    // 2. Resource Validation
    bool resourcesValid = true;
    if (original.hasResourcesArsc && !rebuilt.hasResourcesArsc) {
      resourcesValid = false;
      errors.add('Critical: resources.arsc is missing from rebuilt APK.');
    }
    if (rebuilt.resourceCount < (original.resourceCount * 0.95).floor()) {
      warnings.add('Resource count decreased: Original had ${original.resourceCount}, Rebuilt has ${rebuilt.resourceCount}.');
    }

    // 3. Manifest Validation
    bool manifestValid = true;
    if (!rebuilt.hasManifest) {
      manifestValid = false;
      errors.add('Critical: AndroidManifest.xml missing from rebuilt APK.');
    }
    if (original.activities.isNotEmpty && rebuilt.activities.isEmpty) {
      manifestValid = false;
      errors.add('Activities missing from rebuilt AndroidManifest.xml.');
    }

    // 4. Native Library Validation (MUST PRESERVE ALL .SO FILES)
    bool nativeLibsValid = true;
    if (original.nativeLibCount > 0 && rebuilt.nativeLibCount == 0) {
      nativeLibsValid = false;
      errors.add('Critical: Native libraries completely stripped: Original had ${original.nativeLibCount}, Rebuilt has 0.');
    }
    original.nativeLibsByAbi.forEach((abi, originalLibs) {
      final rebuiltLibs = rebuilt.nativeLibsByAbi[abi] ?? [];
      for (final lib in originalLibs) {
        if (!rebuiltLibs.contains(lib)) {
          nativeLibsValid = false;
          errors.add('Critical: Missing native library lib/$abi/$lib in rebuilt APK.');
        }
      }
    });

    // 5. Assets Validation
    bool assetsValid = true;
    if (original.assetCount > 0 && rebuilt.assetCount < original.assetCount) {
      warnings.add('Asset count difference: Original had ${original.assetCount}, Rebuilt has ${rebuilt.assetCount}.');
    }

    // 6. Alignment Validation
    final alignmentValid = isAligned;
    if (!alignmentValid) {
      errors.add('APK alignment verification failed: uncompressed entries are not aligned to 4/4096-byte boundaries.');
    }

    // 7. Signature Validation
    final signatureValid = isSigned;
    if (!signatureValid) {
      errors.add('APK signature verification failed: APK is unsigned or has invalid cryptographic signature.');
    }

    // 8. Runtime Validation
    bool runtimeValid = true;
    String runtimeMsg = 'Static validation passed; runtime validation was not performed.';
    if (runtimeTested) {
      final hasCrash = runtimeDiagnostics['hasCrash'] as bool? ?? false;
      if (hasCrash) {
        runtimeValid = false;
        final root = runtimeDiagnostics['rootException'] as String? ?? 'Fatal Exception';
        final cause = runtimeDiagnostics['cause'] as String? ?? '';
        runtimeMsg = 'Application crashed during startup: $root. $cause';
        errors.add('Runtime crash detected: $root');
      } else {
        runtimeValid = true;
        runtimeMsg = 'Runtime startup test passed without fatal crashes.';
      }
    }

    final allValid = dexValid &&
        resourcesValid &&
        manifestValid &&
        nativeLibsValid &&
        assetsValid &&
        alignmentValid &&
        signatureValid &&
        runtimeValid;

    return ValidationReport(
      isValid: allValid,
      dexValid: dexValid,
      resourcesValid: resourcesValid,
      manifestValid: manifestValid,
      nativeLibsValid: nativeLibsValid,
      assetsValid: assetsValid,
      alignmentValid: alignmentValid,
      signatureValid: signatureValid,
      runtimeValid: runtimeValid,
      runtimeStatusMessage: runtimeMsg,
      originalInventory: original,
      rebuiltInventory: rebuilt,
      errors: errors,
      warnings: warnings,
      signatureDetails: signatureInfo,
      runtimeDiagnostics: runtimeDiagnostics,
    );
  }
}
