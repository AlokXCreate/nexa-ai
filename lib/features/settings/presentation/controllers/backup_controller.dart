import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:localmind_ai/features/settings/domain/entities/backup_metadata.dart';
import 'package:localmind_ai/features/settings/domain/repositories/backup_repository.dart';
import 'package:localmind_ai/features/settings/data/repositories/backup_repository_impl.dart';
import 'package:localmind_ai/features/settings/data/services/backup_service.dart';
import 'package:localmind_ai/features/settings/data/services/google_drive_service.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/settings_controller.dart';

class BackupState {
  final List<BackupMetadata> localBackups;
  final List<BackupMetadata> cloudBackups;
  final bool isBackingUp;
  final bool isRestoring;
  final bool isLoadingCloud;
  final bool isGoogleConnected;
  final String? googleUserEmail;
  final String autoSchedule; // 'none' | 'daily' | 'weekly'
  final String conflictStrategy; // 'overwrite' | 'merge_newer' | 'merge_keep_both'
  final String? errorMessage;
  final String? successMessage;

  BackupState({
    this.localBackups = const [],
    this.cloudBackups = const [],
    this.isBackingUp = false,
    this.isRestoring = false,
    this.isLoadingCloud = false,
    this.isGoogleConnected = false,
    this.googleUserEmail,
    this.autoSchedule = 'none',
    this.conflictStrategy = 'merge_newer',
    this.errorMessage,
    this.successMessage,
  });

