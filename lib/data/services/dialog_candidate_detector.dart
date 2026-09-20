import '../../domain/models/dialog_finding.dart';
import '../../domain/models/patch_candidate.dart';
import 'dex_parser.dart';

class DetectedCandidate {
  final DialogFinding finding;
  final PatchCandidate patchCandidate;
  final String dexName;
  final int targetByteOffset;
  final int targetByteLength;
  final bool isMethodEntryPatch;
  final int totalMethodInsnsBytes;

  const DetectedCandidate({
    required this.finding,
    required this.patchCandidate,
    required this.dexName,
    required this.targetByteOffset,
    required this.targetByteLength,
    this.isMethodEntryPatch = false,
    this.totalMethodInsnsBytes = 0,
  });
}

class DialogCandidateDetector {
  static const List<String> dialogApiPrefixes = [
    'Landroid/app/Dialog',
    'Landroid/app/AlertDialog',
    'Landroid/app/DialogFragment',
    'Landroidx/appcompat/app/AlertDialog',
    'Landroidx/fragment/app/DialogFragment',
    'Lcom/google/android/material/dialog/MaterialAlertDialogBuilder',
    'Lcom/google/android/material/bottomsheet/BottomSheetDialog',
    'Lcom/google/android/material/bottomsheet/BottomSheetDialogFragment',
    'Landroid/app/ProgressDialog',
  ];

  static const List<String> creditKeywords = [
    'modded by',
    'mod by',
    'reverse engineer',
    'reverse-engineered',
    'credits',
    'credit',
    'telegram',
    't.me/',
    'channel',
    'cracked',
    'repacked',
    'hacked by',
    'modder',
    'author',
    'vip mod',
  ];

