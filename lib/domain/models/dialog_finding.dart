enum DetectionConfidence { veryHigh, high, medium, low }

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
  final List<String> callChain; // [MainActivity.onCreate(), checkAndShow(), showDialog(), Dialog.show()]
  final String riskLevel; // LOW, MEDIUM, HIGH, SAFE TO REMOVE
  final bool isInjectedCreditDialog;
  final String? creditAuthor;
  final String? injectionReason;

  // Multi-Signal Evidence & Object-Data Flow Fields (PRD Sections 2-17)
  final String confidenceRating; // VERY HIGH, HIGH, LIKELY, POSSIBLE
  final int confidenceScore; // Weighted score (e.g. 110)
  final String classification; // Application-created custom Dialog, Injected Modder Credit Dialog, etc.
  final String frameworkType; // android.app.Dialog, androidx.appcompat.app.AlertDialog, PopupWindow, etc.
  final String methodSignature; // full signature of the method
  final String objectRegisterFlow; // e.g. v0 -> <init> -> setContentView(v4) -> show()
  final String creationLocation; // method & offset of object instantiation
  final String contentLocation; // method & offset of setContentView / setView
  final String showLocation; // method & offset of show() call
  final String triggerLocation; // entry-point method that initiates display
  final List<String> associatedUiComponents; // e.g. [LinearLayout, TextView, Button]
  final List<String> evidenceList; // Correlated checklist of detected signals
  final String networkRelationship; // e.g. Network-controlled UI candidate (OkHttp -> JSONObject)
  final String smaliCode; // Smali instructions for [Inspect Smali]

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
    this.confidenceRating = 'HIGH',
    this.confidenceScore = 60,
    this.classification = 'Application-created custom Dialog',
    this.frameworkType = 'android.app.Dialog',
    this.methodSignature = '',
    this.objectRegisterFlow = '',
    this.creationLocation = '',
    this.contentLocation = '',
    this.showLocation = '',
    this.triggerLocation = '',
    this.associatedUiComponents = const [],
    this.evidenceList = const [],
    this.networkRelationship = 'None',
    this.smaliCode = '',
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
        'confidenceRating': confidenceRating,
        'confidenceScore': confidenceScore,
        'classification': classification,
        'frameworkType': frameworkType,
        'methodSignature': methodSignature,
        'objectRegisterFlow': objectRegisterFlow,
        'creationLocation': creationLocation,
        'contentLocation': contentLocation,
        'showLocation': showLocation,
        'triggerLocation': triggerLocation,
        'associatedUiComponents': associatedUiComponents,
        'evidenceList': evidenceList,
        'networkRelationship': networkRelationship,
        'smaliCode': smaliCode,
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
        confidenceRating: json['confidenceRating'] as String? ?? 'HIGH',
        confidenceScore: json['confidenceScore'] as int? ?? 60,
        classification: json['classification'] as String? ?? 'Application-created custom Dialog',
        frameworkType: json['frameworkType'] as String? ?? 'android.app.Dialog',
        methodSignature: json['methodSignature'] as String? ?? '',
        objectRegisterFlow: json['objectRegisterFlow'] as String? ?? '',
        creationLocation: json['creationLocation'] as String? ?? '',
        contentLocation: json['contentLocation'] as String? ?? '',
        showLocation: json['showLocation'] as String? ?? '',
        triggerLocation: json['triggerLocation'] as String? ?? '',
        associatedUiComponents: List<String>.from(json['associatedUiComponents'] ?? []),
        evidenceList: List<String>.from(json['evidenceList'] ?? []),
        networkRelationship: json['networkRelationship'] as String? ?? 'None',
        smaliCode: json['smaliCode'] as String? ?? '',
      );
}
