import 'package:equatable/equatable.dart';

import '../../../tournament/domain/tournament_run.model.dart';
import '../../domain/match_entry.model.dart';

sealed class MatchFeedEntry extends Equatable {
  const MatchFeedEntry();

  String get id;

  DateTime get happenedAt;

  @override
  List<Object?> get props => [id, happenedAt];
}

class MatchFeedMatch extends MatchFeedEntry {
  const MatchFeedMatch(this.match);

  final MatchEntry match;

  @override
  String get id => match.id;

  @override
  DateTime get happenedAt => match.playedAt;
}

class MatchFeedTournament extends MatchFeedEntry {
  const MatchFeedTournament(this.run);

  final TournamentRun run;

  @override
  String get id => run.id;

  @override
  DateTime get happenedAt => run.finishedAt;
}
