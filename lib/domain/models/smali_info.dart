class SmaliInfo {
  final String className;
  final String smaliCode;
  final String? patchedCode;
  final int instructionsCount;
  final List<String> methods;
  final List<String> dialogInvocations;
  final List<int> modifiedLines;

  const SmaliInfo({
    required this.className,
    required this.smaliCode,
    this.patchedCode,
    required this.instructionsCount,
    this.methods = const [],
    this.dialogInvocations = const [],
    this.modifiedLines = const [],
  });

  String get simpleName => className.contains('/') 
      ? className.split('/').last.replaceAll(';', '') 
      : (className.contains('.') ? className.split('.').last : className);

  bool get isPatched => patchedCode != null && patchedCode != smaliCode;

  Map<String, dynamic> toJson() => {
        'className': className,
        'smaliCode': smaliCode,
        'patchedCode': patchedCode,
        'instructionsCount': instructionsCount,
        'methods': methods,
        'dialogInvocations': dialogInvocations,
        'modifiedLines': modifiedLines,
      };

  factory SmaliInfo.fromJson(Map<String, dynamic> json) => SmaliInfo(
        className: json['className'] as String? ?? '',
        smaliCode: json['smaliCode'] as String? ?? '',
        patchedCode: json['patchedCode'] as String?,
        instructionsCount: json['instructionsCount'] as int? ?? 0,
        methods: List<String>.from(json['methods'] ?? []),
        dialogInvocations: List<String>.from(json['dialogInvocations'] ?? []),
        modifiedLines: List<int>.from(json['modifiedLines'] ?? []),
      );
}
