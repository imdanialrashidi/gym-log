import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n/l10n.dart';

/// A static, quiet placeholder for the first document load.
///
/// It replaces an indeterminate spinner so the first frame is cheap and the
/// shell does not repaint continuously while the JSON document opens. It is
/// decorative for sighted users and one labelled node for assistive tech.
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );
    return Semantics(
      container: true,
      label: context.l10n.loadingData,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space2,
            padding,
            AppTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 164,
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(
                    color: AppTokens.outline.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              for (int index = 0; index < rows; index++) ...<Widget>[
                Container(
                  height: 88,
                  padding: const EdgeInsetsDirectional.all(AppTokens.space2),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                    border: Border.all(
                      color: AppTokens.outline.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 132,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTokens.surface3,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusPill,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space1),
                      Container(
                        width: 210,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTokens.surface2,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusPill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < rows - 1) const SizedBox(height: AppTokens.space2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
