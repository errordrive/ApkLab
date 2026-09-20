class JadxSource {
  final String className;
  final String packageName;
  final String sourceCode;
  final List<String> methods;
  final List<String> fields;
  final List<String> callers;
  final List<String> references;
  final List<String> usages;

  const JadxSource({
    required this.className,
    required this.packageName,
    required this.sourceCode,
    this.methods = const [],
    this.fields = const [],
    this.callers = const [],
    this.references = const [],
    this.usages = const [],
  });

  String get simpleName => className.contains('.') ? className.split('.').last : className;

  Map<String, dynamic> toJson() => {
        'className': className,
        'packageName': packageName,
        'sourceCode': sourceCode,
        'methods': methods,
        'fields': fields,
        'callers': callers,
        'references': references,
        'usages': usages,
      };

  factory JadxSource.fromJson(Map<String, dynamic> json) => JadxSource(
        className: json['className'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        sourceCode: json['sourceCode'] as String? ?? '',
        methods: List<String>.from(json['methods'] ?? []),
        fields: List<String>.from(json['fields'] ?? []),
        callers: List<String>.from(json['callers'] ?? []),
        references: List<String>.from(json['references'] ?? []),
        usages: List<String>.from(json['usages'] ?? []),
      );
}
