import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.profile,
      semanticLabel: context.l10n.profilePageTitle,
      onPressed: () => context.push<Object?>(Routes.profile(competitionId)),
    );
  }
}
