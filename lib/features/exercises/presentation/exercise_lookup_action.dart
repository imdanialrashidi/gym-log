import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';

/// Launches an external URL. Widget tests override this to record the request
/// and to simulate a device without a browser.
///
/// Deliberately no `canLaunchUrl` call: on Android 11+ that check needs
/// package-visibility `<queries>` entries and is unreliable without them. We
/// attempt the launch instead and report a false result or exception.
typedef ExerciseLookupLauncher = Future<bool> Function(Uri uri);

final Provider<ExerciseLookupLauncher> exerciseLookupLauncherProvider =
    Provider<ExerciseLookupLauncher>((_) {
      return (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    });

/// Opens the image search for [name]/[searchTerm] in the external browser and
/// shows a non-blocking message when no browser handles the URL.
Future<void> launchExerciseLookup(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  String? searchTerm,
}) async {
  final AppLocalizations l10n = context.l10n;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  bool launched = false;
  try {
    launched = await ref.read(exerciseLookupLauncherProvider)(
      buildExerciseLookupUri(name: name, searchTerm: searchTerm),
    );
  } catch (_) {
    launched = false;
  }
  if (!launched) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.lookupFailed)));
  }
}
