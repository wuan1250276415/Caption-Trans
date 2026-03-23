import 'package:flutter/material.dart';

import 'package:caption_trans/l10n/app_localizations.dart';

import '../../models/whisper_download_source.dart';

Future<WhisperDownloadSource?> showDownloadSourceDialog(
  BuildContext context, {
  WhisperDownloadSource? initialValue,
  String? title,
  String? message,
}) {
  return showDialog<WhisperDownloadSource>(
    context: context,
    builder: (_) => _DownloadSourceDialog(
      initialValue: initialValue,
      title: title,
      message: message,
    ),
  );
}

String localizedDownloadSourceLabel(
  AppLocalizations l10n,
  WhisperDownloadSource? source,
) {
  return switch (source) {
    WhisperDownloadSource.global => l10n.downloadSourceGlobal,
    WhisperDownloadSource.mainlandChina => l10n.downloadSourceChina,
    null => l10n.downloadSourceUnset,
  };
}

class _DownloadSourceDialog extends StatefulWidget {
  final WhisperDownloadSource? initialValue;
  final String? title;
  final String? message;

  const _DownloadSourceDialog({
    required this.initialValue,
    this.title,
    this.message,
  });

  @override
  State<_DownloadSourceDialog> createState() => _DownloadSourceDialogState();
}

class _DownloadSourceDialogState extends State<_DownloadSourceDialog> {
  WhisperDownloadSource? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_download_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title ?? l10n.downloadSourceTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.message ?? l10n.downloadSourceHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 18),
              _SourceOptionCard(
                icon: Icons.public_rounded,
                title: l10n.downloadSourceGlobal,
                description: l10n.downloadSourceGlobalDescription,
                selected: _selected == WhisperDownloadSource.global,
                onTap: () {
                  setState(() => _selected = WhisperDownloadSource.global);
                },
              ),
              const SizedBox(height: 10),
              _SourceOptionCard(
                icon: Icons.location_city_rounded,
                title: l10n.downloadSourceChina,
                description: l10n.downloadSourceChinaDescription,
                selected: _selected == WhisperDownloadSource.mainlandChina,
                onTap: () {
                  setState(
                    () => _selected = WhisperDownloadSource.mainlandChina,
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
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

class _SourceOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _SourceOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.white.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.white.withValues(alpha: 0.32),
            ),
          ],
        ),
      ),
    );
  }
}
