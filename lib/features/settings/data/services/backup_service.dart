import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:localmind_ai/features/settings/domain/entities/backup_metadata.dart';
import 'package:localmind_ai/features/settings/domain/repositories/backup_repository.dart';

class BackupService {
  final BackupRepository _backupRepository;

  BackupService(this._backupRepository);

  // List of all static box names in the application
  static const List<String> staticBoxes = [
    'settingsBox',
    'downloadsBox',
    'installedModelsBox',
    'chatSessionsBox',
    'ragFoldersBox',
    'ragDocumentsBox',
    'knowledgeNotesBox',
    'knowledgeCollectionsBox',
    'multiModelSessionsBox',
    'chatFoldersBox',
    'promptTemplatesBox',
  ];

  // Helper to open a box if it is not open
  Future<Box> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Aggregates all Hive database records into a single JSON String.
  Future<String> serializeAllData() async {
    final Map<String, dynamic> dbDump = {};

    // 1. Serialize static boxes
    for (final boxName in staticBoxes) {
      final box = await _openBox(boxName);
      final Map<String, dynamic> boxData = {};
      for (final key in box.keys) {
        boxData[key.toString()] = box.get(key);
      }
      dbDump[boxName] = boxData;
    }

    // 2. Scan and serialize dynamic session boxes
    // Standard chat message boxes: messagesBox_<sessionId>
    final chatSessionsBox = await _openBox('chatSessionsBox');
    for (final sessionId in chatSessionsBox.keys) {
      final boxName = 'messagesBox_$sessionId';
      final box = await _openBox(boxName);
      final Map<String, dynamic> boxData = {};
      for (final key in box.keys) {
        boxData[key.toString()] = box.get(key);
      }
      dbDump[boxName] = boxData;
    }

    // RAG chunk boxes: ragChunksBox_<docId>
    final ragDocsBox = await _openBox('ragDocumentsBox');
    for (final docId in ragDocsBox.keys) {
      final boxName = 'ragChunksBox_$docId';
      final box = await _openBox(boxName);
      final Map<String, dynamic> boxData = {};
      for (final key in box.keys) {
        boxData[key.toString()] = box.get(key);
      }
      dbDump[boxName] = boxData;
    }

    // Comparison chat message boxes: multiModelMessagesBox_<sessionId>
    final multiSessionsBox = await _openBox('multiModelSessionsBox');
    for (final sessionId in multiSessionsBox.keys) {
      final boxName = 'multiModelMessagesBox_$sessionId';
      final box = await _openBox(boxName);
      final Map<String, dynamic> boxData = {};
      for (final key in box.keys) {
        boxData[key.toString()] = box.get(key);
      }
      dbDump[boxName] = boxData;
    }

    final backupWrapper = {
      'app': 'LocalMind AI',
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'database': dbDump,
    };

    return jsonEncode(backupWrapper);
  }

