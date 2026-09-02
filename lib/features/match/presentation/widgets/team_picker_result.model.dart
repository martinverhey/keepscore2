import 'package:equatable/equatable.dart';

class TeamPickerResult extends Equatable {
  const TeamPickerResult({
    required this.teamA,
    required this.teamB,
    required this.isComplete,
  });

  final Set<String> teamA;
  final Set<String> teamB;
  final bool isComplete;

  @override
  List<Object?> get props => [teamA, teamB, isComplete];
}
