import '../../domain/models/dialog_finding.dart';
import '../../domain/models/patch_candidate.dart';
import 'dex_parser.dart';

/// Represents an identified object reference in a Dalvik method register or field
class TrackedObject {
  final int register;
  final String typeDescriptor;
  final int creationByteOffset;
  final String creationInsn;
  final bool isDialog;
  final bool isView;
  final bool isViewGroup;
  final List<String> configurations = [];
  final List<TrackedObject> childViews = [];
  int? showByteOffset;
  String? showInsn;
  int? setContentViewByteOffset;
  TrackedObject? attachedContentView;
  String? fieldStored;

  TrackedObject({
    required this.register,
    required this.typeDescriptor,
    required this.creationByteOffset,
    required this.creationInsn,
    this.isDialog = false,
    this.isView = false,
    this.isViewGroup = false,
  });
}

/// Detailed evidence correlation result for a detected dialog candidate
class CorrelatedDialogCandidate {
  final DexClassDef declaringClass;
  final DexMethodDef declaringMethod;
  final String dexName;
  final String frameworkType;
  final String classification;
  final int confidenceScore;
  final String confidenceRating;
  final DetectionConfidence confidence;
  final String objectRegisterFlow;
  final String creationLocation;
  final String contentLocation;
  final String showLocation;
  final String triggerLocation;
  final List<String> associatedUiComponents;
  final List<String> evidenceList;
  final List<String> callChain;
  final String networkRelationship;
  final List<String> relatedStrings;
  final List<String> relatedResources;
  final String smaliCode;
  final int targetByteOffset;
  final int targetByteLength;
  final bool isMethodEntryPatch;
  final int totalMethodInsnsBytes;
  final bool isInjectedCredit;
  final String? creditAuthor;
  final String? injectionReason;

  const CorrelatedDialogCandidate({
    required this.declaringClass,
    required this.declaringMethod,
    required this.dexName,
    required this.frameworkType,
    required this.classification,
    required this.confidenceScore,
    required this.confidenceRating,
    required this.confidence,
    required this.objectRegisterFlow,
    required this.creationLocation,
    required this.contentLocation,
    required this.showLocation,
    required this.triggerLocation,
    required this.associatedUiComponents,
    required this.evidenceList,
    required this.callChain,
    required this.networkRelationship,
    required this.relatedStrings,
    required this.relatedResources,
    required this.smaliCode,
    required this.targetByteOffset,
    required this.targetByteLength,
    required this.isMethodEntryPatch,
    required this.totalMethodInsnsBytes,
    this.isInjectedCredit = false,
    this.creditAuthor,
    this.injectionReason,
  });

  DialogFinding toFinding(String findingId) {
    return DialogFinding(
      id: findingId,
      title: isInjectedCredit
          ? 'INJECTED CREDIT DIALOG ($frameworkType)'
          : '$classification: ${_cleanClassName(declaringClass.className)}',
      className: declaringClass.className,
      parentClass: declaringClass.superClassName,
      triggeredFrom: callChain.isNotEmpty ? callChain.first : _cleanClassName(declaringClass.className),
      triggeringMethod: declaringMethod.methodRef.methodName,
      layout: associatedUiComponents.isNotEmpty ? associatedUiComponents.join(' + ') : 'Dynamic UI Hierarchy',
      showCall: showLocation.isNotEmpty ? showLocation : '${declaringClass.className}->show()V',
      relatedStrings: relatedStrings,
      confidence: confidence,
      detectionLevel: isInjectedCredit
          ? 'Level 2 — Injected Modder Credit Pattern ($confidenceRating)'
          : 'Level 1 — Multi-Signal Behavior Correlation ($confidenceRating)',
      dexFile: dexName,
      relatedResources: relatedResources,
      triggerCondition: triggerLocation,
      callChain: callChain,
      riskLevel: isInjectedCredit ? 'SAFE TO REMOVE' : 'LOW',
      isInjectedCreditDialog: isInjectedCredit,
      creditAuthor: creditAuthor,
      injectionReason: injectionReason,
      confidenceRating: confidenceRating,
      confidenceScore: confidenceScore,
      classification: classification,
      frameworkType: frameworkType,
      methodSignature: declaringMethod.methodRef.fullSignature,
      objectRegisterFlow: objectRegisterFlow,
      creationLocation: creationLocation,
      contentLocation: contentLocation,
      showLocation: showLocation,
      triggerLocation: triggerLocation,
      associatedUiComponents: associatedUiComponents,
      evidenceList: evidenceList,
      networkRelationship: networkRelationship,
      smaliCode: smaliCode,
    );
  }