  BackupState copyWith({
    List<BackupMetadata>? localBackups,
    List<BackupMetadata>? cloudBackups,
    bool? isBackingUp,
    bool? isRestoring,
    bool? isLoadingCloud,
    bool? isGoogleConnected,
    String? googleUserEmail,
    String? autoSchedule,
    String? conflictStrategy,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BackupState(
      localBackups: localBackups ?? this.localBackups,
      cloudBackups: cloudBackups ?? this.cloudBackups,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      isLoadingCloud: isLoadingCloud ?? this.isLoadingCloud,
      isGoogleConnected: isGoogleConnected ?? this.isGoogleConnected,
      googleUserEmail: googleUserEmail ?? this.googleUserEmail,
      autoSchedule: autoSchedule ?? this.autoSchedule,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BackupController extends StateNotifier<BackupState> {
  final BackupRepository _repository;
  final BackupService _backupService;
  final GoogleDriveService _googleDriveService;
  final Ref _ref;

  BackupController(
    this._repository,
    this._backupService,
    this._googleDriveService,
    this._ref,
  ) : super(BackupState()) {
    _init();
  }

  void _init() async {
    final schedule = await _repository.getAutoBackupSchedule();
    final strategy = await _repository.getConflictResolutionStrategy();
    
    state = state.copyWith(
      autoSchedule: schedule,
      conflictStrategy: strategy,
    );

    await loadLocalBackups();
    await checkGoogleConnection();
  }

  Future<void> loadLocalBackups() async {
    try {
      final list = await _repository.getBackupMetadataList();
      // Filter out files that might have been deleted manually
      final List<BackupMetadata> verified = [];
      for (final backup in list) {
        if (backup.source == 'local' && File(backup.filePath).existsSync()) {
          verified.add(backup);
        }
      }
      // Sort newest first
      verified.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(localBackups: verified);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load local backups: $e');
    }
  }

  Future<void> checkGoogleConnection() async {
    final connected = _googleDriveService.isSignedIn;
    state = state.copyWith(
      isGoogleConnected: connected,
      googleUserEmail: connected ? _googleDriveService.currentUser?.email : null,
    );
    if (connected) {
      await loadCloudBackups();
    }
  }

  Future<void> connectGoogle() async {
    state = state.copyWith(isLoadingCloud: true, clearError: true);
    try {
      final success = await _googleDriveService.signIn();
      if (success) {
        state = state.copyWith(
          isGoogleConnected: true,
          googleUserEmail: _googleDriveService.currentUser?.email,
        );
        await loadCloudBackups();
      } else {
        state = state.copyWith(errorMessage: 'Google Sign-In was canceled.');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Google Connection failed: $e');
    } finally {
      state = state.copyWith(isLoadingCloud: false);
    }
  }

  Future<void> disconnectGoogle() async {
    state = state.copyWith(isLoadingCloud: true, clearError: true);
    try {
      await _googleDriveService.signOut();
      state = state.copyWith(
        isGoogleConnected: false,
        googleUserEmail: null,
        cloudBackups: [],
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Google Disconnect failed: $e');
    } finally {
      state = state.copyWith(isLoadingCloud: false);
    }
  }

  Future<void> loadCloudBackups() async {
    if (!state.isGoogleConnected) return;
    state = state.copyWith(isLoadingCloud: true, clearError: true);
    try {
      final files = await _googleDriveService.listBackups();
      final cloudList = files.map((file) {
        final id = file['id'] as String;
        final name = file['name'] as String;
        final sizeStr = file['size'] as String?;
        final size = sizeStr != null ? int.tryParse(sizeStr) ?? 0 : 0;
        final createdStr = file['createdTime'] as String;
        final timestamp = DateTime.tryParse(createdStr) ?? DateTime.now();
        final isEncrypted = name.contains('_enc_');

        return BackupMetadata(
          id: id,
          timestamp: timestamp,
          fileName: name,
          fileSize: size,
          source: 'gdrive',
          filePath: id, // Google Drive file ID
          isEncrypted: isEncrypted,
        );
      }).toList();

      state = state.copyWith(cloudBackups: cloudList);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load Google Drive backups: $e');
    } finally {
      state = state.copyWith(isLoadingCloud: false);
    }
  }

  Future<void> createBackup({required String? password, required bool uploadToCloud}) async {
    state = state.copyWith(isBackingUp: true, clearError: true, clearSuccess: true);
    try {
      final jsonString = await _backupService.serializeAllData();
      final fileBytes = _backupService.packageBackup(jsonString, password);
      
      final now = DateTime.now();
      final encryptionTag = (password != null && password.isNotEmpty) ? '_enc_' : '_raw_';
      final fileName = 'localmind_backup${encryptionTag}${now.millisecondsSinceEpoch}.lmbk';

      if (uploadToCloud) {
        if (!state.isGoogleConnected) {
          throw Exception('Google Drive is not connected.');
        }
        final fileId = await _googleDriveService.uploadBackup(fileName, fileBytes);
        final metadata = BackupMetadata(
          id: fileId,
          timestamp: now,
          fileName: fileName,
          fileSize: fileBytes.length,
          source: 'gdrive',
          filePath: fileId,
          isEncrypted: password != null && password.isNotEmpty,
        );
        await _repository.saveBackupMetadata(metadata);
        await loadCloudBackups();
        state = state.copyWith(successMessage: 'Backup uploaded to Google Drive successfully.');
      } else {
        // Local backup
        final directory = await getApplicationDocumentsDirectory();
        final backupsDir = Directory('${directory.path}/localmind_backups');
        if (!backupsDir.existsSync()) {
          backupsDir.createSync();
        }

        final file = File('${backupsDir.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        final metadata = BackupMetadata(
          id: 'local_${now.millisecondsSinceEpoch}',
          timestamp: now,
          fileName: fileName,
          fileSize: fileBytes.length,
          source: 'local',
          filePath: file.path,
          isEncrypted: password != null && password.isNotEmpty,
        );

        await _repository.saveBackupMetadata(metadata);
        await loadLocalBackups();
        state = state.copyWith(successMessage: 'Backup created locally successfully.');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Backup operation failed: $e');
    } finally {
      state = state.copyWith(isBackingUp: false);
    }
  }

  Future<void> restoreBackup(BackupMetadata backup, String? password) async {
    state = state.copyWith(isRestoring: true, clearError: true, clearSuccess: true);
    try {
      List<int> fileBytes;
      if (backup.source == 'local') {
        final file = File(backup.filePath);
        if (!file.existsSync()) {
          throw Exception('Local file does not exist.');
        }
        fileBytes = await file.readAsBytes();
      } else {
        // Download from Google Drive
        fileBytes = await _googleDriveService.downloadBackup(backup.filePath);
      }

      final jsonString = _backupService.unpackageBackup(fileBytes, password);
      await _backupService.deserializeAndRestore(jsonString, state.conflictStrategy);
      
      // Reload UI settings state
      _ref.read(settingsControllerProvider.notifier).log('Settings and database restored from backup.');
      
      state = state.copyWith(successMessage: 'Database restored successfully! Please restart the app to load all data.');
    } catch (e) {
      state = state.copyWith(errorMessage: 'Restore failed: $e');
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<void> deleteBackup(BackupMetadata backup) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    try {
      if (backup.source == 'local') {
        final file = File(backup.filePath);
        if (file.existsSync()) {
          await file.delete();
        }
        await _repository.deleteBackupMetadata(backup.id);
        await loadLocalBackups();
      } else {
        await _googleDriveService.deleteBackup(backup.filePath);
        await _repository.deleteBackupMetadata(backup.id);
        await loadCloudBackups();
      }
      state = state.copyWith(successMessage: 'Backup deleted.');
    } catch (e) {
      state = state.copyWith(errorMessage: 'Delete failed: $e');
    }
  }

  Future<void> updateSchedule(String schedule) async {
    await _repository.saveAutoBackupSchedule(schedule);
    state = state.copyWith(autoSchedule: schedule);
  }

  Future<void> updateConflictStrategy(String strategy) async {
    await _repository.saveConflictResolutionStrategy(strategy);
    state = state.copyWith(conflictStrategy: strategy);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// Riverpod Providers
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(backupRepositoryProvider));
});

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

final backupControllerProvider = StateNotifierProvider<BackupController, BackupState>((ref) {
  final repo = ref.watch(backupRepositoryProvider);
  final service = ref.watch(backupServiceProvider);
  final drive = ref.watch(googleDriveServiceProvider);
  return BackupController(repo, service, drive, ref);
});
