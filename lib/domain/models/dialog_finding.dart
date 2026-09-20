enum DetectionConfidence { high, medium, low }

class DialogFinding {
  final String id;
  final String title;
  final String className;
  final String parentClass;
  final String triggeredFrom;
  final String triggeringMethod;
  final String layout;
  final String showCall;
  final List<String> relatedStrings;
  final DetectionConfidence confidence;
  final String detectionLevel; // Level 1 to Level 5
  final String dexFile;
  final List<String> relatedResources;
  final String triggerCondition;
  final List<String> callChain; // [MainActivity, checkVersion(), CustomWarning, setContentView(), Dialog.show()]
  final String riskLevel; // LOW, MEDIUM, HIGH
  final bool isInjectedCreditDialog;
  final String? creditAuthor;
  final String? injectionReason;

  const DialogFinding({
    required this.id,
    required this.title,
    required this.className,
    required this.parentClass,
    required this.triggeredFrom,
    required this.triggeringMethod,
    required this.layout,
    required this.showCall,
    required this.relatedStrings,
    required this.confidence,
    required this.detectionLevel,
    required this.dexFile,
    required this.relatedResources,
    required this.triggerCondition,
    required this.callChain,
    this.riskLevel = 'MEDIUM',
    this.isInjectedCreditDialog = false,
    this.creditAuthor,
    this.injectionReason,
  });

  String get simpleName => className.contains('.') ? className.split('.').last : className;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'className': className,
        'parentClass': parentClass,
        'triggeredFrom': triggeredFrom,
        'triggeringMethod': triggeringMethod,
        'layout': layout,
        'showCall': showCall,
        'relatedStrings': relatedStrings,
        'confidence': confidence.name,
        'detectionLevel': detectionLevel,
        'dexFile': dexFile,
        'relatedResources': relatedResources,
        'triggerCondition': triggerCondition,
        'callChain': callChain,
        'riskLevel': riskLevel,
        'isInjectedCreditDialog': isInjectedCreditDialog,
        'creditAuthor': creditAuthor,
        'injectionReason': injectionReason,
      };

  factory DialogFinding.fromJson(Map<String, dynamic> json) => DialogFinding(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        className: json['className'] as String? ?? '',
        parentClass: json['parentClass'] as String? ?? 'android.app.Dialog',
        triggeredFrom: json['triggeredFrom'] as String? ?? '',
        triggeringMethod: json['triggeringMethod'] as String? ?? '',
        layout: json['layout'] as String? ?? '',
        showCall: json['showCall'] as String? ?? 'Dialog.show()',
        relatedStrings: List<String>.from(json['relatedStrings'] ?? []),
        confidence: DetectionConfidence.values.firstWhere(
          (e) => e.name == (json['confidence'] as String? ?? 'high').toLowerCase(),
          orElse: () => DetectionConfidence.high,
        ),
        detectionLevel: json['detectionLevel'] as String? ?? 'Level 1 — Known Android APIs',
        dexFile: json['dexFile'] as String? ?? 'classes.dex',
        relatedResources: List<String>.from(json['relatedResources'] ?? []),
        triggerCondition: json['triggerCondition'] as String? ?? '',
        callChain: List<String>.from(json['callChain'] ?? []),
        riskLevel: json['riskLevel'] as String? ?? 'MEDIUM',
        isInjectedCreditDialog: json['isInjectedCreditDialog'] as bool? ?? false,
        creditAuthor: json['creditAuthor'] as String?,
        injectionReason: json['injectionReason'] as String?,
      );
}