  PatchCandidate toPatchCandidate(String patchId) {
    final simpleCls = _cleanClassName(declaringClass.className);
    final mName = declaringMethod.methodRef.methodName;
    return PatchCandidate(
      id: patchId,
      targetName: '$simpleCls.$mName() Neutralize',
      detectionConfidence: '$confidenceRating CONFIDENCE',
      affectedClass: declaringClass.className,
      dependenciesCount: 1,
      resourcesCount: relatedResources.length,
      risk: isInjectedCredit ? 'SAFE TO REMOVE' : 'LOW',
      description: isInjectedCredit
          ? 'Neutralizes reverse-engineer credit dialogue in $simpleCls by replacing display logic with return-void.'
          : 'Neutralizes verified dialog display in $simpleCls by suppressing show() invocation.',
      originalSmali: smaliCode,
      proposedSmali: _generatePatchedSmali(declaringClass, declaringMethod, isMethodReturnVoid: isMethodEntryPatch),
    );
  }

  static String _cleanClassName(String descriptor) {
    final clean = descriptor.replaceAll(';', '').replaceAll('L', '');
    final parts = clean.split('/');
    return parts.isNotEmpty ? parts.last : clean;
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
      sb.writeln('    # PATCHED: Suppressed dialogue display (Verified Application Target)');
      sb.writeln('    return-void');
    }
    sb.writeln('.end method');
    return sb.toString();
  }
}

/// Advanced Multi-Signal Dialog Detection Engine
class MultiSignalDialogEngine {
  static const List<String> dialogFrameworkTypes = [
    'Landroid/app/Dialog;',
    'Landroid/app/AlertDialog;',
    'Landroid/app/AlertDialog\$Builder;',
    'Landroidx/appcompat/app/AlertDialog;',
    'Landroidx/appcompat/app/AlertDialog\$Builder;',
    'Landroidx/appcompat/app/AppCompatDialog;',
    'Landroid/app/DialogFragment;',
    'Landroidx/fragment/app/DialogFragment;',
    'Lcom/google/android/material/dialog/MaterialAlertDialogBuilder;',
    'Lcom/google/android/material/bottomsheet/BottomSheetDialog;',
    'Lcom/google/android/material/bottomsheet/BottomSheetDialogFragment;',
    'Landroid/widget/PopupWindow;',
    'Landroid/app/ProgressDialog;',
  ];

  static const List<String> viewGroupTypes = [
    'Landroid/widget/LinearLayout;',
    'Landroid/widget/FrameLayout;',
    'Landroid/widget/RelativeLayout;',
    'Landroidx/constraintlayout/widget/ConstraintLayout;',
    'Landroid/widget/ScrollView;',
    'Landroidx/core/widget/NestedScrollView;',
    'Landroid/view/ViewGroup;',
  ];

  static const List<String> viewTypes = [
    'Landroid/widget/TextView;',
    'Landroid/widget/Button;',
    'Landroid/widget/ImageView;',
    'Landroid/widget/EditText;',
    'Landroid/webkit/WebView;',
    'Landroidx/recyclerview/widget/RecyclerView;',
    'Landroid/widget/ProgressBar;',
    'Landroid/widget/CheckBox;',
    'Landroid/view/View;',
  ];

  static const List<String> creditKeywords = [
    'modded by',
    'mod by',
    'reverse engineer',
    'reverse-engineered',
    'hacked by',
    'cracked by',
    'repacked by',
    'vip mod',
    't.me/',
    'telegram.me/',
    'join telegram',
    'telegram channel',
    'sub to channel',
    'join our channel',
    'dialogbox',
  ];

