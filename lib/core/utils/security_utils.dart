import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

class SecurityUtils {
  /// Computes the SHA-256 checksum of raw bytes.
  static String computeSha256(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Computes the SHA-256 checksum of a string.
  static String computeSha256String(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  /// Validates an archive structure against zip-slip vulnerability.
  /// Rejects any path with '..', leading slashes, or drive letters.
  static bool validateZipStructure(Archive archive) {
    for (final file in archive.files) {
      final name = file.name;
      if (name.contains('..') ||
          name.startsWith('/') ||
          name.startsWith('\\') ||
          RegExp(r'^[a-zA-Z]:').hasMatch(name)) {
        return false; // Malicious zip-slip path detected
      }
    }
    return true;
  }

  /// Verifies if a given file has the standard ZIP/APK magic number (PK\x03\x04).
  static bool hasZipMagicBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }
}
