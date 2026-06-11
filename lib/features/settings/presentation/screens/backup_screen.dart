import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';
import 'package:localmind_ai/core/theme/app_typography.dart';
import 'package:localmind_ai/core/widgets/glass_app_bar.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';
import 'package:localmind_ai/core/widgets/premium_button.dart';
import 'package:localmind_ai/features/settings/domain/entities/backup_metadata.dart';
import 'package:localmind_ai/features/settings/presentation/controllers/backup_controller.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Show error or success SnackBars reactively
    ref.listen<BackupState>(backupControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(backupControllerProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(backupControllerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text('Backup & Restore', style: AppTypography.titleMedium),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                center: const Alignment(-0.6, -0.6),
                radius: 1.5,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.only(
                top: kToolbarHeight + 40,
                bottom: 120,
                left: 16,
                right: 16,
              ),
              children: [
                // 1. Google Drive Integration Card
                _buildGoogleDriveCard(state),
                const SizedBox(height: 16),

                // 2. Action Controls (Backup/Restore local)
                _buildLocalBackupActionsCard(state),
                const SizedBox(height: 16),

                // 3. Settings Cards (Schedule & Conflict Resolution)
                _buildSettingsAccordion(state),
                const SizedBox(height: 24),

                // 4. Backups Catalog History
                Text('Backup Versions', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                
                if (state.localBackups.isEmpty && state.cloudBackups.isEmpty)
                  _buildEmptyState()
                else ...[
                  if (state.localBackups.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Local Storage', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ...state.localBackups.map((backup) => _buildBackupTile(backup)),
                    const SizedBox(height: 16),
                  ],
                  if (state.cloudBackups.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Google Drive', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ...state.cloudBackups.map((backup) => _buildBackupTile(backup)),
                  ]
                ],
              ],
            ),
          ),

          // Loading overlays
          if (state.isBackingUp || state.isRestoring)
            _buildLoadingOverlay(state.isBackingUp ? 'Creating database backup...' : 'Restoring data files...'),
        ],
      ),
    );
  }

  Widget _buildGoogleDriveCard(BackupState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.15),
            child: const Icon(Icons.cloud_queue_rounded, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Google Drive Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  state.isGoogleConnected
                      ? 'Connected: ${state.googleUserEmail}'
                      : 'Keep your database safe in the cloud',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: PremiumButton(
              label: state.isGoogleConnected ? 'Disconnect' : 'Connect',
              isSecondary: state.isGoogleConnected,
              onPressed: () {
                if (state.isGoogleConnected) {
                  ref.read(backupControllerProvider.notifier).disconnectGoogle();
                } else {
                  ref.read(backupControllerProvider.notifier).connectGoogle();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalBackupActionsCard(BackupState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Database Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Instantly capture settings, collections, prompts, and chats.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Local Backup',
                  icon: Icons.save_alt_rounded,
                  onPressed: () => _showBackupDialog(uploadToCloud: false),
                ),
              ),
              if (state.isGoogleConnected) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: PremiumButton(
                    label: 'Cloud Backup',
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () => _showBackupDialog(uploadToCloud: true),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsAccordion(BackupState state) {
    return Column(
      children: [
        // Automatic Backup dropdown
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text('Auto Backup Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              DropdownButton<String>(
                value: state.autoSchedule,
                dropdownColor: Theme.of(context).cardTheme.color,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Disabled', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(backupControllerProvider.notifier).updateSchedule(val);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Conflict Strategy dropdown
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.merge_type_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text('Conflict Resolution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              DropdownButton<String>(
                value: state.conflictStrategy,
                dropdownColor: Theme.of(context).cardTheme.color,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'overwrite', child: Text('Overwrite Local', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'merge_newer', child: Text('Merge (Keep Newer)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'merge_keep_both', child: Text('Merge (Keep Both)', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(backupControllerProvider.notifier).updateConflictStrategy(val);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackupTile(BackupMetadata backup) {
    final formattedSize = (backup.fileSize / 1024).toStringAsFixed(1);
    final formattedDate = '${backup.timestamp.day}/${backup.timestamp.month}/${backup.timestamp.year} ${backup.timestamp.hour.toString().padLeft(2, '0')}:${backup.timestamp.minute.toString().padLeft(2, '0')}';
    final isLocal = backup.source == 'local';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                isLocal ? Icons.storage_rounded : Icons.backup_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          backup.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (backup.isEncrypted) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate • ${formattedSize} KB',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Action buttons
            IconButton(
              icon: const Icon(Icons.settings_backup_restore_rounded, color: Colors.blueAccent, size: 20),
              tooltip: 'Restore Backup',
              onPressed: () => _showRestoreConfirmDialog(backup),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              tooltip: 'Delete Backup',
              onPressed: () => ref.read(backupControllerProvider.notifier).deleteBackup(backup),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No backup snapshots found.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(String message) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupDialog({required bool uploadToCloud}) {
    _passwordController.clear();
    bool useEncryption = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('New Backup', style: AppTypography.titleMedium),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select whether to encrypt your backup metadata and chats.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Encrypt Backup', style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  value: useEncryption,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      useEncryption = val;
                    });
                  },
                ),
                if (useEncryption) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (useEncryption && !_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop();
                ref.read(backupControllerProvider.notifier).createBackup(
                      password: useEncryption ? _passwordController.text : null,
                      uploadToCloud: uploadToCloud,
                    );
              },
              child: const Text('Backup'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreConfirmDialog(BackupMetadata backup) {
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Restore Backup', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore "${backup.fileName}"? This operation matches your selected conflict strategy (${ref.read(backupControllerProvider).conflictStrategy}).',
              style: const TextStyle(fontSize: 13),
            ),
            if (backup.isEncrypted) ...[
              const SizedBox(height: 16),
              const Text('This file is encrypted. Enter the backup password:', style: TextStyle(fontSize: 12, color: Colors.amber)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Encryption Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(backupControllerProvider.notifier).restoreBackup(
                    backup,
                    backup.isEncrypted ? _passwordController.text : null,
                  );
            },
            child: const Text('Restore', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}
