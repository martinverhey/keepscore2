import 'package:equatable/equatable.dart';

import 'tournament_match.model.dart';

export 'tournament_match.model.dart';

class Bracket extends Equatable {
  const Bracket(this.rounds);

  factory Bracket.fromMatches(List<TournamentMatch> matches) {
    final byRound = <int, List<TournamentMatch>>{};
    for (final match in matches) {
      (byRound[match.round] ??= []).add(match);
    }

    final numbers = byRound.keys.toList()..sort();
    return Bracket([
      for (final number in numbers)
        List<TournamentMatch>.unmodifiable(
          byRound[number]!..sort((a, b) => a.slot.compareTo(b.slot)),
        ),
    ]);
  }

  final List<List<TournamentMatch>> rounds;

  int get roundCount => rounds.length;

  bool get isEmpty => rounds.isEmpty;

  TournamentMatch? get finalMatch =>
      rounds.isEmpty || rounds.last.isEmpty ? null : rounds.last.first;

  TournamentEntrant? get champion => finalMatch?.winner;

  List<TournamentMatch> get playableNow => [
    for (final round in rounds)
      for (final match in round)
        if (match.isPlayable && !match.isPlayed) match,
  ];

  int get currentRoundNumber {
    for (var index = 0; index < rounds.length; index++) {
      if (rounds[index].any((match) => !match.isPlayed && !match.isBye)) {
        return index + 1;
      }
    }
    return roundCount;
  }

  List<TournamentMatch> get currentRound =>
      rounds.isEmpty ? const [] : rounds[currentRoundNumber - 1];

  @override
  List<Object?> get props => [rounds];
}
