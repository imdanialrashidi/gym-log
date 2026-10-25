import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_info.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/links/external_link.dart';

/// Version, license, source, donation, privacy, and medical-advice notice
/// (`SET-005`). Both links open outside the app; a missing browser leaves the
/// screen usable and shows a non-blocking message.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppTokens.space2),
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppTokens.space1),
                Text(
                  l10n.aboutVersion(context.digits(appVersion)),
                  key: const Key('about-version'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.aboutLicenseLabel),
            subtitle: Text(l10n.aboutLicenseValue),
          ),
          ListTile(
            key: const Key('about-open-source-licenses'),
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            leading: const Icon(Icons.policy_outlined),
            title: Text(l10n.aboutOpenSourceLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: appVersion,
            ),
          ),
          ListTile(
            key: const Key('about-source'),
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutSourceCode),
            subtitle: const Text(appSourceUrl),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(
              openExternalLink(
                context,
                ref,
                Uri.parse(appSourceUrl),
                failureMessage: l10n.aboutLinkFailed,
              ),
            ),
          ),
          ListTile(
            key: const Key('about-donate'),
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            leading: const Icon(Icons.favorite_outline),
            title: Text(l10n.aboutDonate),
            subtitle: const Text(appDonateUrl),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(
              openExternalLink(
                context,
                ref,
                Uri.parse(appDonateUrl),
                failureMessage: l10n.aboutLinkFailed,
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.aboutPrivacyTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTokens.space1),
                Text(l10n.aboutPrivacyBody),
                const SizedBox(height: AppTokens.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTokens.info,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Expanded(child: Text(l10n.aboutNotMedicalAdvice)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