  /// Restores a JSON backup payload with the selected conflict resolution strategy.
  Future<void> deserializeAndRestore(String jsonString, String strategy) async {
    final Map<String, dynamic> wrapper = jsonDecode(jsonString) as Map<String, dynamic>;
    if (wrapper['app'] != 'LocalMind AI') {
      throw const FormatException('Invalid backup payload format (App identity mismatch)');
    }

    final Map<String, dynamic> dbDump = wrapper['database'] as Map<String, dynamic>;

    if (strategy == 'overwrite') {
      // Clear all existing data
      for (final boxName in staticBoxes) {
        final box = await _openBox(boxName);
        await box.clear();
      }

      // Also clear all currently open dynamic boxes we can find
      final activeChatSessions = await _openBox('chatSessionsBox');
      for (final key in activeChatSessions.keys) {
        final box = await _openBox('messagesBox_$key');
        await box.clear();
      }
      final activeRagDocs = await _openBox('ragDocumentsBox');
      for (final key in activeRagDocs.keys) {
        final box = await _openBox('ragChunksBox_$key');
        await box.clear();
      }
      final activeCompareSessions = await _openBox('multiModelSessionsBox');
      for (final key in activeCompareSessions.keys) {
        final box = await _openBox('multiModelMessagesBox_$key');
        await box.clear();
      }

      // Restore everything directly
      for (final boxName in dbDump.keys) {
        final box = await _openBox(boxName);
        final boxData = dbDump[boxName] as Map<String, dynamic>;
        for (final entry in boxData.entries) {
          await box.put(entry.key, entry.value);
        }
      }
    } else if (strategy == 'merge_newer') {
      // Merge keeping newer timestamps
      for (final boxName in dbDump.keys) {
        final box = await _openBox(boxName);
        final boxData = dbDump[boxName] as Map<String, dynamic>;

        for (final entry in boxData.entries) {
          final backupItem = entry.value;
          final localItem = box.get(entry.key);

          if (localItem == null) {
            await box.put(entry.key, backupItem);
          } else {
            final backupTime = _getTimestamp(backupItem);
            final localTime = _getTimestamp(localItem);

            if (backupTime != null && localTime != null) {
              if (backupTime.isAfter(localTime)) {
                await box.put(entry.key, backupItem);
              }
            } else {
              // Fallback to overwriting if no timestamp exists
              await box.put(entry.key, backupItem);
            }
          }
        }
      }
    } else if (strategy == 'merge_keep_both') {
      // Merge keeping both (generates duplicate copies of conflicting sessions/notes)
      final Set<String> dupedSessions = {};
      final Set<String> dupedRagDocs = {};

      for (final boxName in dbDump.keys) {
        final boxData = dbDump[boxName] as Map<String, dynamic>;

        // We process static session and notes tables first to map IDs
        if (boxName == 'chatSessionsBox' || 
            boxName == 'knowledgeNotesBox' || 
            boxName == 'promptTemplatesBox' ||
            boxName == 'multiModelSessionsBox') {
          
          final box = await _openBox(boxName);

          for (final entry in boxData.entries) {
            final localItem = box.get(entry.key);
            if (localItem == null) {
              await box.put(entry.key, entry.value);
            } else {
              // Conflicting metadata item, duplicate it
              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(entry.value as Map);
              final newId = '${entry.key}_restored_${DateTime.now().millisecondsSinceEpoch}';
              itemMap['id'] = newId;

              // Append suffix to title
              if (itemMap.containsKey('title')) {
                itemMap['title'] = '${itemMap['title']} (Restored)';
              } else if (itemMap.containsKey('name')) {
                itemMap['name'] = '${itemMap['name']} (Restored)';
              } else if (itemMap.containsKey('localName')) {
                itemMap['localName'] = '${itemMap['localName']} (Restored)';
              }

              await box.put(newId, itemMap);

              // Record map to duplicate corresponding dynamic messages or chunks
              if (boxName == 'chatSessionsBox') {
                dupedSessions.add('${entry.key}::$newId');
              } else if (boxName == 'multiModelSessionsBox') {
                dupedSessions.add('compare_${entry.key}::compare_$newId');
              }
            }
          }
        }
      }

      // Process all other static tables (folders, documents, settings)
      for (final boxName in dbDump.keys) {
        if (boxName == 'chatSessionsBox' || 
            boxName == 'knowledgeNotesBox' || 
            boxName == 'promptTemplatesBox' ||
            boxName == 'multiModelSessionsBox') {
          continue; // Already processed
        }

        // Skip dynamic messages/chunks boxes since we process them below
        if (boxName.startsWith('messagesBox_') || 
            boxName.startsWith('multiModelMessagesBox_') || 
            boxName.startsWith('ragChunksBox_')) {
          continue;
        }

        final box = await _openBox(boxName);
        final boxData = dbDump[boxName] as Map<String, dynamic>;
        for (final entry in boxData.entries) {
          final localItem = box.get(entry.key);
          if (localItem == null) {
            await box.put(entry.key, entry.value);
          } else {
            // Overwrite basic settings or downloads tasks rather than duplicating them
            await box.put(entry.key, entry.value);
          }
        }
      }

      // Process dynamic boxes
      for (final boxName in dbDump.keys) {
        if (!boxName.startsWith('messagesBox_') && 
            !boxName.startsWith('multiModelMessagesBox_') && 
            !boxName.startsWith('ragChunksBox_')) {
          continue;
        }

        final boxData = dbDump[boxName] as Map<String, dynamic>;

        // Verify if this dynamic box belongs to a duplicated session
        String targetBoxName = boxName;
        bool isDuplicated = false;
        String oldId = '';
        String newId = '';

        if (boxName.startsWith('messagesBox_')) {
          oldId = boxName.replaceFirst('messagesBox_', '');
          final match = dupedSessions.firstWhere(
            (s) => s.startsWith('$oldId::'), 
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            isDuplicated = true;
            newId = match.split('::')[1];
            targetBoxName = 'messagesBox_$newId';
          }
        } else if (boxName.startsWith('multiModelMessagesBox_')) {
          oldId = boxName.replaceFirst('multiModelMessagesBox_', '');
          final match = dupedSessions.firstWhere(
            (s) => s.startsWith('compare_$oldId::compare_'), 
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            isDuplicated = true;
            newId = match.split('::')[1].replaceFirst('compare_', '');
            targetBoxName = 'multiModelMessagesBox_$newId';
          }
        }

        final box = await _openBox(targetBoxName);
        for (final entry in boxData.entries) {
          if (isDuplicated) {
            // If the session itself was duplicated, we might need to map messages
            final Map<String, dynamic> msgMap = Map<String, dynamic>.from(entry.value as Map);
            // Change parent session ID
            if (msgMap.containsKey('sessionId')) {
              msgMap['sessionId'] = newId;
            }
            await box.put(entry.key, msgMap);
          } else {
            await box.put(entry.key, entry.value);
          }
        }
      }
    }
  }

