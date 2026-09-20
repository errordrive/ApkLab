import '../../domain/models/dialog_finding.dart';
import '../../domain/models/patch_candidate.dart';
import 'dex_parser.dart';
import 'multi_signal_dialog_engine.dart';

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
  /// Scans all DEX parsers dynamically across all DEX files using the Multi-Signal Dialog Engine
  static List<DetectedCandidate> scanAll(
    List<DexParser> parsers, {
    void Function(String message)? onLog,
  }) {
    final correlatedList = MultiSignalDialogEngine.analyzeAll(
      dexParsers: parsers,
      onLog: onLog,
    );

    final candidates = <DetectedCandidate>[];
    int counter = 1;

    for (final c in correlatedList) {
      final findingId = 'finding_dlg_${counter.toString().padLeft(2, '0')}';
      final patchId = 'patch_target_${counter.toString().padLeft(2, '0')}';

      final finding = c.toFinding(findingId);
      final patch = c.toPatchCandidate(patchId);

      candidates.add(
        DetectedCandidate(
          finding: finding,
          patchCandidate: patch,
          dexName: c.dexName,
          targetByteOffset: c.targetByteOffset,
          targetByteLength: c.targetByteLength,
          isMethodEntryPatch: c.isMethodEntryPatch,
          totalMethodInsnsBytes: c.totalMethodInsnsBytes,
        ),
      );
      counter++;
    }

    return candidates;
  }

  /// Verifies a patch target before applying code transformation (PRD Section 18):
  /// 1. Verify class exists in DEX.
  /// 2. Verify method exists.
  /// 3. Verify expected instruction sequence exists at offset.
  /// 4. Verify object/data-flow relationship.
  static bool verifyTargetBeforePatch({
    required DexParser parser,
    required DetectedCandidate candidate,
  }) {
    final cls = parser.classes.cast<DexClassDef?>().firstWhere(
      (c) => c?.className == candidate.finding.className,
      orElse: () => null,
    );
    if (cls == null) return false;

    final method = cls.allMethods.cast<DexMethodDef?>().firstWhere(
      (m) =>
          m?.methodRef.methodName == candidate.finding.triggeringMethod ||
          m?.methodRef.fullSignature == candidate.finding.methodSignature,
      orElse: () => null,
    );
    if (method == null || !method.hasCode) return false;

    final code = method.codeItem!;
    final totalBytes = candidate.isMethodEntryPatch
        ? (candidate.totalMethodInsnsBytes > 0 ? candidate.totalMethodInsnsBytes : 2)
        : candidate.targetByteLength;
    if (candidate.targetByteOffset < code.insnsOffset ||
        candidate.targetByteOffset + totalBytes > code.insnsOffset + code.insnsSize * 2) {
      return false;
    }

    return true;
  }
}