  /// Scans all DEX parsers dynamically across all DEX files and finds all dialog candidates
  static List<DetectedCandidate> scanAll(List<DexParser> parsers) {
    final candidates = <DetectedCandidate>[];
    int findingCounter = 1;

    for (final parser in parsers) {
      for (final cls in parser.classes) {
        final lowerClass = cls.className.toLowerCase();
        final lowerSuper = cls.superClassName.toLowerCase();

        final isDialogSubclass = _isDialogType(cls.superClassName) ||
            lowerSuper.contains('dialog') ||
            lowerClass.contains('dialogbox');

        // 1. If class itself is a Dialog subclass (or custom dialog), inspect its show/onCreate methods
        if (isDialogSubclass) {
          for (final method in cls.allMethods) {
            final mName = method.methodRef.methodName;
            if (mName == 'show' && method.hasCode) {
              final code = method.codeItem!;
              final smali = _generateMethodSmali(cls, method);
              final findingId = 'finding_dlg_${findingCounter.toString().padLeft(2, '0')}';
              final patchId = 'patch_target_${findingCounter.toString().padLeft(2, '0')}';

              final isCredit = _hasCreditKeywords(code.stringsReferenced) ||
                  lowerClass.contains('credit') ||
                  lowerClass.contains('dialogbox');

              final finding = DialogFinding(
                id: findingId,
                title: isCredit
                    ? 'INJECTED CREDIT DIALOG #${findingCounter.toString().padLeft(2, '0')}'
                    : 'DIALOG CLASS METHOD #${findingCounter.toString().padLeft(2, '0')}',
                className: cls.className,
                parentClass: cls.superClassName,
                triggeredFrom: cls.className,
                triggeringMethod: method.methodRef.fullSignature,
                layout: 'Dynamic View / Layout',
                showCall: '${cls.className}->show()V',
                relatedStrings: code.stringsReferenced,
                confidence: DetectionConfidence.high,
                detectionLevel: isCredit
                    ? 'Level 2 — Injected Modder Credit Dialog'
                    : 'Level 1 — Dialog Class Hierarchy',
                dexFile: parser.dexName,
                relatedResources: [],
                triggerCondition: 'Direct invocation of dialog show() method',
                callChain: [cls.className, 'show()V'],
                riskLevel: isCredit ? 'SAFE TO REMOVE' : 'LOW',
                isInjectedCreditDialog: isCredit,
                creditAuthor: isCredit ? 'Reverse Engineer / Modder' : null,
                injectionReason: isCredit
                    ? 'Injected credit dialog identified via strings & dialog structure'
                    : null,
              );

              final patch = PatchCandidate(
                id: patchId,
                targetName: '${_simpleName(cls.className)}.show() Suppress',
                detectionConfidence: 'HIGH CONFIDENCE',
                affectedClass: cls.className,
                dependenciesCount: 1,
                resourcesCount: 0,
                risk: isCredit ? 'SAFE' : 'LOW',
                description: isCredit
                    ? 'Neutralizes reverse-engineer credit dialog by replacing method entry with return-void.'
                    : 'Suppresses dialog display by neutralizing show() method.',
                originalSmali: smali,
                proposedSmali: _generatePatchedSmali(cls, method, isMethodReturnVoid: true),
              );

              candidates.add(
                DetectedCandidate(
                  finding: finding,
                  patchCandidate: patch,
                  dexName: parser.dexName,
                  targetByteOffset: code.insnsOffset,
                  targetByteLength: 2,
                  isMethodEntryPatch: true,
                  totalMethodInsnsBytes: code.insnsSize * 2,
                ),
              );
              findingCounter++;
            }
          }
        }

        // 2. Scan all methods in all classes for invocations of show(), create(), Dialog builder methods
        for (final method in cls.allMethods) {
          if (!method.hasCode) continue;
          final code = method.codeItem!;

          for (final insn in code.instructions) {
            final targetMethod = insn.targetMethod;
            if (targetMethod == null) continue;

            final isShowCall = targetMethod.methodName == 'show' &&
                (_isDialogType(targetMethod.classDescriptor) ||
                    targetMethod.classDescriptor.toLowerCase().contains('dialog'));

            final isCreateCall = (targetMethod.methodName == 'create' ||
                    targetMethod.methodName == 'show') &&
                targetMethod.classDescriptor.contains('Builder');

            if (isShowCall || isCreateCall) {
              final isCredit = _hasCreditKeywords(code.stringsReferenced) ||
                  cls.className.toLowerCase().contains('credit') ||
                  cls.className.toLowerCase().contains('dialogbox');

              final findingId = 'finding_dlg_${findingCounter.toString().padLeft(2, '0')}';
              final patchId = 'patch_target_${findingCounter.toString().padLeft(2, '0')}';
              final smali = _generateMethodSmali(cls, method);

              final finding = DialogFinding(
                id: findingId,
                title: isCredit
                    ? 'INJECTED CREDIT DIALOG CALL #${findingCounter.toString().padLeft(2, '0')}'
                    : 'DIALOG INVOCATION #${findingCounter.toString().padLeft(2, '0')}',
                className: cls.className,
                parentClass: cls.superClassName,
                triggeredFrom: cls.className,
                triggeringMethod: method.methodRef.fullSignature,
                layout: 'Dynamic Dialog Construction',
                showCall: targetMethod.fullSignature,
                relatedStrings: code.stringsReferenced,
                confidence: isCredit ? DetectionConfidence.high : DetectionConfidence.medium,
                detectionLevel: isCredit
                    ? 'Level 3 — Injected Modder Call Site'
                    : 'Level 1 — API Call Site',
                dexFile: parser.dexName,
                relatedResources: [],
                triggerCondition: 'Invoked during ${method.methodRef.methodName}',
                callChain: [cls.className, method.methodRef.methodName, targetMethod.fullSignature],
                riskLevel: isCredit ? 'SAFE TO REMOVE' : 'LOW',
                isInjectedCreditDialog: isCredit,
                creditAuthor: isCredit ? 'Reverse Engineer / Modder' : null,
                injectionReason: isCredit
                    ? 'Injected credit dialog call site identified via strings & bytecode'
                    : null,
              );

              final patch = PatchCandidate(
                id: patchId,
                targetName: '${_simpleName(cls.className)}->${targetMethod.methodName}() NOP',
                detectionConfidence: isCredit ? 'HIGH CONFIDENCE' : 'MEDIUM CONFIDENCE',
                affectedClass: cls.className,
                dependenciesCount: 1,
                resourcesCount: 0,
                risk: isCredit ? 'SAFE' : 'LOW',
                description: 'Neutralizes dialog invocation instruction (${insn.smaliText}) with NOP opcodes.',
                originalSmali: smali,
                proposedSmali: _generatePatchedSmaliWithNop(cls, method, insn.byteOffset),
              );

              candidates.add(
                DetectedCandidate(
                  finding: finding,
                  patchCandidate: patch,
                  dexName: parser.dexName,
                  targetByteOffset: insn.byteOffset,
                  targetByteLength: insn.byteLength,
                  isMethodEntryPatch: false,
                  totalMethodInsnsBytes: code.insnsSize * 2,
                ),
              );
              findingCounter++;
            }
          }
        }
      }
    }

    return candidates;
  }