  DateTime? _getTimestamp(dynamic item) {
    if (item is Map) {
      final t = item['updatedAt'] ?? item['timestamp'] ?? item['createdAt'] ?? item['lastUsed'];
      if (t != null) {
        if (t is String) return DateTime.tryParse(t);
        if (t is int) return DateTime.fromMillisecondsSinceEpoch(t);
        if (t is DateTime) return t;
      }
    }
    return null;
  }

  // --- Pure Dart XTEA stream encryption engine ---

  /// Encrypts or decrypts bytes in CTR mode using XTEA.
  List<int> cryptXteaCtr(List<int> data, String password) {
    final key = _deriveKey(password);
    final List<int> result = List<int>.filled(data.length, 0);
    
    final int blocks = (data.length + 7) ~/ 8;
    for (int b = 0; b < blocks; b++) {
      // Create counter block [b, 0]
      final List<int> counterBlock = [b & 0xFFFFFFFF, (b >> 32) & 0xFFFFFFFF];
      _xteaEncrypt(counterBlock, key);
      
      final List<int> keystream = [];
      for (int i = 0; i < 2; i++) {
        keystream.add(counterBlock[i] & 0xFF);
        keystream.add((counterBlock[i] >> 8) & 0xFF);
        keystream.add((counterBlock[i] >> 16) & 0xFF);
        keystream.add((counterBlock[i] >> 24) & 0xFF);
      }
      
      for (int i = 0; i < 8; i++) {
        final int idx = b * 8 + i;
        if (idx < data.length) {
          result[idx] = data[idx] ^ keystream[i];
        }
      }
    }
    return result;
  }

  List<int> _deriveKey(String password) {
    // Basic mixing and stretching to derive 128-bit key from arbitrary password
    final List<int> key = [0x12345678, 0x9ABCDEF0, 0x0FEDCBA9, 0x87654321];
    final bytes = utf8.encode(password);
    for (int i = 0; i < bytes.length; i++) {
      key[i % 4] = (key[i % 4] ^ (bytes[i] << (8 * (i % 4)))) & 0xFFFFFFFF;
      key[i % 4] = (key[i % 4] + 0x9E3779B9) & 0xFFFFFFFF; // Mix Golden Ratio
    }
    return key;
  }

