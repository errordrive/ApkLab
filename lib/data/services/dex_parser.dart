import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class DexMethodRef {
  final int methodIndex;
  final String classDescriptor;
  final String methodName;
  final String returnType;
  final List<String> parameterTypes;

  const DexMethodRef({
    required this.methodIndex,
    required this.classDescriptor,
    required this.methodName,
    required this.returnType,
    required this.parameterTypes,
  });

  String get fullSignature => '$classDescriptor->$methodName(${parameterTypes.join()})$returnType';

  @override
  String toString() => fullSignature;
}

class DexFieldRef {
  final int fieldIndex;
  final String classDescriptor;
  final String fieldName;
  final String typeDescriptor;

  const DexFieldRef({
    required this.fieldIndex,
    required this.classDescriptor,
    required this.fieldName,
    required this.typeDescriptor,
  });

  String get fullSignature => '$classDescriptor->$fieldName:$typeDescriptor';

  @override
  String toString() => fullSignature;
}

class DexInstruction {
  final int opcode;
  final int byteOffset;
  final int byteLength;
  final String smaliText;
  final DexMethodRef? targetMethod;
  final String? stringConstant;
  final String? targetType;
  final DexFieldRef? targetField;
  final List<int> registers;
  final int? destRegister;

  const DexInstruction({
    required this.opcode,
    required this.byteOffset,
    required this.byteLength,
    required this.smaliText,
    this.targetMethod,
    this.stringConstant,
    this.targetType,
    this.targetField,
    this.registers = const [],
    this.destRegister,
  });

  @override
  String toString() => smaliText;
}

class DexCodeItem {
  final int codeOffset;
  final int registersSize;
  final int insSize;
  final int outsSize;
  final int insnsSize;
  final int insnsOffset;
  final List<DexInstruction> instructions;
  final List<String> stringsReferenced;
  final List<DexMethodRef> methodsInvoked;

  const DexCodeItem({
    required this.codeOffset,
    required this.registersSize,
    required this.insSize,
    required this.outsSize,
    required this.insnsSize,
    required this.insnsOffset,
    required this.instructions,
    required this.stringsReferenced,
    required this.methodsInvoked,
  });
}

class DexMethodDef {
  final DexMethodRef methodRef;
  final int accessFlags;
  final DexCodeItem? codeItem;

  const DexMethodDef({
    required this.methodRef,
    required this.accessFlags,
    this.codeItem,
  });

  bool get hasCode => codeItem != null;
}

class DexClassDef {
  final String className;
  final int accessFlags;
  final String superClassName;
  final List<String> interfaces;
  final List<DexMethodDef> directMethods;
  final List<DexMethodDef> virtualMethods;

  const DexClassDef({
    required this.className,
    required this.accessFlags,
    required this.superClassName,
    required this.interfaces,
    required this.directMethods,
    required this.virtualMethods,
  });

  List<DexMethodDef> get allMethods => [...directMethods, ...virtualMethods];
}

class DexParser {
  final String dexName;
  Uint8List bytes;
  late ByteData _byteData;

  final List<String> strings = [];
  final List<String> types = [];
  final List<DexFieldRef> fields = [];
  final List<DexMethodRef> methods = [];
  final List<DexClassDef> classes = [];

  DexParser({required this.dexName, required this.bytes}) {
    _byteData = ByteData.sublistView(bytes);
  }

