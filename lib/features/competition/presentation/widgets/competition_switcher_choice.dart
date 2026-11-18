import 'package:flutter/widgets.dart';

sealed class CompetitionSwitcherChoice {
  const CompetitionSwitcherChoice();
}

final class CompetitionSwitchChoice extends CompetitionSwitcherChoice {
  const CompetitionSwitchChoice(this.competitionId);

  final String competitionId;
}

final class CompetitionJoinChoice extends CompetitionSwitcherChoice {
  const CompetitionJoinChoice();
}

final class CompetitionCreateChoice extends CompetitionSwitcherChoice {
  const CompetitionCreateChoice();
}

final class CompetitionActionChoice extends CompetitionSwitcherChoice {
  const CompetitionActionChoice(this.action);

  final VoidCallback action;
}
