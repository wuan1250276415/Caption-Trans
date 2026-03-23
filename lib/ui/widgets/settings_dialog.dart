import 'package:flutter/material.dart';
import 'package:caption_trans/l10n/app_localizations.dart';
import '../../models/whisper_download_source.dart';
import '../../services/settings_service.dart';
import '../../services/update_service.dart';
import 'download_source_dialog.dart';
import 'update_dialog.dart';

/// Settings dialog for configuring API keys, language, and preferences.
class SettingsDialog extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final Locale currentLocale;
  final Map<String, ProviderCredential> providerCredentials;
  final Future<void> Function(String provider) onDeleteProviderCredential;
  final SettingsService settingsService;

  const SettingsDialog({
    super.key,
    required this.onLocaleChanged,
    required this.currentLocale,
    required this.providerCredentials,
    required this.onDeleteProviderCredential,
    required this.settingsService,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final UpdateService _updateService = UpdateService();
  late Locale _selectedLocale;
  late Map<String, ProviderCredential> _savedProviderCredentials;
  WhisperDownloadSource? _selectedDownloadSource;
  String? _currentVersion;
  bool _isLoadingVersion = true;
  bool _isCheckingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.currentLocale;
    _savedProviderCredentials = Map<String, ProviderCredential>.from(
      widget.providerCredentials,
    );
    _selectedDownloadSource = widget.settingsService.whisperDownloadSource;
    _loadCurrentVersion();
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final versionInfo = await _updateService.getCurrentVersionInfo();
      if (!mounted) return;
      setState(() {
        _currentVersion = versionInfo.displayVersion;
        _isLoadingVersion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentVersion = null;
        _isLoadingVersion = false;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingForUpdates) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCheckingForUpdates = true);

    try {
      final result = await _updateService.checkForUpdates();
      if (!mounted) return;

      if (result.isUpdateAvailable) {
        await showUpdateAvailableDialog(context, result);
      } else {
        _showSnackBar(
          l10n.alreadyLatestVersion(result.currentVersion.displayVersion),
          Colors.green.shade700,
        );
      }
      await widget.settingsService.setLastUpdateCheckAt(DateTime.now());
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(l10n.updateCheckFailed, Colors.red.shade700);
      await widget.settingsService.setLastUpdateCheckAt(DateTime.now());
    } finally {
      if (mounted) {
        setState(() => _isCheckingForUpdates = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _changeDownloadSource() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final WhisperDownloadSource? selected = await showDownloadSourceDialog(
      context,
      initialValue: _selectedDownloadSource,
      title: l10n.changeDownloadSource,
      message: l10n.downloadSourceHint,
    );
    if (selected == null || !mounted) {
      return;
    }

    await widget.settingsService.setWhisperDownloadSource(selected);
    if (!mounted) {
      return;
    }

    setState(() => _selectedDownloadSource = selected);
    _showSnackBar(l10n.downloadSourceUpdated, Colors.green.shade700);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final savedEntries = _savedProviderCredentials.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar
              Row(
                children: [
                  Icon(
                    Icons.settings_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.settingsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _LanguageChip(
                            label: '中文',
                            isSelected: _selectedLocale.languageCode == 'zh',
                            onTap: () => setState(
                              () => _selectedLocale = const Locale('zh'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LanguageChip(
                            label: 'English',
                            isSelected: _selectedLocale.languageCode == 'en',
                            onTap: () => setState(
                              () => _selectedLocale = const Locale('en'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.appUpdate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.currentVersion,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoadingVersion
                                  ? '...'
                                  : (_currentVersion ?? '-'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isCheckingForUpdates
                                    ? null
                                    : _checkForUpdates,
                                icon: _isCheckingForUpdates
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.system_update_alt_rounded,
                                      ),
                                label: Text(
                                  _isCheckingForUpdates
                                      ? l10n.checkingForUpdates
                                      : l10n.checkForUpdates,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.downloadSourceSectionTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.downloadSourceSectionHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.downloadSourceTitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    localizedDownloadSourceLabel(
                                      l10n,
                                      _selectedDownloadSource,
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _changeDownloadSource,
                              child: Text(l10n.changeDownloadSource),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.savedProvidersTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.savedProvidersHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (savedEntries.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            l10n.savedProvidersEmpty,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: savedEntries.map((entry) {
                            final maskedKey = entry.value.apiKey.length <= 8
                                ? List.filled(
                                    entry.value.apiKey.length,
                                    '*',
                                  ).join()
                                : '${entry.value.apiKey.substring(0, 4)}...${entry.value.apiKey.substring(entry.value.apiKey.length - 4)}';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          entry.value.baseUrl,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Key: $maskedKey',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await widget.onDeleteProviderCredential(
                                        entry.key,
                                      );
                                      if (!mounted) return;
                                      setState(() {
                                        _savedProviderCredentials.remove(
                                          entry.key,
                                        );
                                      });
                                    },
                                    tooltip: l10n.clear,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onLocaleChanged(_selectedLocale);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