  /// Parses the DEX headers, string table, type table, method table, and class definitions
  bool parse() {
    try {
      if (bytes.length < 0x70) return false;

      // Check magic: "dex\n"
      if (bytes[0] != 0x64 || bytes[1] != 0x65 || bytes[2] != 0x78 || bytes[3] != 0x0a) {
        return false;
      }

      final stringIdsSize = _byteData.getUint32(56, Endian.little);
      final stringIdsOff = _byteData.getUint32(60, Endian.little);

      final typeIdsSize = _byteData.getUint32(64, Endian.little);
      final typeIdsOff = _byteData.getUint32(68, Endian.little);

      final protoIdsSize = _byteData.getUint32(72, Endian.little);
      final protoIdsOff = _byteData.getUint32(76, Endian.little);

      final fieldIdsSize = _byteData.getUint32(80, Endian.little);
      final fieldIdsOff = _byteData.getUint32(84, Endian.little);

      final methodIdsSize = _byteData.getUint88(88, Endian.little);
      final methodIdsOff = _byteData.getUint32(92, Endian.little);

      final classDefsSize = _byteData.getUint32(96, Endian.little);
      final classDefsOff = _byteData.getUint32(100, Endian.little);

      // 1. Parse Strings
      strings.clear();
      for (int i = 0; i < stringIdsSize; i++) {
        final off = _byteData.getUint32(stringIdsOff + i * 4, Endian.little);
        strings.add(_readString(off));
      }

      // 2. Parse Types
      types.clear();
      for (int i = 0; i < typeIdsSize; i++) {
        final descriptorIdx = _byteData.getUint32(typeIdsOff + i * 4, Endian.little);
        types.add(descriptorIdx < strings.length ? strings[descriptorIdx] : 'UnknownType_$i');
      }

      // 3. Parse Protos
      final protoReturnTypes = <String>[];
      final protoParamTypes = <List<String>>[];
      for (int i = 0; i < protoIdsSize; i++) {
        final returnTypeIdx = _byteData.getUint32(protoIdsOff + i * 12 + 4, Endian.little);
        final paramsOff = _byteData.getUint32(protoIdsOff + i * 12 + 8, Endian.little);

        final returnType = returnTypeIdx < types.length ? types[returnTypeIdx] : 'V';
        protoReturnTypes.add(returnType);

        final params = <String>[];
        if (paramsOff != 0 && paramsOff + 4 <= bytes.length) {
          final size = _byteData.getUint32(paramsOff, Endian.little);
          for (int p = 0; p < size; p++) {
            final typeIdx = _byteData.getUint16(paramsOff + 4 + p * 2, Endian.little);
            params.add(typeIdx < types.length ? types[typeIdx] : '?');
          }
        }
        protoParamTypes.add(params);
      }

      // 4. Parse Fields
      fields.clear();
      for (int i = 0; i < fieldIdsSize; i++) {
        final classIdx = _byteData.getUint16(fieldIdsOff + i * 8, Endian.little);
        final typeIdx = _byteData.getUint16(fieldIdsOff + i * 8 + 2, Endian.little);
        final nameIdx = _byteData.getUint32(fieldIdsOff + i * 8 + 4, Endian.little);

        final classDesc = classIdx < types.length ? types[classIdx] : 'Lunknown;';
        final typeDesc = typeIdx < types.length ? types[typeIdx] : 'Lunknown;';
        final fieldName = nameIdx < strings.length ? strings[nameIdx] : 'field$i';

        fields.add(
          DexFieldRef(
            fieldIndex: i,
            classDescriptor: classDesc,
            fieldName: fieldName,
            typeDescriptor: typeDesc,
          ),
        );
      }

      // 5. Parse Methods
      methods.clear();
      for (int i = 0; i < methodIdsSize; i++) {
        final classIdx = _byteData.getUint16(methodIdsOff + i * 8, Endian.little);
        final protoIdx = _byteData.getUint16(methodIdsOff + i * 8 + 2, Endian.little);
        final nameIdx = _byteData.getUint32(methodIdsOff + i * 8 + 4, Endian.little);

        final classDesc = classIdx < types.length ? types[classIdx] : 'Lunknown;';
        final methodName = nameIdx < strings.length ? strings[nameIdx] : 'method$i';
        final returnType = protoIdx < protoReturnTypes.length ? protoReturnTypes[protoIdx] : 'V';
        final params = protoIdx < protoParamTypes.length ? protoParamTypes[protoIdx] : <String>[];

        methods.add(
          DexMethodRef(
            methodIndex: i,
            classDescriptor: classDesc,
            methodName: methodName,
            returnType: returnType,
            parameterTypes: params,
          ),
        );
      }

      // 5. Parse Class Defs
      classes.clear();
      for (int i = 0; i < classDefsSize; i++) {
        final classOff = classDefsOff + i * 32;
        final classIdx = _byteData.getUint32(classOff, Endian.little);
        final accessFlags = _byteData.getUint32(classOff + 4, Endian.little);
        final superclassIdx = _byteData.getUint32(classOff + 8, Endian.little);
        final interfacesOff = _byteData.getUint32(classOff + 12, Endian.little);
        final classDataOff = _byteData.getUint32(classOff + 24, Endian.little);

        final className = classIdx < types.length ? types[classIdx] : 'LUnknownClass_$i;';
        final superClassName = (superclassIdx != 0xFFFFFFFF && superclassIdx < types.length)
            ? types[superclassIdx]
            : '';

        final interfaces = <String>[];
        if (interfacesOff != 0 && interfacesOff + 4 <= bytes.length) {
          final count = _byteData.getUint32(interfacesOff, Endian.little);
          for (int k = 0; k < count; k++) {
            final tIdx = _byteData.getUint16(interfacesOff + 4 + k * 2, Endian.little);
            if (tIdx < types.length) interfaces.add(types[tIdx]);
          }
        }

        final directMethods = <DexMethodDef>[];
        final virtualMethods = <DexMethodDef>[];

        if (classDataOff != 0 && classDataOff < bytes.length) {
          _parseClassData(classDataOff, directMethods, virtualMethods);
        }

        classes.add(
          DexClassDef(
            className: className,
            accessFlags: accessFlags,
            superClassName: superClassName,
            interfaces: interfaces,
            directMethods: directMethods,
            virtualMethods: virtualMethods,
          ),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void _parseClassData(
    int offset,
    List<DexMethodDef> directMethods,
    List<DexMethodDef> virtualMethods,
  ) {
    int cur = offset;
    final staticFieldsSize = _readUleb128(cur);
    cur = staticFieldsSize.nextOffset;

    final instanceFieldsSize = _readUleb128(cur);
    cur = instanceFieldsSize.nextOffset;

    final directMethodsSize = _readUleb128(cur);
    cur = directMethodsSize.nextOffset;

    final virtualMethodsSize = _readUleb128(cur);
    cur = virtualMethodsSize.nextOffset;

    // Skip static fields
    for (int i = 0; i < staticFieldsSize.value; i++) {
      cur = _readUleb128(cur).nextOffset; // field_idx_diff
      cur = _readUleb128(cur).nextOffset; // access_flags
    }

    // Skip instance fields
    for (int i = 0; i < instanceFieldsSize.value; i++) {
      cur = _readUleb128(cur).nextOffset; // field_idx_diff
      cur = _readUleb128(cur).nextOffset; // access_flags
    }

    // Direct methods
    int methodIdx = 0;
    for (int i = 0; i < directMethodsSize.value; i++) {
      final diff = _readUleb128(cur);
      cur = diff.nextOffset;
      methodIdx += diff.value;

      final flags = _readUleb128(cur);
      cur = flags.nextOffset;

      final codeOff = _readUleb128(cur);
      cur = codeOff.nextOffset;

      DexCodeItem? codeItem;
      if (codeOff.value != 0 && codeOff.value + 16 <= bytes.length) {
        codeItem = _parseCodeItem(codeOff.value);
      }

      if (methodIdx < methods.length) {
        directMethods.add(
          DexMethodDef(
            methodRef: methods[methodIdx],
            accessFlags: flags.value,
            codeItem: codeItem,
          ),
        );
      }
    }

    // Virtual methods
    methodIdx = 0;
    for (int i = 0; i < virtualMethodsSize.value; i++) {
      final diff = _readUleb128(cur);
      cur = diff.nextOffset;
      methodIdx += diff.value;

      final flags = _readUleb128(cur);
      cur = flags.nextOffset;

      final codeOff = _readUleb128(cur);
      cur = codeOff.nextOffset;

      DexCodeItem? codeItem;
      if (codeOff.value != 0 && codeOff.value + 16 <= bytes.length) {
        codeItem = _parseCodeItem(codeOff.value);
      }

      if (methodIdx < methods.length) {
        virtualMethods.add(
          DexMethodDef(
            methodRef: methods[methodIdx],
            accessFlags: flags.value,
            codeItem: codeItem,
          ),
        );
      }
    }
  }

  DexCodeItem _parseCodeItem(int codeOffset) {
    final registersSize = _byteData.getUint16(codeOffset, Endian.little);
    final insSize = _byteData.getUint16(codeOffset + 2, Endian.little);
    final outsSize = _byteData.getUint16(codeOffset + 4, Endian.little);
    final insnsSize = _byteData.getUint32(codeOffset + 12, Endian.little);

    final insnsOffset = codeOffset + 16;
    final instructions = <DexInstruction>[];
    final stringsReferenced = <String>[];
    final methodsInvoked = <DexMethodRef>[];

    int pc = 0;
    while (pc < insnsSize) {
      final insnByteOff = insnsOffset + pc * 2;
      if (insnByteOff + 2 > bytes.length) break;

      final rawOp = _byteData.getUint16(insnByteOff, Endian.little);
      final opcode = rawOp & 0xFF;

      int lengthInCodeUnits = 1;
      String smali = 'unknown_op_$opcode';
      DexMethodRef? targetMethod;
      String? stringConst;
      String? targetType;
      DexFieldRef? targetField;
      List<int> insnRegisters = [];
      int? destReg;

      switch (opcode) {
        case 0x00: // nop
          smali = 'nop';
          lengthInCodeUnits = 1;
          break;
        case 0x01: // move
        case 0x04: // move-wide
        case 0x07: // move-object
          destReg = (rawOp >> 8) & 0x0F;
          final src = (rawOp >> 12) & 0x0F;
          insnRegisters = [src];
          smali = '${opcode == 0x07 ? "move-object" : (opcode == 0x04 ? "move-wide" : "move")} v$destReg, v$src';
          lengthInCodeUnits = 1;
          break;
        case 0x02: // move/from16
        case 0x08: // move-object/from16
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final src = _byteData.getUint16(insnByteOff + 2, Endian.little);
            insnRegisters = [src];
            smali = '${opcode == 0x08 ? "move-object/from16" : "move/from16"} v$destReg, v$src';
            lengthInCodeUnits = 2;
          }
          break;
        case 0x0a: // move-result
        case 0x0b: // move-result-wide
        case 0x0c: // move-result-object
        case 0x0d: // move-exception
          destReg = (rawOp >> 8) & 0xFF;
          final mName = opcode == 0x0c
              ? 'move-result-object'
              : (opcode == 0x0d ? 'move-exception' : (opcode == 0x0b ? 'move-result-wide' : 'move-result'));
          smali = '$mName v$destReg';
          lengthInCodeUnits = 1;
          break;
        case 0x0e: // return-void
          smali = 'return-void';
          lengthInCodeUnits = 1;
          break;
        case 0x0f: // return
        case 0x10: // return-wide
        case 0x11: // return-object
          final reg = (rawOp >> 8) & 0xFF;
          insnRegisters = [reg];
          smali = '${opcode == 0x11 ? "return-object" : "return"} v$reg';
          lengthInCodeUnits = 1;
          break;
        case 0x12: // const/4
          destReg = (rawOp >> 8) & 0x0F;
          final lit = (rawOp >> 12) & 0x0F;
          smali = 'const/4 v$destReg, $lit';
          lengthInCodeUnits = 1;
          break;
        case 0x13: // const/16
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final val = _byteData.getInt16(insnByteOff + 2, Endian.little);
            smali = 'const/16 v$destReg, $val';
            lengthInCodeUnits = 2;
          }
          break;
        case 0x14: // const
          if (pc + 2 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final val = _byteData.getInt32(insnByteOff + 2, Endian.little);
            smali = 'const v$destReg, $val';
            lengthInCodeUnits = 3;
          }
          break;
        case 0x1a: // const-string
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final stringIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            if (stringIdx < strings.length) {
              stringConst = strings[stringIdx];
              stringsReferenced.add(stringConst);
              final escaped = stringConst.replaceAll('\n', '\\n').replaceAll('\r', '');
              smali = 'const-string v$destReg, "$escaped"';
            } else {
              smali = 'const-string v$destReg, string@$stringIdx';
            }
            lengthInCodeUnits = 2;
          }
          break;
        case 0x1b: // const-string/jumbo
          if (pc + 2 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final stringIdx = _byteData.getUint32(insnByteOff + 2, Endian.little);
            if (stringIdx < strings.length) {
              stringConst = strings[stringIdx];
              stringsReferenced.add(stringConst);
              final escaped = stringConst.replaceAll('\n', '\\n').replaceAll('\r', '');
              smali = 'const-string/jumbo v$destReg, "$escaped"';
            } else {
              smali = 'const-string/jumbo v$destReg, string@$stringIdx';
            }
            lengthInCodeUnits = 3;
          }
          break;
        case 0x1c: // const-class
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final typeIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            targetType = typeIdx < types.length ? types[typeIdx] : 'type@$typeIdx';
            smali = 'const-class v$destReg, $targetType';
            lengthInCodeUnits = 2;
          }
          break;
        case 0x1f: // check-cast
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final typeIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            targetType = typeIdx < types.length ? types[typeIdx] : 'type@$typeIdx';
            smali = 'check-cast v$destReg, $targetType';
            lengthInCodeUnits = 2;
          }
          break;
        case 0x22: // new-instance
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final typeIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            targetType = typeIdx < types.length ? types[typeIdx] : 'type@$typeIdx';
            smali = 'new-instance v$destReg, $targetType';
            lengthInCodeUnits = 2;
          }
          break;
        case 0x52: // iget
        case 0x54: // iget-object
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0x0F;
            final objReg = (rawOp >> 12) & 0x0F;
            insnRegisters = [objReg];
            final fieldIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            if (fieldIdx < fields.length) {
              targetField = fields[fieldIdx];
              smali = '${opcode == 0x54 ? "iget-object" : "iget"} v$destReg, v$objReg, ${targetField.fullSignature}';
            } else {
              smali = '${opcode == 0x54 ? "iget-object" : "iget"} v$destReg, v$objReg, field@$fieldIdx';
            }
            lengthInCodeUnits = 2;
          }
          break;
        case 0x59: // iput
        case 0x5b: // iput-object
          if (pc + 1 < insnsSize) {
            final valReg = (rawOp >> 8) & 0x0F;
            final objReg = (rawOp >> 12) & 0x0F;
            insnRegisters = [valReg, objReg];
            final fieldIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            if (fieldIdx < fields.length) {
              targetField = fields[fieldIdx];
              smali = '${opcode == 0x5b ? "iput-object" : "iput"} v$valReg, v$objReg, ${targetField.fullSignature}';
            } else {
              smali = '${opcode == 0x5b ? "iput-object" : "iput"} v$valReg, v$objReg, field@$fieldIdx';
            }
            lengthInCodeUnits = 2;
          }
          break;
        case 0x60: // sget
        case 0x62: // sget-object
          if (pc + 1 < insnsSize) {
            destReg = (rawOp >> 8) & 0xFF;
            final fieldIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            if (fieldIdx < fields.length) {
              targetField = fields[fieldIdx];
              smali = '${opcode == 0x62 ? "sget-object" : "sget"} v$destReg, ${targetField.fullSignature}';
            } else {
              smali = '${opcode == 0x62 ? "sget-object" : "sget"} v$destReg, field@$fieldIdx';
            }
            lengthInCodeUnits = 2;
          }
          break;
        case 0x67: // sput
        case 0x69: // sput-object
          if (pc + 1 < insnsSize) {
            final valReg = (rawOp >> 8) & 0xFF;
            insnRegisters = [valReg];
            final fieldIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            if (fieldIdx < fields.length) {
              targetField = fields[fieldIdx];
              smali = '${opcode == 0x69 ? "sput-object" : "sput"} v$valReg, ${targetField.fullSignature}';
            } else {
              smali = '${opcode == 0x69 ? "sput-object" : "sput"} v$valReg, field@$fieldIdx';
            }
            lengthInCodeUnits = 2;
          }
          break;
        case 0x6e: // invoke-virtual
        case 0x6f: // invoke-super
        case 0x70: // invoke-direct
        case 0x71: // invoke-static
        case 0x72: // invoke-interface
          if (pc + 2 < insnsSize) {
            final opName = _getInvokeName(opcode);
            final count = (rawOp >> 12) & 0x0F;
            final regG = (rawOp >> 8) & 0x0F;
            final methodIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            final regWord = _byteData.getUint16(insnByteOff + 4, Endian.little);
            final regC = regWord & 0x0F;
            final regD = (regWord >> 4) & 0x0F;
            final regE = (regWord >> 8) & 0x0F;
            final regF = (regWord >> 12) & 0x0F;

            final regs = <int>[];
            if (count >= 1) regs.add(regC);
            if (count >= 2) regs.add(regD);
            if (count >= 3) regs.add(regE);
            if (count >= 4) regs.add(regF);
            if (count == 5) regs.add(regG);
            insnRegisters = regs;

            if (methodIdx < methods.length) {
              targetMethod = methods[methodIdx];
              methodsInvoked.add(targetMethod);
              final regList = regs.map((r) => 'v$r').join(', ');
              smali = '$opName {$regList}, ${targetMethod.fullSignature}';
            } else {
              final regList = regs.map((r) => 'v$r').join(', ');
              smali = '$opName {$regList}, method@$methodIdx';
            }
            lengthInCodeUnits = 3;
          }
          break;
        case 0x74: // invoke-virtual/range
        case 0x75: // invoke-super/range
        case 0x76: // invoke-direct/range
        case 0x77: // invoke-static/range
        case 0x78: // invoke-interface/range
          if (pc + 2 < insnsSize) {
            final opName = '${_getInvokeName(opcode - 6)}/range';
            final count = (rawOp >> 8) & 0xFF;
            final methodIdx = _byteData.getUint16(insnByteOff + 2, Endian.little);
            final firstReg = _byteData.getUint16(insnByteOff + 4, Endian.little);

            final regs = <int>[];
            for (int r = 0; r < count; r++) {
              regs.add(firstReg + r);
            }
            insnRegisters = regs;

            if (methodIdx < methods.length) {
              targetMethod = methods[methodIdx];
              methodsInvoked.add(targetMethod);
              final lastReg = firstReg + count - 1;
              smali = '$opName {v$firstReg..v$lastReg}, ${targetMethod.fullSignature}';
            } else {
              final lastReg = firstReg + count - 1;
              smali = '$opName {v$firstReg..v$lastReg}, method@$methodIdx';
            }
            lengthInCodeUnits = 3;
          }
          break;
        default:
          lengthInCodeUnits = _estimateInsnLength(opcode);
          smali = 'op_0x${opcode.toRadixString(16).padLeft(2, '0')}';
          break;
      }

      instructions.add(
        DexInstruction(
          opcode: opcode,
          byteOffset: insnByteOff,
          byteLength: lengthInCodeUnits * 2,
          smaliText: smali,
          targetMethod: targetMethod,
          stringConstant: stringConst,
          targetType: targetType,
          targetField: targetField,
          registers: insnRegisters,
          destRegister: destReg,
        ),
      );

      pc += lengthInCodeUnits;
    }

    return DexCodeItem(
      codeOffset: codeOffset,
      registersSize: registersSize,
      insSize: insSize,
      outsSize: outsSize,
      insnsSize: insnsSize,
      insnsOffset: insnsOffset,
      instructions: instructions,
      stringsReferenced: stringsReferenced,
      methodsInvoked: methodsInvoked,
    );
  }

  String _getInvokeName(int opcode) {
    switch (opcode) {
      case 0x6e:
        return 'invoke-virtual';
      case 0x6f:
        return 'invoke-super';
      case 0x70:
        return 'invoke-direct';
      case 0x71:
        return 'invoke-static';
      case 0x72:
        return 'invoke-interface';
      default:
        return 'invoke';
    }
  }

  int _estimateInsnLength(int opcode) {
    // Standard Dalvik instruction formats length in 16-bit code units
    if (opcode >= 0x00 && opcode <= 0x12) return 1;
    if (opcode >= 0x13 && opcode <= 0x1c) return 2;
    if (opcode >= 0x1d && opcode <= 0x27) return 2;
    if (opcode >= 0x28 && opcode <= 0x29) return (opcode == 0x28) ? 1 : 2;
    if (opcode == 0x2a || opcode == 0x2b) return 3;
    if (opcode >= 0x2c && opcode <= 0x31) return 1;
    if (opcode >= 0x32 && opcode <= 0x3d) return 2;
    if (opcode >= 0x3e && opcode <= 0x43) return 1;
    if (opcode >= 0x44 && opcode <= 0x51) return 2;
    if (opcode >= 0x52 && opcode <= 0x6d) return 2;
    if (opcode >= 0x6e && opcode <= 0x78) return 3;
    if (opcode >= 0x7b && opcode <= 0x8f) return 1;
    if (opcode >= 0x90 && opcode <= 0xaf) return 2;
    if (opcode >= 0xb0 && opcode <= 0xcf) return 1;
    if (opcode >= 0xd0 && opcode <= 0xe2) return 2;
    return 1;
  }

  /// Patches a specific instruction range in the DEX with NOP opcodes (0x0000)
  void patchInstructionWithNop(int byteOffset, int byteLength) {
    for (int i = 0; i < byteLength; i++) {
      bytes[byteOffset + i] = 0x00;
    }
  }

  /// Safely neutralizes an instruction:
  /// If followed by move-result, move-result-wide, or move-result-object,
  /// neutralizes both the invoke and the move-result with a const/4 (or const-wide/16)
  /// initializing the target register to 0/null to avoid ART VerifyError.
  void patchInstructionSafely({
    required int byteOffset,
    required int byteLength,
    required DexCodeItem codeItem,
  }) {
    // Find instruction in codeItem
    final insnIndex = codeItem.instructions.indexWhere((i) => i.byteOffset == byteOffset);
    if (insnIndex == -1) {
      patchInstructionWithNop(byteOffset, byteLength);
      return;
    }

    final currentInsn = codeItem.instructions[insnIndex];
    final nextInsn = (insnIndex + 1 < codeItem.instructions.length)
        ? codeItem.instructions[insnIndex + 1]
        : null;

    // Check if next instruction is move-result (0x0a), move-result-wide (0x0b), or move-result-object (0x0c)
    if (nextInsn != null && (nextInsn.opcode == 0x0a || nextInsn.opcode == 0x0b || nextInsn.opcode == 0x0c)) {
      final totalBytes = currentInsn.byteLength + nextInsn.byteLength;
      final destReg = nextInsn.destRegister ?? (nextInsn.registers.isNotEmpty ? nextInsn.registers.first : 0);

      if (nextInsn.opcode == 0x0b) {
        // move-result-wide: write const-wide/16 destReg, 0 (4 bytes: 0x16, destReg, 0x00, 0x00)
        bytes[byteOffset] = 0x16;
        bytes[byteOffset + 1] = destReg & 0xFF;
        bytes[byteOffset + 2] = 0x00;
        bytes[byteOffset + 3] = 0x00;
        for (int i = 4; i < totalBytes; i++) {
          bytes[byteOffset + i] = 0x00;
        }
      } else {
        // move-result or move-result-object: write const/4 destReg, 0 (2 bytes: 0x12, destReg)
        if (destReg < 16) {
          bytes[byteOffset] = 0x12;
          bytes[byteOffset + 1] = (destReg & 0x0F) << 4; // const/4 destReg, 0
          for (int i = 2; i < totalBytes; i++) {
            bytes[byteOffset + i] = 0x00;
          }
        } else {
          // const/16 destReg, 0 (4 bytes)
          bytes[byteOffset] = 0x13;
          bytes[byteOffset + 1] = destReg & 0xFF;
          bytes[byteOffset + 2] = 0x00;
          bytes[byteOffset + 3] = 0x00;
          for (int i = 4; i < totalBytes; i++) {
            bytes[byteOffset + i] = 0x00;
          }
        }
      }
    } else {
      // Normal NOP padding
      patchInstructionWithNop(byteOffset, byteLength);
    }
  }

  /// Patches a method entry to return immediately with type-safety:
  /// - Void methods: return-void (0x000e)
  /// - Primitive methods (int, boolean, byte, char, short): const/4 v0, 0 + return v0 (0x000f)
  /// - Wide methods (long, double): const-wide/16 v0, 0 + return-wide v0 (0x0010)
  /// - Object / Array methods: const/4 v0, 0 + return-object v0 (0x0011)
  /// This completely prevents ART VerifyError on startup!
  void patchMethodSafely({
    required int codeOffset,
    required int insnsStartByteOffset,
    required int totalInsnsBytes,
    required String returnType,
    required int registersSize,
  }) {
    if (totalInsnsBytes < 2) return;

    if (returnType == 'V') {
      // return-void
      bytes[insnsStartByteOffset] = 0x0e;
      bytes[insnsStartByteOffset + 1] = 0x00;
      for (int i = 2; i < totalInsnsBytes; i++) {
        bytes[insnsStartByteOffset + i] = 0x00;
      }
    } else if (returnType == 'Z' || returnType == 'B' || returnType == 'S' || returnType == 'C' || returnType == 'I') {
      // Ensure at least 1 register
      if (registersSize == 0 && codeOffset + 2 <= bytes.length) {
        _byteData.setUint16(codeOffset, 1, Endian.little);
      }
      if (totalInsnsBytes >= 4) {
        // const/4 v0, 0
        bytes[insnsStartByteOffset] = 0x12;
        bytes[insnsStartByteOffset + 1] = 0x00;
        // return v0
        bytes[insnsStartByteOffset + 2] = 0x0f;
        bytes[insnsStartByteOffset + 3] = 0x00;
        for (int i = 4; i < totalInsnsBytes; i++) {
          bytes[insnsStartByteOffset + i] = 0x00;
        }
      }
    } else if (returnType == 'J' || returnType == 'D') {
      // Ensure at least 2 registers
      if (registersSize < 2 && codeOffset + 2 <= bytes.length) {
        _byteData.setUint16(codeOffset, 2, Endian.little);
      }
      if (totalInsnsBytes >= 6) {
        // const-wide/16 v0, 0
        bytes[insnsStartByteOffset] = 0x16;
        bytes[insnsStartByteOffset + 1] = 0x00;
        bytes[insnsStartByteOffset + 2] = 0x00;
        bytes[insnsStartByteOffset + 3] = 0x00;
        // return-wide v0
        bytes[insnsStartByteOffset + 4] = 0x10;
        bytes[insnsStartByteOffset + 5] = 0x00;
        for (int i = 6; i < totalInsnsBytes; i++) {
          bytes[insnsStartByteOffset + i] = 0x00;
        }
      }
    } else {
      // Object or Array (L...; or [...])
      if (registersSize == 0 && codeOffset + 2 <= bytes.length) {
        _byteData.setUint16(codeOffset, 1, Endian.little);
      }
      if (totalInsnsBytes >= 4) {
        // const/4 v0, 0
        bytes[insnsStartByteOffset] = 0x12;
        bytes[insnsStartByteOffset + 1] = 0x00;
        // return-object v0
        bytes[insnsStartByteOffset + 2] = 0x11;
        bytes[insnsStartByteOffset + 3] = 0x00;
        for (int i = 4; i < totalInsnsBytes; i++) {
          bytes[insnsStartByteOffset + i] = 0x00;
        }
      }
    }
  }

  /// Patches a method entry to return void immediately (legacy wrapper)
  void patchMethodWithReturnVoid(int insnsStartByteOffset, int totalInsnsBytes) {
    patchMethodSafely(
      codeOffset: 0,
      insnsStartByteOffset: insnsStartByteOffset,
      totalInsnsBytes: totalInsnsBytes,
      returnType: 'V',
      registersSize: 1,
    );
  }

  /// Comprehensive structural validation of the DEX file
  DexValidationResult validateDexStructure() {
    final errors = <String>[];
    if (bytes.length < 0x70) {
      return DexValidationResult(isValid: false, errors: ['DEX length too short (< 112 bytes)']);
    }
    // Check magic
    if (bytes[0] != 0x64 || bytes[1] != 0x65 || bytes[2] != 0x78 || bytes[3] != 0x0a) {
      errors.add('Invalid DEX magic bytes');
    }
    // Check Adler-32
    final expectedAdler = _byteData.getUint32(8, Endian.little);
    final actualAdler = _computeAdler32(bytes, 12, bytes.length - 12);
    if (expectedAdler != actualAdler) {
      errors.add('Adler-32 checksum mismatch: expected 0x${expectedAdler.toRadixString(16)}, got 0x${actualAdler.toRadixString(16)}');
    }
    // Check SHA-1
    final expectedSha1 = bytes.sublist(12, 32);
    final actualSha1 = sha1.convert(bytes.sublist(32)).bytes;
    for (int i = 0; i < 20; i++) {
      if (expectedSha1[i] != actualSha1[i]) {
        errors.add('SHA-1 signature mismatch in DEX header');
        break;
      }
    }
    // Validate classes and methods can be traversed
    try {
      for (final cls in classes) {
        for (final m in cls.allMethods) {
          if (!m.hasCode) continue;
          final code = m.codeItem!;
          if (code.insnsOffset + code.insnsSize * 2 > bytes.length) {
            errors.add('Method ${cls.className}->${m.methodRef.methodName} instructions overflow DEX bounds');
          }
        }
      }
    } catch (e) {
      errors.add('Exception validating classes and methods: $e');
    }

    return DexValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      classesCount: classes.length,
      methodsCount: methods.length,
      stringsCount: strings.length,
    );
  }

  /// Recalculates the Adler-32 checksum and SHA-1 signature in the DEX header
  Uint8List recalculateChecksums() {
    // 1. Recalculate SHA-1 over bytes 32..end
    final contentForSha1 = bytes.sublist(32);
    final sha1Digest = sha1.convert(contentForSha1).bytes;
    for (int i = 0; i < 20; i++) {
      bytes[12 + i] = sha1Digest[i];
    }

    // 2. Recalculate Adler-32 over bytes 12..end
    final adler = _computeAdler32(bytes, 12, bytes.length - 12);
    _byteData.setUint32(8, adler, Endian.little);

    return bytes;
  }

  int _computeAdler32(Uint8List data, int offset, int length) {
    int a = 1;
    int b = 0;
    const mod = 65521;
    for (int i = offset; i < offset + length; i++) {
      a = (a + data[i]) % mod;
      b = (b + a) % mod;
    }
    return (b << 16) | a;
  }

  String _readString(int offset) {
    if (offset >= bytes.length) return '';
    final uleb = _readUleb128(offset);
    int cur = uleb.nextOffset;
    final buffer = <int>[];
    while (cur < bytes.length && bytes[cur] != 0) {
      buffer.add(bytes[cur]);
      cur++;
    }
    try {
      return utf8.decode(buffer, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(buffer);
    }
  }

  _UlebResult _readUleb128(int offset) {
    int result = 0;
    int cur = offset;
    int shift = 0;
    while (cur < bytes.length) {
      final b = bytes[cur++];
      result |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return _UlebResult(value: result, nextOffset: cur);
  }
}

class DexValidationResult {
  final bool isValid;
  final List<String> errors;
  final int classesCount;
  final int methodsCount;
  final int stringsCount;

  const DexValidationResult({
    required this.isValid,
    this.errors = const [],
    this.classesCount = 0,
    this.methodsCount = 0,
    this.stringsCount = 0,
  });
}

class _UlebResult {
  final int value;
  final int nextOffset;
  const _UlebResult({required this.value, required this.nextOffset});
}

extension _ByteDataExt on ByteData {
  int getUint88(int offset, Endian endian) => getUint32(offset, endian);
}
