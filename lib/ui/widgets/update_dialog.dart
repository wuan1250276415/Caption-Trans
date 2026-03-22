import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:caption_trans/l10n/app_localizations.dart';
import '../../services/update_service.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  UpdateCheckResult result,
) async {
  final l10n = AppLocalizations.of(context)!;
  final releaseNotes = result.releaseNotes?.trim();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(l10n.updateAvailableTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 360),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.updateAvailableMessage(
                    result.latestVersion,
                    result.currentVersion.displayVersion,
                  ),
                ),
                if (result.assetName != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    result.assetName!,
                    style: Theme.of(dialogContext).textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.65)),
                  ),
                ],
                if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.releaseNotes,
                    style: Theme.of(dialogContext).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      releaseNotes,
                      style: Theme.of(dialogContext).textTheme.bodySmall
                          ?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openUpdateLink(context, result.downloadUrl);
            },
            child: Text(l10n.downloadUpdate),
          ),
        ],
      );
    },
  );
}

Future<void> openUpdateLink(BuildContext context, String rawUrl) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.tryParse(rawUrl);

  if (uri == null) {
    _showUpdateError(context, l10n.updateCheckFailed);
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showUpdateError(context, l10n.updateCheckFailed);
    }
  } catch (_) {
    if (!context.mounted) return;
    _showUpdateError(context, l10n.updateCheckFailed);
  }
}

void _showUpdateError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );
}
