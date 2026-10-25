import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/photo_storage.dart';
import 'photo_failure_text.dart';

/// Full-screen photo viewer with an optional delete action (`PHO-001`,
/// `PHO-005`). A missing file shows a plain message instead of an error.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({required this.file, this.onRemove, super.key});

  final File file;

  /// Deletes the stored copy and returns `true` when it no longer exists.
  final Future<bool> Function()? onRemove;

  Future<void> _remove(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.removePhotoTitle,
      message: l10n.removePhotoBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      final bool? removed = await onRemove?.call();
      if (removed != true || !context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on PhotoStorageException catch (error) {
      if (context.mounted) {
        _showFailure(context, photoFailureMessage(context, error));
      }
    } catch (_) {
      if (context.mounted) {
        _showFailure(context, l10n.photoDeleteFailed);
      }
    }
  }

  void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: Text(l10n.photoViewerTitle),
        actions: <Widget>[
          if (onRemove != null)
            IconButton(
              key: const Key('remove-photo'),
              tooltip: l10n.removePhoto,
              onPressed: () => _remove(context),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            semanticLabel: l10n.photoViewerTitle,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.all(AppTokens.space3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: AppTokens.textSecondary,
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          l10n.photoMissing,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
          ),
        ),
      ),
    );
  }
}
