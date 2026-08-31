import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class CompetitionSettingsButton extends StatelessWidget {
  const CompetitionSettingsButton({super.key, required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.settings,
      semanticLabel: context.l10n.competitionSettings,
      onPressed: () => context.push<Object?>(Routes.settings(competitionId)),
    );
  }
}
