import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class SecurityService {
  // 1. PIN Obfuscation / Verification
  String encryptPin(String pin) {
    if (pin.isEmpty) return '';
    final bytes = utf8.encode(pin.trim());
    final obfuscated = bytes.map((b) => b ^ 99).toList(); // XOR seed 99
    return base64.encode(obfuscated);
  }

  bool verifyPin(String inputPin, String obfuscatedPin) {
    if (inputPin.isEmpty || obfuscatedPin.isEmpty) return false;
    final encrypted = encryptPin(inputPin);
    return encrypted == obfuscatedPin;
  }

  // 2. Real/Simulated Permissions Manager
  Future<Map<String, String>> checkPermissions() async {
    final statusMap = <String, String>{};
    
    // Helper to query and map permissions safely on mobile/desktop fallbacks
    Future<void> check(String name, Permission perm) async {
      try {
        final status = await perm.status;
        statusMap[name] = status.name;
      } catch (_) {
        statusMap[name] = 'granted'; // Default to granted on unsupported desktop platform fallbacks
      }
    }

    await check('Microphone', Permission.microphone);
    await check('Storage', Permission.storage);
    await check('Notifications', Permission.notification);
    
    return statusMap;
  }

  Future<bool> requestPermission(String name) async {
    Permission? perm;
    if (name == 'Microphone') perm = Permission.microphone;
    if (name == 'Storage') perm = Permission.storage;
    if (name == 'Notifications') perm = Permission.notification;

    if (perm != null) {
      try {
        final status = await perm.request();
        return status.isGranted;
      } catch (_) {
        return true; // fallback for non-supported desktop platforms
      }
    }
    return false;
  }

  // 3. Encrypted Data Export & Backup Restore
  String encryptBackup(String plainJson, String password) {
    final bytes = utf8.encode(plainJson);
    final keyBytes = utf8.encode(password.isNotEmpty ? password : 'default_nexa_key');
    final result = List<int>.filled(bytes.length, 0);
    
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return base64.encode(result);
  }

  String decryptBackup(String encryptedBase64, String password) {
    final bytes = base64.decode(encryptedBase64);
    final keyBytes = utf8.encode(password.isNotEmpty ? password : 'default_nexa_key');
    final result = List<int>.filled(bytes.length, 0);
    
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return utf8.decode(result);
  }

  // 4. Data Purge (Delete all records and files)
  Future<void> purgeAllAppData(String downloadDir) async {
    // 1. Wipe all known Hive boxes
    final boxesToWipe = [
      'modelsBox',
      'settingsBox',
      'downloadsBox',
      'installedModelsBox',
      'chatSessionsBox',
      'benchmarksBox',
      'securityBox',
    ];

    for (final boxName in boxesToWipe) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
        } else {
          final box = await Hive.openBox(boxName);
          await box.clear();
        }
      } catch (_) {}
    }

    // 2. Purge local download folder binaries
    if (downloadDir.isNotEmpty && downloadDir != '/localmind/models') {
      try {
        final directory = Directory(downloadDir);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      } catch (_) {}
    }
  }
}
