import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'apk_validator.dart';
import 'dex_parser.dart';
import 'dialog_candidate_detector.dart';

class ApkParsedInventory {
  final ApkInventory inventory;
  final Map<String, Uint8List> dexFiles;

  const ApkParsedInventory({
    required this.inventory,
    required this.dexFiles,
  });
}

class BuildProgress {
  final String stage;
  final String message;
  final double percent;
  final bool isDone;
  final bool hasError;
  final String? error;
  final String? stackTrace;
  final List<String> completedStages;
  final String? outputApkPath;
  final String? outputApkName;
  final String? displayPath;
  final int sizeBytes;
  final ValidationReport? validationReport;
  final String? workspacePath;
  final String? signerInfo;
  final Map<String, dynamic>? runtimeDiagnostics;

  const BuildProgress({
    required this.stage,
    required this.message,
    required this.percent,
    this.isDone = false,
    this.hasError = false,
    this.error,
    this.stackTrace,
    this.completedStages = const [],
    this.outputApkPath,
    this.outputApkName,
    this.displayPath,
    this.sizeBytes = 0,
    this.validationReport,
    this.workspacePath,
    this.signerInfo,
    this.runtimeDiagnostics,
  });
}

class ApkBuildResult {
  final bool success;
  final String? outputApkPath;
  final String? outputApkName;
  final String? displayPath;
  final int sizeBytes;
  final String message;
  final String? error;
  final String? stackTrace;
  final bool v1Signed;
  final bool v2Signed;
  final bool v3Signed;
  final bool isVerified;
  final bool isAligned;
  final List<String> completedStages;
  final ValidationReport? validationReport;
  final String? workspacePath;
  final String? signerInfo;
  final Map<String, dynamic>? runtimeDiagnostics;

  const ApkBuildResult({
    required this.success,
    this.outputApkPath,
    this.outputApkName,
    this.displayPath,
    this.sizeBytes = 0,
    required this.message,
    this.error,
    this.stackTrace,
    this.v1Signed = false,
    this.v2Signed = false,
    this.v3Signed = false,
    this.isVerified = false,
    this.isAligned = false,
    this.completedStages = const [],
    this.validationReport,
    this.workspacePath,
    this.signerInfo,
    this.runtimeDiagnostics,
  });
}

class ApkBuildPipeline {
  static const MethodChannel _channel = MethodChannel('com.example.apklab/native_pipeline');