  void _xteaEncrypt(List<int> block, List<int> key) {
    int v0 = block[0];
    int v1 = block[1];
    int sum = 0;
    const int delta = 0x9E3779B9;
    for (int i = 0; i < 32; i++) {
      v0 = (v0 + (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + key[sum & 3])) & 0xFFFFFFFF;
      sum = (sum + delta) & 0xFFFFFFFF;
      v1 = (v1 + (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + key[(sum >> 11) & 3])) & 0xFFFFFFFF;
    }
    block[0] = v0;
    block[1] = v1;
  }

  /// Formats backup data for writing.
  List<int> packageBackup(String jsonString, String? password) {
    if (password != null && password.isNotEmpty) {
      final plaintext = utf8.encode('OK$jsonString');
      final encryptedBytes = cryptXteaCtr(plaintext, password);
      
      final List<int> fileBytes = [];
      fileBytes.addAll(utf8.encode('LMBK_ENC:'));
      fileBytes.addAll(encryptedBytes);
      return fileBytes;
    } else {
      final List<int> fileBytes = [];
      fileBytes.addAll(utf8.encode('LMBK_RAW:'));
      fileBytes.addAll(utf8.encode(jsonString));
      return fileBytes;
    }
  }

  /// Unpackages backup file to retrieve the raw JSON data.
  String unpackageBackup(List<int> fileBytes, String? password) {
    final fileStr = utf8.decode(fileBytes.sublist(0, 9), allowMalformed: true);
    
    if (fileStr == 'LMBK_ENC:') {
      if (password == null || password.isEmpty) {
        throw const FormatException('This backup file is encrypted. Password is required.');
      }
      final encryptedData = fileBytes.sublist(9);
      final decryptedData = cryptXteaCtr(encryptedData, password);
      final decryptedStr = utf8.decode(decryptedData, allowMalformed: true);
      
      if (!decryptedStr.startsWith('OK')) {
        throw const FormatException('Incorrect decryption password.');
      }
      return decryptedStr.substring(2);
    } else if (fileStr.startsWith('LMBK_RAW:')) {
      return utf8.decode(fileBytes.sublist(9));
    } else {
      // Try parsing as raw JSON directly for backward compatibility
      try {
        final decoded = utf8.decode(fileBytes);
        jsonDecode(decoded);
        return decoded;
      } catch (_) {
        throw const FormatException('Unsupported backup file format.');
      }
    }
  }

  /// Runs background scheduled auto-backups.
  Future<void> runAutomaticScheduledBackup() async {
    final schedule = await _backupRepository.getAutoBackupSchedule();
    if (schedule == 'none') return;

    final lastBackup = await _backupRepository.getLastAutoBackupTime();
    final now = DateTime.now();

    bool shouldBackup = false;
    if (lastBackup == null) {
      shouldBackup = true;
    } else {
      final diff = now.difference(lastBackup);
      if (schedule == 'daily' && diff.inDays >= 1) {
        shouldBackup = true;
      } else if (schedule == 'weekly' && diff.inDays >= 7) {
        shouldBackup = true;
      }
    }

    if (shouldBackup) {
      try {
        final jsonString = await serializeAllData();
        final fileBytes = packageBackup(jsonString, null); // Scheduled backups are unencrypted locally
        
        final directory = await getApplicationDocumentsDirectory();
        final backupsDir = Directory('${directory.path}/localmind_backups');
        if (!backupsDir.existsSync()) {
          backupsDir.createSync();
        }

        final fileName = 'localmind_backup_auto_${now.millisecondsSinceEpoch}.lmbk';
        final file = File('${backupsDir.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        // Save metadata
        final metadata = BackupMetadata(
          id: 'auto_${now.millisecondsSinceEpoch}',
          timestamp: now,
          fileName: fileName,
          fileSize: fileBytes.length,
          source: 'local',
          filePath: file.path,
          isEncrypted: false,
        );
        await _backupRepository.saveBackupMetadata(metadata);
        await _backupRepository.saveLastAutoBackupTime(now);
      } catch (e) {
        debugPrint('Automatic scheduled backup failed: $e');
      }
    }
  }
}
