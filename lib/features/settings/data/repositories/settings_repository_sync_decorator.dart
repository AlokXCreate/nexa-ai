import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/core/database/sync_operation.dart';
import 'package:localmind_ai/core/database/firestore_sync_service.dart';
import 'package:localmind_ai/features/settings/domain/entities/app_settings.dart';
import 'package:localmind_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:localmind_ai/features/security/presentation/controllers/security_controller.dart';

class SettingsRepositorySyncDecorator implements SettingsRepository {
  final SettingsRepository _delegate;
  final Ref _ref;

  SettingsRepositorySyncDecorator(this._delegate, this._ref);

  FirestoreSyncService get _syncService => _ref.read(firestoreSyncServiceProvider);

  bool _isIncognito() {
    try {
      return _ref.read(securityControllerProvider).config.isIncognitoActive;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AppSettings> getSettings() => _delegate.getSettings();

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _delegate.saveSettings(settings);
    if (!_isIncognito()) {
      await _syncService.queueOperation(
        collectionName: 'settings',
        documentId: 'app',
        actionType: SyncActionType.save,
        data: settings.toMap(),
      );
    }
  }
}
