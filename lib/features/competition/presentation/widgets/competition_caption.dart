import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/competition_cubit.dart';
import '../pages/competition_flows.dart';
import '../pages/competition_switcher_sheet.dart';

class CompetitionCaption extends StatelessWidget {
  static const double _chevronSize = 12;

  const CompetitionCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<CompetitionCubit, String?>(
      (cubit) => cubit.state.competition?.name,
    );
    if (name == null) return const SizedBox.shrink();
    final accent = AdaptiveColors.accent(context);

    return Semantics(
      label: context.l10n.competitionSwitch(name),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionStrong.copyWith(color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AdaptiveIcon(
            AdaptiveGlyph.chevronDown,
            size: _chevronSize,
            color: accent,
          ),
        ],
      ),
    );
  }
}

Future<void> openCompetitionSwitcher(BuildContext context) async {
  final choice = await showCompetitionSwitcherSheet(context);
  if (choice == null || !context.mounted) return;
  await runCompetitionSwitcherChoice(context, choice);
}