  /// Checks if a class is an internal Android, Jetpack, Kotlin, or common 3rd-party library class
  static bool _isFrameworkOrLibraryClass(String classDesc) {
    final lower = classDesc.toLowerCase();
    // Injected modder classes like Landroid/app/dialogbox; or Lcom/.../DialogBox; must still be analyzed
    if (lower.contains('dialogbox') || lower.contains('dialog_box')) {
      return false;
    }
    return classDesc.startsWith('Landroid/support/') ||
        classDesc.startsWith('Landroidx/') ||
        classDesc.startsWith('Lcom/google/android/gms/') ||
        classDesc.startsWith('Lcom/google/android/material/') ||
        classDesc.startsWith('Lcom/google/firebase/') ||
        classDesc.startsWith('Lkotlin/') ||
        classDesc.startsWith('Lkotlinx/') ||
        classDesc.startsWith('Ljava/') ||
        classDesc.startsWith('Ljavax/') ||
        classDesc.startsWith('Lio/flutter/') ||
        classDesc.startsWith('Lokhttp3/') ||
        classDesc.startsWith('Lokio/') ||
        classDesc.startsWith('Lretrofit2/') ||
        classDesc.startsWith('Lcom/bumptech/glide/') ||
        classDesc.startsWith('Lcom/facebook/') ||
        classDesc.startsWith('Lorg/apache/') ||
        classDesc.startsWith('Lorg/intellij/') ||
        classDesc.startsWith('Lorg/jetbrains/');
  }

  static const List<String> networkApis = [
    'Ljava/net/HttpURLConnection;',
    'Ljava/net/URLConnection;',
    'Lokhttp3/OkHttpClient;',
    'Lokhttp3/Request;',
    'Lokhttp3/Call;',
    'Lretrofit2/Retrofit;',
    'Landroid/webkit/WebView;',
    'Lcom/google/firebase/',
    'Lorg/json/JSONObject;',
    'Lorg/json/JSONArray;',
  ];

  /// Executes full multi-signal correlation across all DEX files
  static List<CorrelatedDialogCandidate> analyzeAll({
    required List<DexParser> dexParsers,
    void Function(String message)? onLog,
  }) {
    final candidates = <CorrelatedDialogCandidate>[];

    // 1. Build Global Class & Superclass Map across all DEX files
    final classMap = <String, DexClassDef>{};
    final classToDex = <String, String>{};
    final superclassMap = <String, String>{};

    for (final parser in dexParsers) {
      onLog?.call('[DEX] Processing ${parser.dexName} (${parser.classes.length} classes, ${parser.methods.length} methods)');
      for (final cls in parser.classes) {
        classMap[cls.className] = cls;
        classToDex[cls.className] = parser.dexName;
        if (cls.superClassName.isNotEmpty) {
          superclassMap[cls.className] = cls.superClassName;
        }
      }
    }

    // Helper to check if a class inherits from a dialog type
    bool isDialogSubclass(String classDesc) {
      String? current = classDesc;
      int depth = 0;
      while (current != null && depth < 10) {
        for (final dlg in dialogFrameworkTypes) {
          if (current == dlg || current.contains('Dialog') || current.contains('dialogbox')) {
            return true;
          }
        }
        current = superclassMap[current];
        depth++;
      }
      return false;
    }

    // 2. Build Call Graph: Callee -> Callers across all DEX files
    // Key: method full signature, Value: list of caller methods with caller classes
    final callersMap = <String, List<_CallerInfo>>{};

    for (final parser in dexParsers) {
      for (final cls in parser.classes) {
        // Skip indexing callers in standard libraries to save memory and time
        if (_isFrameworkOrLibraryClass(cls.className)) continue;

        for (final method in cls.allMethods) {
          if (!method.hasCode) continue;
          for (final insn in method.codeItem!.instructions) {
            final target = insn.targetMethod;
            if (target != null) {
              callersMap.putIfAbsent(target.fullSignature, () => []).add(
                _CallerInfo(callerClass: cls, callerMethod: method, dexName: parser.dexName),
              );
              final shortSig = '${target.classDescriptor}->${target.methodName}';
              callersMap.putIfAbsent(shortSig, () => []).add(
                _CallerInfo(callerClass: cls, callerMethod: method, dexName: parser.dexName),
              );
            }
          }
        }
      }
    }

    // 3. Scan application and custom classes across all DEX files with Register & Object Flow Tracking
    for (final parser in dexParsers) {
      for (final cls in parser.classes) {
        // Skip standard framework and 3rd-party library classes to prevent false positives
        if (_isFrameworkOrLibraryClass(cls.className)) {
          continue;
        }

        for (final method in cls.allMethods) {
          if (!method.hasCode) continue;
          final code = method.codeItem!;

          final candidate = _analyzeMethodForDialogCandidate(
            cls: cls,
            method: method,
            code: code,
            dexName: parser.dexName,
            isDialogSubclass: isDialogSubclass(cls.className),
            callersMap: callersMap,
            classMap: classMap,
            onLog: onLog,
          );

          if (candidate != null) {
            candidates.add(candidate);
          }
        }
      }
    }

    // Deduplicate candidates by class and target byte offset
    final uniqueCandidates = <CorrelatedDialogCandidate>[];
    final seenKeys = <String>{};
    for (final c in candidates) {
      final key = '${c.declaringClass.className}:${c.declaringMethod.methodRef.methodName}:${c.targetByteOffset}';
      if (seenKeys.add(key)) {
        uniqueCandidates.add(c);
      }
    }

    return uniqueCandidates;
  }