  static bool _isDialogType(String descriptor) {
    for (final prefix in dialogApiPrefixes) {
      if (descriptor.startsWith(prefix) || descriptor.contains(prefix)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasCreditKeywords(List<String> strings) {
    for (final str in strings) {
      final lower = str.toLowerCase();
      for (final kw in creditKeywords) {
        if (lower.contains(kw)) return true;
      }
    }
    return false;
  }

  static String _simpleName(String descriptor) {
    final clean = descriptor.replaceAll(';', '').replaceAll('L', '');
    final parts = clean.split('/');
    return parts.isNotEmpty ? parts.last : clean;
  }

  static String _generateMethodSmali(DexClassDef cls, DexMethodDef method) {
    final sb = StringBuffer();
    sb.writeln('.class ${cls.className}');
    if (cls.superClassName.isNotEmpty) {
      sb.writeln('.super ${cls.superClassName}');
    }
    sb.writeln();
    sb.writeln('.method public ${method.methodRef.methodName}(${method.methodRef.parameterTypes.join()})${method.methodRef.returnType}');
    if (method.hasCode) {
      final code = method.codeItem!;
      sb.writeln('    .registers ${code.registersSize}');
      for (final insn in code.instructions) {
        sb.writeln('    ${insn.smaliText}');
      }
    }
    sb.writeln('.end method');
    return sb.toString();
  }

  static String _generatePatchedSmali(
    DexClassDef cls,
    DexMethodDef method, {
    required bool isMethodReturnVoid,
  }) {
    final sb = StringBuffer();
    sb.writeln('.class ${cls.className}');
    if (cls.superClassName.isNotEmpty) {
      sb.writeln('.super ${cls.superClassName}');
    }
    sb.writeln();
    sb.writeln('.method public ${method.methodRef.methodName}(${method.methodRef.parameterTypes.join()})${method.methodRef.returnType}');
    if (method.hasCode) {
      final code = method.codeItem!;
      sb.writeln('    .registers ${code.registersSize}');
      sb.writeln('    # PATCHED: Suppressed dialogue display');
      sb.writeln('    return-void');
    }
    sb.writeln('.end method');
    return sb.toString();
  }

  static String _generatePatchedSmaliWithNop(
    DexClassDef cls,
    DexMethodDef method,
    int targetByteOffset,
  ) {
    final sb = StringBuffer();
    sb.writeln('.class ${cls.className}');
    if (cls.superClassName.isNotEmpty) {
      sb.writeln('.super ${cls.superClassName}');
    }
    sb.writeln();
    sb.writeln('.method public ${method.methodRef.methodName}(${method.methodRef.parameterTypes.join()})${method.methodRef.returnType}');
    if (method.hasCode) {
      final code = method.codeItem!;
      sb.writeln('    .registers ${code.registersSize}');
      for (final insn in code.instructions) {
        if (insn.byteOffset == targetByteOffset) {
          sb.writeln('    # PATCHED: Neutralized with NOP');
          sb.writeln('    nop');
        } else {
          sb.writeln('    ${insn.smaliText}');
        }
      }
    }
    sb.writeln('.end method');
    return sb.toString();
  }
}