  /// Opens the system Storage Access Framework directory picker
  static Future<Map<String, String>?> pickOutputDirectory() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('pickOutputDirectory');
      if (res != null) {
        return {
          'uri': res['uri'] as String? ?? '',
          'displayName': res['displayName'] as String? ?? '',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gets the currently persisted SAF output directory
  static Future<Map<String, String>?> getPersistedOutputDirectory() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getPersistedOutputDirectory');
      if (res != null) {
        return {
          'uri': res['uri'] as String? ?? '',
          'displayName': res['displayName'] as String? ?? '',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gets the private internal cache/workspace directory for decoding & intermediate build files
  static Future<String> getPrivateWorkspaceDir() async {
    try {
      final res = await _channel.invokeMethod<String>('getPrivateWorkspaceDir');
      if (res != null && res.isNotEmpty) {
        return res;
      }
    } catch (_) {}
    return Directory.systemTemp.path;
  }

  /// Installs the specified APK using Android's PackageInstaller / FileProvider / SAF URI
  static Future<bool> installApk(String pathOrUri) async {
    try {
      final res = await _channel.invokeMethod<bool>('installApk', {'path': pathOrUri});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shares the APK via Android's ACTION_SEND intent chooser
  static Future<bool> shareApk(String pathOrUri) async {
    try {
      final res = await _channel.invokeMethod<bool>('shareApk', {'path': pathOrUri});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the APK file or its containing folder
  static Future<bool> openFile(String pathOrUri) async {
    try {
      final res = await _channel.invokeMethod<bool>('openFile', {'path': pathOrUri});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Runs Android zipalign on an APK archive
  static Future<Map<String, dynamic>> zipalignApk(String inputPath, String outputPath) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('zipalign', {
      'inputPath': inputPath,
      'outputPath': outputPath,
    });
    return res ?? {};
  }

  /// Verifies 4-byte and 4096-byte alignment of uncompressed entries in an APK
  static Future<Map<String, dynamic>> verifyZipAlignment(String apkPath) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('verifyZipAlignment', {
      'apkPath': apkPath,
    });
    return res ?? {};
  }

  /// Signs an APK with ApkSigner using the configured or custom keystore
  static Future<Map<String, dynamic>> signApk({
    required String inputPath,
    required String outputPath,
    String? customKeystorePath,
    String? customKeystorePass,
    String? customKeyAlias,
  }) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('signApk', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'customKeystorePath': customKeystorePath,
      'customKeystorePass': customKeystorePass,
      'customKeyAlias': customKeyAlias,
    });
    return res ?? {};
  }

  /// Cryptographically verifies the signature of an APK with ApkVerifier
  static Future<Map<String, dynamic>> verifySignature(String apkPath) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('verifySignature', {
      'apkPath': apkPath,
    });
    return res ?? {};
  }

  /// Captures recent logcat diagnostics to detect startup crashes
  static Future<Map<String, dynamic>> captureRuntimeDiagnostics([String packageName = '']) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('captureRuntimeDiagnostics', {
      'packageName': packageName,
    });
    return res ?? {};
  }

  /// Decodes an APK archive and extracts its inventory and DEX bytes inside a background isolate
  static ApkParsedInventory _decodeAndExtractDex(Uint8List apkBytes) {
    final archive = ZipDecoder().decodeBytes(apkBytes);
    final inventory = ApkInventory.fromArchive(archive);
    final dexFiles = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.endsWith('.dex')) {
        dexFiles[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }
    return ApkParsedInventory(
      inventory: inventory,
      dexFiles: dexFiles,
    );
  }

  /// Rebuilds an unsigned APK archive in a background worker isolate, preserving
  /// STORED uncompressed formats for resources.arsc and native libraries (*.so)
  static Uint8List _buildUnsignedApkArchive({
    required Uint8List originalBytes,
    required Map<String, Uint8List> patchedDexMap,
  }) {
    final originalArchive = ZipDecoder().decodeBytes(originalBytes);
    final newArchive = Archive();
    for (final file in originalArchive.files) {
      // Strip old signature files completely (case-insensitive)
      final upperName = file.name.toUpperCase();
      if (upperName.startsWith('META-INF/') &&
          (upperName.endsWith('.SF') ||
              upperName.endsWith('.RSA') ||
              upperName.endsWith('.DSA') ||
              upperName.endsWith('.EC') ||
              upperName == 'META-INF/MANIFEST.MF' ||
              upperName.contains('/SIG-') ||
              upperName.startsWith('META-INF/SIG-'))) {
        continue;
      }

      final isStored = file.name == 'resources.arsc' ||
          (file.name.startsWith('lib/') && file.name.endsWith('.so')) ||
          file.compression == CompressionType.none;

      if (patchedDexMap.containsKey(file.name)) {
        final modifiedData = patchedDexMap[file.name]!;
        final newFile = ArchiveFile(file.name, modifiedData.length, modifiedData);
        newFile.compression = CompressionType.deflate; // DEX files are deflated
        newArchive.addFile(newFile);
      } else {
        file.compression = isStored ? CompressionType.none : CompressionType.deflate;
        newArchive.addFile(file);
      }
    }

    final encoded = ZipEncoder().encode(newArchive);
    return Uint8List.fromList(encoded);
  }

  /// Executes the complete 12-stage rebuild and validation pipeline:
  /// 1. Prepare private workspace
  /// 2. Decode APK & extract original inventory
  /// 3. Analyze DEX/Smali
  /// 4. Controlled transformation (safe Dalvik bytecode patching)
  /// 5. Rebuild APK (preserving STORED compression for resources.arsc & lib/*.so)
  /// 6. Structural & Component Validation (Original vs Rebuilt comparison)
  /// 7. DEX Validation (classes*.dex headers, checksums, method survival)
  /// 8. APK Alignment (Zipalign & verification)
  /// 9. APK Signing (ApkSigner v1 + v2 + v3)
  /// 10. Signature Verification (ApkVerifier)
  /// 11. Runtime Diagnostic Validation (logcat crash detection)
  /// 12. Export through SAF & Final Verification
  static Stream<BuildProgress> runPipelineStream({
    required Uint8List originalBytes,
    required String originalFileName,
    String? customOutputDirectory,
    List<DetectedCandidate> patchesToApply = const [],
    String? customKeystorePath,
    String? customKeystorePass,
    String? customKeyAlias,
    bool runRuntimeDiagnostics = false,
  }) async* {
    final completed = <String>[];
    Directory? workspacesDir;
    ValidationReport? validationReport;

    try {
      final cleanName = originalFileName.replaceAll('.apk', '').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

      // Stage 1: Prepare private workspace
      yield BuildProgress(
        stage: 'Prepare private workspace',
        message: 'Initializing isolated workspace directory for build artifacts...',
        percent: 0.05,
        completedStages: completed,
      );

      if (originalBytes.length < 4 ||
          originalBytes[0] != 0x50 ||
          originalBytes[1] != 0x4b ||
          originalBytes[2] != 0x03 ||
          originalBytes[3] != 0x04) {
        throw FormatException('Invalid APK format: Missing ZIP magic bytes (PK\\x03\\x04).');
      }

      final privateBase = await getPrivateWorkspaceDir();
      workspacesDir = Directory('$privateBase/$cleanName');
      await workspacesDir.create(recursive: true);

      final originalSavedFile = File('${workspacesDir.path}/original_$cleanName.apk');
      await originalSavedFile.writeAsBytes(originalBytes, flush: true);
      completed.add('Prepare private workspace');

      // Stage 2: Decode APK & Extract Original Inventory
      yield BuildProgress(
        stage: 'Decode APK',
        message: 'Decoding APK archive and indexing original components...',
        percent: 0.12,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final originalData = await Isolate.run(() => _decodeAndExtractDex(originalBytes));
      final originalInventory = originalData.inventory;
      completed.add('Decode APK');

      // Stage 3: Analyze DEX/Smali
      yield BuildProgress(
        stage: 'Analyze DEX/Smali',
        message: 'Parsing Dalvik bytecode across ${originalInventory.dexCount} DEX files...',
        percent: 0.22,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      if (originalData.dexFiles.isEmpty) {
        throw StateError('No classes.dex found in the selected APK archive.');
      }

      final parsers = <DexParser>[];
      for (final entry in originalData.dexFiles.entries) {
        final parser = DexParser(dexName: entry.key, bytes: entry.value);
        final ok = parser.parse();
        if (ok) {
          parsers.add(parser);
        }
        await Future.delayed(Duration.zero);
      }

      if (parsers.isEmpty) {
        throw StateError('Failed to parse Dalvik bytecode from DEX files.');
      }

      final detected = DialogCandidateDetector.scanAll(parsers);
      await Future.delayed(Duration.zero);
      completed.add('Analyze DEX/Smali');

      // Stage 4: Controlled transformation
      yield BuildProgress(
        stage: 'Apply patch',
        message: 'Applying type-safe bytecode transformation & recalculating Adler32/SHA-1...',
        percent: 0.35,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final toApply = patchesToApply.isNotEmpty ? patchesToApply : detected;
      final patchedDexMap = <String, Uint8List>{};
      final successfullyApplied = <DetectedCandidate>[];

      for (final candidate in toApply) {
        final parser = parsers.firstWhere(
          (p) => p.dexName == candidate.dexName,
          orElse: () => parsers.first,
        );

        // Pre-patch verification (PRD Section 18)
        final isVerified = DialogCandidateDetector.verifyTargetBeforePatch(
          parser: parser,
          candidate: candidate,
        );
        if (!isVerified) {
          continue;
        }

        // Find target method to check return type and code item
        final cls = parser.classes.cast<DexClassDef?>().firstWhere(
          (c) => c?.className == candidate.finding.className,
          orElse: () => null,
        );
        final method = cls?.allMethods.cast<DexMethodDef?>().firstWhere(
          (m) =>
              m?.methodRef.methodName == candidate.finding.triggeringMethod ||
              m?.methodRef.fullSignature == candidate.finding.methodSignature,
          orElse: () => null,
        );

        if (method != null && method.hasCode) {
          final code = method.codeItem!;

          if (candidate.isMethodEntryPatch) {
            parser.patchMethodSafely(
              codeOffset: code.codeOffset,
              insnsStartByteOffset: candidate.targetByteOffset,
              totalInsnsBytes: candidate.totalMethodInsnsBytes > 0
                  ? candidate.totalMethodInsnsBytes
                  : code.insnsSize * 2,
              returnType: method.methodRef.returnType,
              registersSize: code.registersSize,
            );
          } else {
            parser.patchInstructionSafely(
              byteOffset: candidate.targetByteOffset,
              byteLength: candidate.targetByteLength,
              codeItem: code,
            );
          }

          final validDex = parser.recalculateChecksums();
          patchedDexMap[candidate.dexName] = validDex;
          successfullyApplied.add(candidate);
        }
        await Future.delayed(Duration.zero);
      }

      for (final parser in parsers) {
        if (!patchedDexMap.containsKey(parser.dexName)) {
          patchedDexMap[parser.dexName] = parser.bytes;
        }
      }
      completed.add('Apply patch');
      await Future.delayed(Duration.zero);

      // Stage 5: Rebuild APK (Preserving STORED compression for resources.arsc & lib/*.so)
      yield BuildProgress(
        stage: 'Rebuild APK',
        message: 'Packaging APK entries (preserving uncompressed resources & native libs)...',
        percent: 0.48,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final unsignedBytes = await Isolate.run(() {
        return _buildUnsignedApkArchive(
          originalBytes: originalBytes,
          patchedDexMap: patchedDexMap,
        );
      });
      final unsignedApkFile = File('${workspacesDir.path}/rebuilt-unsigned.apk');
      await unsignedApkFile.writeAsBytes(unsignedBytes, flush: true);
      completed.add('Rebuild APK');

      // Stage 6: Structural & Component Validation
      yield BuildProgress(
        stage: 'Structural validation',
        message: 'Validating component preservation against original APK inventory...',
        percent: 0.58,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final rebuiltData = await Isolate.run(() => _decodeAndExtractDex(unsignedBytes));
      final rebuiltInventory = rebuiltData.inventory;
      completed.add('Structural validation');

      // Stage 7: DEX Validation
      yield BuildProgress(
        stage: 'DEX validation',
        message: 'Validating rebuilt DEX headers, checksums, and method survival...',
        percent: 0.65,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final rebuiltParsers = <DexParser>[];
      for (final entry in rebuiltData.dexFiles.entries) {
        final p = DexParser(dexName: entry.key, bytes: entry.value);
        if (p.parse()) {
          rebuiltParsers.add(p);
        }
        await Future.delayed(Duration.zero);
      }
      completed.add('DEX validation');

      // Stage 8: APK Alignment (Zipalign)
      yield BuildProgress(
        stage: 'Zipalign',
        message: 'Aligning uncompressed entries: 4096-byte page (.so) & 4-byte boundaries...',
        percent: 0.73,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );

      final alignedApkFile = File('${workspacesDir.path}/aligned_$cleanName.apk');
      final alignRes = await zipalignApk(unsignedApkFile.path, alignedApkFile.path);
      if (alignRes['success'] != true) {
        throw StateError('Zipalign failed on rebuilt APK: ${alignRes['error']}');
      }

      final isAligned = alignRes['isAligned'] as bool? ?? false;
      if (!isAligned) {
        throw StateError('APK alignment verification failed: ${alignRes['alignmentReport']}');
      }
      completed.add('Zipalign');

      // Stage 9: APK Signing (ApkSigner v1 + v2 + v3)
      yield BuildProgress(
        stage: 'Sign APK',
        message: 'Signing APK with v1, v2, and v3 cryptographic schemes via ApkSigner...',
        percent: 0.82,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );

      final signedApkFile = File('${workspacesDir.path}/signed_$cleanName.apk');
      final signRes = await signApk(
        inputPath: alignedApkFile.path,
        outputPath: signedApkFile.path,
        customKeystorePath: customKeystorePath,
        customKeystorePass: customKeystorePass,
        customKeyAlias: customKeyAlias,
      );

      if (signRes['success'] != true || signRes['isVerified'] != true) {
        throw StateError('ApkSigner failed to produce a valid signed APK: ${signRes['error'] ?? signRes['verificationReport']}');
      }
      completed.add('Sign APK');

      // Stage 10: Signature Verification (ApkVerifier)
      yield BuildProgress(
        stage: 'Signature verification',
        message: 'Verifying cryptographic signature blocks with ApkVerifier...',
        percent: 0.88,
        completedStages: completed,
        workspacePath: workspacesDir.path,
      );

      final verifyRes = await verifySignature(signedApkFile.path);
      final isSignatureValid = verifyRes['isVerified'] as bool? ?? false;
      if (!isSignatureValid) {
        throw StateError('Signature verification rejected the signed APK: ${verifyRes['errors']}');
      }
      completed.add('Signature verification');

      // Stage 11: Runtime Diagnostic Validation (where requested)
      Map<String, dynamic> runtimeDiag = {};
      if (runRuntimeDiagnostics) {
        yield BuildProgress(
          stage: 'Runtime validation',
          message: 'Monitoring runtime logcat for startup fatal exceptions...',
          percent: 0.92,
          completedStages: completed,
          workspacePath: workspacesDir.path,
        );
        runtimeDiag = await captureRuntimeDiagnostics(originalInventory.packageName ?? '');
        completed.add('Runtime validation');
      }

      // Generate Final Validation Report
      validationReport = ApkValidator.validate(
        original: originalInventory,
        rebuilt: rebuiltInventory,
        rebuiltParsers: rebuiltParsers,
        appliedPatches: successfullyApplied,
        isAligned: isAligned,
        isSigned: isSignatureValid,
        signatureInfo: verifyRes,
        runtimeDiagnostics: runtimeDiag,
        runtimeTested: runRuntimeDiagnostics,
      );

      // Save validation-report.json in workspace
      final reportFile = File('${workspacesDir.path}/validation-report.json');
      await reportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(validationReport.toJson()),
        flush: true,
      );

      if (!validationReport.isValid) {
        throw StateError('Post-build validation failed: ${validationReport.errors.join("; ")}');
      }

      // Stage 12: Export through SAF & Final Verification
      yield BuildProgress(
        stage: 'Export through SAF',
        message: 'Exporting signed & verified APK to user-selected folder via SAF...',
        percent: 0.96,
        completedStages: completed,
        workspacePath: workspacesDir.path,
        validationReport: validationReport,
      );

      final exportRes = await _channel.invokeMapMethod<String, dynamic>('exportApkToSaf', {
        'sourcePath': signedApkFile.path,
        'fileName': 'patched-$cleanName.apk',
        'treeUri': customOutputDirectory,
      });

      if (exportRes == null || exportRes['success'] != true) {
        throw StateError('APK was validated and signed successfully, but export failed: ${exportRes?['error']}');
      }
      completed.add('Export through SAF');

      // Stage 13: Verify Exported APK
      yield BuildProgress(
        stage: 'Verify exported APK',
        message: 'Verifying that document exists and contains non-zero bytes...',
        percent: 0.99,
        completedStages: completed,
        workspacePath: workspacesDir.path,
        validationReport: validationReport,
      );

      final finalSize = exportRes['sizeBytes'] as int? ?? 0;
      if (finalSize == 0) {
        throw StateError('Exported APK verification failed: document has 0 bytes.');
      }
      completed.add('Verify exported APK');

      final displayPath = exportRes['displayPath'] as String? ?? 'patched-$cleanName.apk';
      final finalUri = exportRes['uri'] as String? ?? signedApkFile.path;
      final signerSubject = verifyRes['signerSubject'] as String? ?? 'CN=ApkLab';

      // Save build.log in workspace
      final buildLogFile = File('${workspacesDir.path}/build.log');
      await buildLogFile.writeAsString(
        'BUILD SUCCESSFUL\n'
        'Timestamp: ${DateTime.now().toIso8601String()}\n'
        'Original: ${originalInventory.dexCount} DEX, ${originalInventory.nativeLibCount} native libs, ${originalInventory.resourceCount} resources\n'
        'Rebuilt: ${rebuiltInventory.dexCount} DEX, ${rebuiltInventory.nativeLibCount} native libs, ${rebuiltInventory.resourceCount} resources\n'
        'Signer: $signerSubject\n'
        'Output: $displayPath ($finalSize bytes)\n'
        'Validation: PASS\n',
        flush: true,
      );

      yield BuildProgress(
        stage: 'Build Successful',
        message: 'APK exported successfully to $displayPath (${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB).',
        percent: 1.0,
        isDone: true,
        completedStages: completed,
        outputApkPath: finalUri,
        outputApkName: 'patched-$cleanName.apk',
        displayPath: displayPath,
        sizeBytes: finalSize,
        validationReport: validationReport,
        workspacePath: workspacesDir.path,
        signerInfo: signerSubject,
        runtimeDiagnostics: runtimeDiag,
      );
    } catch (e, st) {
      // PRESERVE WORKSPACE ON FAILURE (PRD Section 17)
      if (workspacesDir != null) {
        try {
          final errorLogFile = File('${workspacesDir.path}/build.log');
          await errorLogFile.writeAsString(
            'BUILD FAILED\n'
            'Timestamp: ${DateTime.now().toIso8601String()}\n'
            'Error: $e\n'
            'Stack trace:\n$st\n',
            flush: true,
          );
        } catch (_) {}
      }

      yield BuildProgress(
        stage: 'Build Failed',
        message: 'Pipeline failed: $e',
        percent: 1.0,
        hasError: true,
        error: e.toString(),
        stackTrace: st.toString(),
        completedStages: completed,
        workspacePath: workspacesDir?.path,
        validationReport: validationReport,
      );
    }
  }

  /// Runs the pipeline asynchronously and returns the final result
  static Future<ApkBuildResult> runPipeline({
    required Uint8List originalBytes,
    required String originalFileName,
    String? customOutputDirectory,
    List<DetectedCandidate> patchesToApply = const [],
    String? customKeystorePath,
    String? customKeystorePass,
    String? customKeyAlias,
    bool runRuntimeDiagnostics = false,
    void Function(BuildProgress)? onProgress,
  }) async {
    BuildProgress? lastProgress;
    await for (final progress in runPipelineStream(
      originalBytes: originalBytes,
      originalFileName: originalFileName,
      customOutputDirectory: customOutputDirectory,
      patchesToApply: patchesToApply,
      customKeystorePath: customKeystorePath,
      customKeystorePass: customKeystorePass,
      customKeyAlias: customKeyAlias,
      runRuntimeDiagnostics: runRuntimeDiagnostics,
    )) {
      lastProgress = progress;
      onProgress?.call(progress);
    }

    if (lastProgress == null || lastProgress.hasError) {
      return ApkBuildResult(
        success: false,
        message: lastProgress?.message ?? 'Build failed with unknown error.',
        error: lastProgress?.error,
        stackTrace: lastProgress?.stackTrace,
        completedStages: lastProgress?.completedStages ?? [],
        workspacePath: lastProgress?.workspacePath,
        validationReport: lastProgress?.validationReport,
      );
    }

    final cleanName = originalFileName.replaceAll('.apk', '').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return ApkBuildResult(
      success: true,
      outputApkPath: lastProgress.outputApkPath ?? lastProgress.message,
      outputApkName: lastProgress.outputApkName ?? 'patched-$cleanName.apk',
      displayPath: lastProgress.displayPath ?? 'patched-$cleanName.apk',
      sizeBytes: lastProgress.sizeBytes,
      message: 'APK exported successfully.',
      v1Signed: true,
      v2Signed: true,
      v3Signed: true,
      isVerified: true,
      isAligned: true,
      completedStages: lastProgress.completedStages,
      validationReport: lastProgress.validationReport,
      workspacePath: lastProgress.workspacePath,
      signerInfo: lastProgress.signerInfo,
      runtimeDiagnostics: lastProgress.runtimeDiagnostics,
    );
  }
}