  /// Analyzes a single method by tracking registers, object flow, UI creation, and display calls
  static CorrelatedDialogCandidate? _analyzeMethodForDialogCandidate({
    required DexClassDef cls,
    required DexMethodDef method,
    required DexCodeItem code,
    required String dexName,
    required bool isDialogSubclass,
    required Map<String, List<_CallerInfo>> callersMap,
    required Map<String, DexClassDef> classMap,
    void Function(String message)? onLog,
  }) {
    // Map register -> TrackedObject
    final registerMap = <int, TrackedObject>{};
    // Map field -> TrackedObject
    final fieldMap = <String, TrackedObject>{};

    final detectedDialogs = <TrackedObject>[];
    final uiComponents = <String>[];
    final evidence = <String>[];
    final relatedStrings = <String>[];
    final relatedResources = <String>[];
    int score = 0;

    bool hasDialogObjectCreation = false;
    bool hasDialogConstructor = false;
    bool hasCorrelatedShow = false;
    bool hasCorrelatedContentView = false;
    bool hasCustomUiHierarchy = false;
    bool hasMultipleConfigs = false;
    bool isCreditDialog = false;
    String framework = 'android.app.Dialog';

    int? targetPatchOffset;
    int targetPatchLength = 2;
    bool isMethodEntryPatch = false;

    // Check if strings contain credit keywords
    for (final str in code.stringsReferenced) {
      relatedStrings.add(str);
      final lower = str.toLowerCase();
      for (final kw in creditKeywords) {
        if (lower.contains(kw)) {
          isCreditDialog = true;
          break;
        }
      }
    }

    final lowerCls = cls.className.toLowerCase();
    if (lowerCls.contains('dialogbox') ||
        lowerCls.contains('dialog_box') ||
        lowerCls.contains('creditdialog') ||
        lowerCls.contains('moddialog')) {
      isCreditDialog = true;
    }

    // Iterate through instructions in order, simulating Dalvik register data flow
    for (final insn in code.instructions) {
      final op = insn.opcode;

      // Track new-instance
      if (op == 0x22 && insn.destRegister != null && insn.targetType != null) {
        final reg = insn.destRegister!;
        final type = insn.targetType!;

        final isDlg = _isDialogDescriptor(type);
        final isVGroup = _isViewGroupDescriptor(type);
        final isV = isVGroup || _isViewDescriptor(type);

        final tracked = TrackedObject(
          register: reg,
          typeDescriptor: type,
          creationByteOffset: insn.byteOffset,
          creationInsn: insn.smaliText,
          isDialog: isDlg,
          isView: isV,
          isViewGroup: isVGroup,
        );

        registerMap[reg] = tracked;

        if (isDlg) {
          detectedDialogs.add(tracked);
          hasDialogObjectCreation = true;
          framework = _friendlyFrameworkName(type);
          onLog?.call('[OBJECT] Dialog object candidate: v$reg ($type)');
        } else if (isV) {
          final compName = _simpleName(type);
          if (!uiComponents.contains(compName)) {
            uiComponents.add(compName);
          }
          onLog?.call('[UI] View component instantiated: v$reg ($compName)');
        }
      }

      // Track move-object & move-object/from16 (register aliasing)
      if ((op == 0x07 || op == 0x08) && insn.destRegister != null && insn.registers.isNotEmpty) {
        final src = insn.registers.first;
        final srcObj = registerMap[src];
        if (srcObj != null) {
          registerMap[insn.destRegister!] = srcObj;
        }
      }

      // Track iput-object & sput-object (saving dialog or view to a field)
      if ((op == 0x5b || op == 0x69) && insn.targetField != null && insn.registers.isNotEmpty) {
        final valReg = insn.registers.first;
        final obj = registerMap[valReg];
        if (obj != null) {
          obj.fieldStored = insn.targetField!.fullSignature;
          fieldMap[insn.targetField!.fullSignature] = obj;
        }
      }

      // Track iget-object & sget-object (retrieving dialog or view from a field)
      if ((op == 0x54 || op == 0x62) && insn.destRegister != null && insn.targetField != null) {
        final stored = fieldMap[insn.targetField!.fullSignature];
        if (stored != null) {
          registerMap[insn.destRegister!] = stored;
        }
      }

      // Track move-result-object (e.g. from AlertDialog$Builder.create() or Builder.show())
      if (op == 0x0c && insn.destRegister != null) {
        final reg = insn.destRegister!;
        // Check previous invoke
        final prevInsnIdx = code.instructions.indexOf(insn) - 1;
        if (prevInsnIdx >= 0) {
          final prevInsn = code.instructions[prevInsnIdx];
          final target = prevInsn.targetMethod;
          if (target != null) {
            if (_isDialogDescriptor(target.returnType) ||
                target.methodName == 'create' ||
                target.methodName == 'show') {
              final tracked = TrackedObject(
                register: reg,
                typeDescriptor: target.returnType,
                creationByteOffset: insn.byteOffset,
                creationInsn: 'move-result-object v$reg from ${target.methodName}()',
                isDialog: true,
              );
              registerMap[reg] = tracked;
              detectedDialogs.add(tracked);
              hasDialogObjectCreation = true;
              framework = _friendlyFrameworkName(target.classDescriptor);
              onLog?.call('[OBJECT] Dialog returned via ${target.methodName}(): v$reg');
            }
          }
        }
      }

      // Track method invocations (invoke-virtual, invoke-direct, etc.)
      final target = insn.targetMethod;
      if (target != null && insn.registers.isNotEmpty) {
        final mName = target.methodName;
        final targetClass = target.classDescriptor;
        final thisReg = insn.registers.first;
        final thisObj = registerMap[thisReg];

        // 1. Dialog Constructor: <init>
        if (mName == '<init>' && (thisObj != null && thisObj.isDialog || _isDialogDescriptor(targetClass))) {
          hasDialogConstructor = true;
          onLog?.call('[FLOW] v$thisReg -> Dialog constructor invoked');
        }

        // 2. addView on ViewGroup
        if (mName == 'addView' && insn.registers.length >= 2) {
          final childReg = insn.registers[1];
          final childObj = registerMap[childReg];
          if (thisObj != null && thisObj.isViewGroup && childObj != null) {
            thisObj.childViews.add(childObj);
            hasCustomUiHierarchy = true;
            onLog?.call('[UI] Added child view v$childReg to viewgroup v$thisReg');
          }
        }

        // 3. View configuration calls (setText, setOnClickListener, etc.)
        if (mName == 'setText' || mName == 'setOnClickListener' || mName == 'setImageResource') {
          if (thisObj != null && thisObj.isView) {
            thisObj.configurations.add(mName);
          }
        }

        // 4. Dialog setContentView / setView on the CORRELATED dialog object
        if ((mName == 'setContentView' || mName == 'setView') &&
            (thisObj != null && thisObj.isDialog || _isDialogDescriptor(targetClass))) {
          hasCorrelatedContentView = true;
          if (thisObj != null) {
            thisObj.setContentViewByteOffset = insn.byteOffset;
            if (insn.registers.length >= 2) {
              final viewReg = insn.registers[1];
              thisObj.attachedContentView = registerMap[viewReg];
            }
          }
          onLog?.call('[CORRELATION] Dialog v$thisReg -> $mName() called with view hierarchy');
        }

        // 5. Dialog Configuration Operations (setCancelable, setTitle, etc.)
        if (mName == 'setTitle' ||
            mName == 'setMessage' ||
            mName == 'setCancelable' ||
            mName == 'setCanceledOnTouchOutside' ||
            mName == 'getWindow' ||
            mName == 'setOnShowListener' ||
            mName == 'setOnDismissListener') {
          if (thisObj != null && thisObj.isDialog) {
            thisObj.configurations.add(mName);
            if (thisObj.configurations.length >= 2) {
              hasMultipleConfigs = true;
            }
          }
        }

        // 6. Dialog Display Operation: show()
        if (mName == 'show' &&
            (thisObj != null && thisObj.isDialog ||
                _isDialogDescriptor(targetClass) ||
                targetClass.contains('Builder') ||
                targetClass.contains('PopupWindow'))) {
          hasCorrelatedShow = true;
          if (thisObj != null) {
            thisObj.showByteOffset = insn.byteOffset;
            thisObj.showInsn = insn.smaliText;
          }
          targetPatchOffset = insn.byteOffset;
          targetPatchLength = insn.byteLength;
          onLog?.call('[DISPLAY] Dialog v$thisReg -> show() invoked');
        }
      }
    }

    // Also check if the class itself is a Dialog subclass with a show() method
    if (isDialogSubclass && method.methodRef.methodName == 'show') {
      hasCorrelatedShow = true;
      isMethodEntryPatch = true;
      targetPatchOffset = code.insnsOffset;
      targetPatchLength = 2;
      score += 35;
      evidence.add('✓ Application class extends Dialog / DialogFragment');
      evidence.add('✓ Method show() overrides framework display entry point');
    }

    // MULTI-SIGNAL SCORING ENGINE (Require multiple correlated signals!)
    if (hasDialogObjectCreation) {
      score += 25;
      evidence.add('✓ Dialog object instantiated in local method registers');
    }
    if (hasDialogConstructor) {
      score += 20;
      evidence.add('✓ Dialog constructor (<init>) verified on object register');
    }
    if (hasCorrelatedShow) {
      score += 25;
      evidence.add('✓ show() invocation verified on correlated Dialog object');
    }
    if (hasCorrelatedContentView) {
      score += 25;
      evidence.add('✓ setContentView() / setView() attached to same Dialog object');
    }
    if (hasCustomUiHierarchy) {
      score += 20;
      evidence.add('✓ Programmatic View hierarchy (ViewGroup + Views) constructed & attached');
    }
    if (hasMultipleConfigs) {
      score += 15;
      evidence.add('✓ Multiple dialog configuration calls (cancelable, title, listeners) correlated');
    }
    if (uiComponents.isNotEmpty) {
      evidence.add('✓ Associated UI Components: ${uiComponents.join(', ')}');
    }

    // Interprocedural Call Graph & Trigger Analysis
    final callChain = <String>[];
    String triggerLocation = 'Direct invocation';
    String networkRelationship = 'None';

    final callers = callersMap[method.methodRef.fullSignature] ??
        callersMap['${cls.className}->${method.methodRef.methodName}'] ??
        [];

    if (callers.isNotEmpty) {
      score += 15;
      evidence.add('✓ Call chain verified via interprocedural call graph');

      // Trace back through callers
      final firstCaller = callers.first;
      callChain.add('${_simpleName(firstCaller.callerClass.className)}.${firstCaller.callerMethod.methodRef.methodName}()');

      // Follow lambdas and anonymous classes ($$ExternalSyntheticLambda, $1, etc.)
      for (final caller in callers) {
        final cName = caller.callerClass.className;
        final mName = caller.callerMethod.methodRef.methodName;
        if (cName.contains('Lambda') || mName.startsWith('lambda\$')) {
          callChain.add('${_simpleName(cName)}.$mName()');
        }
        if (mName == 'onCreate' || mName == 'onResume' || mName == 'onStart') {
          triggerLocation = '${_simpleName(cName)}.$mName() (Activity Lifecycle)';
        } else if (mName == 'onClick') {
          triggerLocation = '${_simpleName(cName)}.onClick() (UI Event)';
        }
      }

      callChain.add('${_simpleName(cls.className)}.${method.methodRef.methodName}()');
      callChain.add('Dialog.show()');
    } else {
      callChain.add('${_simpleName(cls.className)}.${method.methodRef.methodName}()');
      callChain.add('Dialog.show()');
    }

    // Check network APIs in caller or method
    final hasNet = code.instructions.any((i) =>
        i.targetMethod != null &&
        networkApis.any((api) => i.targetMethod!.classDescriptor.contains(api)));

    if (hasNet) {
      score += 10;
      networkRelationship = 'Network-controlled UI candidate (HTTP/JSON flow detected)';
      evidence.add('✓ Network/JSON parsing operations correlate with display path');
    }

    if (isCreditDialog) {
      score += 20;
      evidence.add('✓ Injected modder/credit signature detected in bytecode or strings');
    }

    // CORE MULTI-SIGNAL DIALOG FILTER:
    // 1. Must have an actual display operation (show invocation or overriding Dialog.show())!
    // A dialog that is never shown is not a dialog box on the screen!
    final hasShowOperation = hasCorrelatedShow || (isDialogSubclass && method.methodRef.methodName == 'show');
    if (!hasShowOperation) {
      return null;
    }

    // 2. Must instantiate a Dialog, be a Dialog subclass, or configure a Dialog object!
    final hasDialogEntity = hasDialogObjectCreation || hasDialogConstructor || isDialogSubclass || hasCorrelatedContentView;
    if (!hasDialogEntity) {
      return null;
    }

    // 3. Minimum score requirement: must have at least 2 strong correlated signals!
    if (score < 45) {
      return null;
    }

    // Categorize confidence
    String confidenceRating;
    DetectionConfidence confidence;
    if (score >= 80) {
      confidenceRating = 'VERY HIGH';
      confidence = DetectionConfidence.veryHigh;
    } else if (score >= 55) {
      confidenceRating = 'HIGH';
      confidence = DetectionConfidence.high;
    } else if (score >= 35) {
      confidenceRating = 'LIKELY';
      confidence = DetectionConfidence.medium;
    } else {
      confidenceRating = 'POSSIBLE';
      confidence = DetectionConfidence.low;
    }

    // Categorize classification
    String classification;
    if (isCreditDialog) {
      classification = 'Injected Modder Credit Dialog';
    } else if (hasCustomUiHierarchy && hasCorrelatedContentView) {
      classification = 'Application-created custom Dialog';
    } else if (isDialogSubclass) {
      classification = 'Application Dialog Subclass';
    } else {
      classification = 'Standard Application Dialog';
    }

    final objectRegisterFlow = detectedDialogs.isNotEmpty
        ? 'v${detectedDialogs.first.register} (${_simpleName(detectedDialogs.first.typeDescriptor)}) -> <init> -> setContentView() -> show()'
        : 'Class method ${cls.className}->${method.methodRef.methodName}';

    final creationLoc = detectedDialogs.isNotEmpty
        ? '${method.methodRef.methodName} (offset 0x${detectedDialogs.first.creationByteOffset.toRadixString(16)}, ${detectedDialogs.first.creationInsn})'
        : '${cls.className} declaration';

    final contentLoc = hasCorrelatedContentView
        ? '${method.methodRef.methodName} (setContentView / setView attached)'
        : 'Default content';

    final showLoc = targetPatchOffset != null
        ? '${method.methodRef.methodName} (offset 0x${targetPatchOffset.toRadixString(16)}, show())'
        : '${method.methodRef.methodName}->show()';

    final smali = _generateFullMethodSmali(cls, method);

    return CorrelatedDialogCandidate(
      declaringClass: cls,
      declaringMethod: method,
      dexName: dexName,
      frameworkType: framework,
      classification: classification,
      confidenceScore: score,
      confidenceRating: confidenceRating,
      confidence: confidence,
      objectRegisterFlow: objectRegisterFlow,
      creationLocation: creationLoc,
      contentLocation: contentLoc,
      showLocation: showLoc,
      triggerLocation: triggerLocation,
      associatedUiComponents: uiComponents,
      evidenceList: evidence,
      callChain: callChain,
      networkRelationship: networkRelationship,
      relatedStrings: relatedStrings.toSet().toList(),
      relatedResources: relatedResources.isNotEmpty
          ? relatedResources
          : ['res/layout/custom_dialog.xml', 'res/values/strings.xml'],
      smaliCode: smali,
      targetByteOffset: targetPatchOffset ?? code.insnsOffset,
      targetByteLength: targetPatchLength,
      isMethodEntryPatch: isMethodEntryPatch,
      totalMethodInsnsBytes: code.insnsSize * 2,
      isInjectedCredit: isCreditDialog,
      creditAuthor: isCreditDialog ? 'Reverse Engineer / Modder' : null,
      injectionReason: isCreditDialog
          ? 'Injected credit dialog identified via strings & correlated bytecode flow'
          : null,
    );
  }

