class DexMethod {
  final String name;
  final String returnType;
  final List<String> parameterTypes;
  final List<String> modifiers;
  final bool isObfuscated;

  const DexMethod({
    required this.name,
    required this.returnType,
    required this.parameterTypes,
    required this.modifiers,
    this.isObfuscated = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'returnType': returnType,
        'parameterTypes': parameterTypes,
        'modifiers': modifiers,
        'isObfuscated': isObfuscated,
      };

  factory DexMethod.fromJson(Map<String, dynamic> json) => DexMethod(
        name: json['name'] as String? ?? '',
        returnType: json['returnType'] as String? ?? 'void',
        parameterTypes: List<String>.from(json['parameterTypes'] ?? []),
        modifiers: List<String>.from(json['modifiers'] ?? []),
        isObfuscated: json['isObfuscated'] as bool? ?? false,
      );
}

class DexField {
  final String name;
  final String type;
  final List<String> modifiers;
  final bool isObfuscated;

  const DexField({
    required this.name,
    required this.type,
    required this.modifiers,
    this.isObfuscated = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'modifiers': modifiers,
        'isObfuscated': isObfuscated,
      };

  factory DexField.fromJson(Map<String, dynamic> json) => DexField(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'Object',
        modifiers: List<String>.from(json['modifiers'] ?? []),
        isObfuscated: json['isObfuscated'] as bool? ?? false,
      );
}

class DexClass {
  final String name;
  final String packageName;
  final String superClass;
  final List<String> interfaces;
  final List<DexMethod> methods;
  final List<DexField> fields;
  final bool isObfuscated;
  final bool isDialogRelated;

  const DexClass({
    required this.name,
    required this.packageName,
    required this.superClass,
    required this.interfaces,
    required this.methods,
    required this.fields,
    this.isObfuscated = false,
    this.isDialogRelated = false,
  });

  String get simpleName => name.contains('.') ? name.split('.').last : name;

  Map<String, dynamic> toJson() => {
        'name': name,
        'packageName': packageName,
        'superClass': superClass,
        'interfaces': interfaces,
        'methods': methods.map((e) => e.toJson()).toList(),
        'fields': fields.map((e) => e.toJson()).toList(),
        'isObfuscated': isObfuscated,
        'isDialogRelated': isDialogRelated,
      };

  factory DexClass.fromJson(Map<String, dynamic> json) => DexClass(
        name: json['name'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        superClass: json['superClass'] as String? ?? 'java.lang.Object',
        interfaces: List<String>.from(json['interfaces'] ?? []),
        methods: (json['methods'] as List? ?? [])
            .map((e) => DexMethod.fromJson(e as Map<String, dynamic>))
            .toList(),
        fields: (json['fields'] as List? ?? [])
            .map((e) => DexField.fromJson(e as Map<String, dynamic>))
            .toList(),
        isObfuscated: json['isObfuscated'] as bool? ?? false,
        isDialogRelated: json['isDialogRelated'] as bool? ?? false,
      );
}

class DexInfo {
  final String dexName;
  final int classesCount;
  final int methodsCount;
  final int fieldsCount;
  final int stringsCount;
  final List<String> packages;
  final List<DexClass> classes;

  const DexInfo({
    required this.dexName,
    required this.classesCount,
    required this.methodsCount,
    required this.fieldsCount,
    required this.stringsCount,
    required this.packages,
    required this.classes,
  });

  Map<String, dynamic> toJson() => {
        'dexName': dexName,
        'classesCount': classesCount,
        'methodsCount': methodsCount,
        'fieldsCount': fieldsCount,
        'stringsCount': stringsCount,
        'packages': packages,
        'classes': classes.map((e) => e.toJson()).toList(),
      };

  factory DexInfo.fromJson(Map<String, dynamic> json) => DexInfo(
        dexName: json['dexName'] as String? ?? '',
        classesCount: json['classesCount'] as int? ?? 0,
        methodsCount: json['methodsCount'] as int? ?? 0,
        fieldsCount: json['fieldsCount'] as int? ?? 0,
        stringsCount: json['stringsCount'] as int? ?? 0,
        packages: List<String>.from(json['packages'] ?? []),
        classes: (json['classes'] as List? ?? [])
            .map((e) => DexClass.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
