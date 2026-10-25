import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches an external URL. Widget tests override this to record the request
/// and to simulate a device without a browser.
///
/// Deliberately no `canLaunchUrl` call: on Android 11+ that check needs
/// package-visibility `<queries>` entries and is unreliable without them. We
/// attempt the launch instead and report a false result or exception.
typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

final Provider<ExternalLinkLauncher> externalLinkLauncherProvider =
    Provider<ExternalLinkLauncher>((_) {
      return (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    });

/// Opens [uri] in an external app and shows [failureMessage] when no handler
/// accepts it. The message is non-blocking; the current screen stays usable.
Future<void> openExternalLink(
  BuildContext context,
  WidgetRef ref,
  Uri uri, {
  required String failureMessage,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  bool launched = false;
  try {
    launched = await ref.read(externalLinkLauncherProvider)(uri);
  } catch (_) {
    launched = false;
  }
  if (!launched) {
    messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}
