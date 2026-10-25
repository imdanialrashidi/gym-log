import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/photo_index_controller.dart';
import '../../../data/photo_storage.dart';
import 'photo_actions.dart';
import 'photo_thumbnail.dart';
import 'photo_viewer_screen.dart';

/// Up to three private session photos with a viewer and removal (`PHO-001`,
/// `PHO-005`, ADR-0006).
class SessionPhotosSection extends ConsumerWidget {
  const SessionPhotosSection({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<PhotoIndex> asyncIndex = ref.watch(photoIndexProvider);

    return Padding(
      key: const Key('session-photos-section'),
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: asyncIndex.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(AppTokens.space1),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (Object error, StackTrace stack) => Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.photoLoadFailed,
                style: const TextStyle(color: AppTokens.danger),
              ),
            ),
            TextButton(
              key: const Key('retry-session-photos'),
              onPressed: () => ref.invalidate(photoIndexProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
        data: (PhotoIndex index) => _buildContent(context, ref, index),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PhotoIndex index) {
    final AppLocalizations l10n = context.l10n;
    final List<int> slots = index.sessionSlots(sessionId);
    final bool atLimit = slots.length >= maxSessionPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.sessionPhotosLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              context.digits(
                l10n.sessionPhotoCount(slots.length, maxSessionPhotos),
              ),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space1),
        if (slots.isEmpty)
          Text(
            l10n.noSessionPhotos,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTokens.textSecondary),
          )
        else
          Wrap(
            spacing: AppTokens.space1,
            runSpacing: AppTokens.space1,
            children: <Widget>[
              for (final int slot in slots)
                PhotoThumbnail(
                  key: ValueKey<String>('session-photo-$slot'),
                  file: index.file(sessionPhotoFileName(sessionId, slot)),
                  label: context.digits(l10n.photoNumber(slot + 1)),
                  onTap: () => _openViewer(context, ref, index, slot),
                ),
            ],
          ),
        const SizedBox(height: AppTokens.space1),
        if (!atLimit)
          OutlinedButton.icon(
            key: const Key('add-session-photo'),
            onPressed: () => addSessionPhoto(context, ref, sessionId),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.addPhoto),
          )
        else
          Text(
            context.digits(l10n.photoLimitReached(maxSessionPhotos)),
            key: const Key('session-photo-limit'),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        const SizedBox(height: 4),
        Text(
          l10n.photoPrivateHint,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTokens.textSecondary),
        ),
      ],
    );
  }

  Future<void> _openViewer(
    BuildContext context,
    WidgetRef ref,
    PhotoIndex index,
    int slot,
  ) async {
    final File file = index.file(sessionPhotoFileName(sessionId, slot));
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext routeContext) => PhotoViewerScreen(
          file: file,
          onRemove: () async {
            await ref
                .read(photoIndexProvider.notifier)
                .removeSessionPhoto(sessionId, slot);
            return true;
          },
        ),
      ),
    );
  }
}
