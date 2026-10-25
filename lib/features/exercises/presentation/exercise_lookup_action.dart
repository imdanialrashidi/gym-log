import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/links/external_link.dart';

/// Opens the image search for [name]/[searchTerm] in the external browser and
/// shows a non-blocking message when no browser handles the URL.
Future<void> launchExerciseLookup(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  String? searchTerm,
}) {
  return openExternalLink(
    context,
    ref,
    buildExerciseLookupUri(name: name, searchTerm: searchTerm),
    failureMessage: context.l10n.lookupFailed,
  );
}
