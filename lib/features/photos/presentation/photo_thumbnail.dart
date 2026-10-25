import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';

/// Rounded photo thumbnail. The fallback is a labeled missing-file state, never
/// a raw image error or path.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    required this.file,
    required this.label,
    this.size = 96,
    this.onTap,
    super.key,
  });

  final File file;
  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        excludeFromSemantics: true,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return Container(
            width: size,
            height: size,
            color: AppTokens.surface2,
            alignment: Alignment.center,
            child: Tooltip(
              message: l10n.photoMissing,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppTokens.textSecondary,
              ),
            ),
          );
        },
      ),
    );

    return Semantics(
      label: label,
      button: onTap != null,
      child: onTap == null
          ? image
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              child: image,
            ),
    );
  }
}
