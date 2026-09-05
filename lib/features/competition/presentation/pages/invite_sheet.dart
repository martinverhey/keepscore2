import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/competition.model.dart';
import '../widgets/active_competition_card.dart';

Future<void> showInviteSheet(
  BuildContext context, {
  required CompetitionOverview overview,
}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => _InviteSheet(overview: overview),
  );
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.overview});

  final CompetitionOverview overview;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.competitionInviteTitle,
      content: ActiveCompetitionCard(overview: overview),
    );
  }
}