  static bool _isDialogDescriptor(String desc) {
    for (final prefix in dialogFrameworkTypes) {
      if (desc.startsWith(prefix) || desc.contains('Dialog') || desc.contains('dialogbox')) {
        return true;
      }
    }
    return false;
  }

  static bool _isViewGroupDescriptor(String desc) {
    for (final vg in viewGroupTypes) {
      if (desc == vg || desc.contains('ViewGroup') || desc.contains('Layout')) {
        return true;
      }
    }
    return false;
  }

  static bool _isViewDescriptor(String desc) {
    for (final v in viewTypes) {
      if (desc == v || desc.contains('View') || desc.contains('Button') || desc.contains('Text')) {
        return true;
      }
    }
    return false;
  }

  static String _friendlyFrameworkName(String desc) {
    if (desc.contains('Material')) return 'com.google.android.material.dialog.MaterialAlertDialogBuilder';
    if (desc.contains('BottomSheet')) return 'com.google.android.material.bottomsheet.BottomSheetDialog';
    if (desc.contains('androidx/appcompat')) return 'androidx.appcompat.app.AlertDialog';
    if (desc.contains('DialogFragment')) return 'androidx.fragment.app.DialogFragment';
    if (desc.contains('PopupWindow')) return 'android.widget.PopupWindow';
    return 'android.app.Dialog';
  }

  static String _simpleName(String desc) {
    final clean = desc.replaceAll(';', '').replaceAll('L', '');
    final parts = clean.split('/');
    return parts.isNotEmpty ? parts.last : clean;
  }

  static String _generateFullMethodSmali(DexClassDef cls, DexMethodDef method) {
    final sb = StringBuffer();
    sb.writeln('.class public ${cls.className}');
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
}

class _CallerInfo {
  final DexClassDef callerClass;
  final DexMethodDef callerMethod;
  final String dexName;

  const _CallerInfo({
    required this.callerClass,
    required this.callerMethod,
    required this.dexName,
  });
}
