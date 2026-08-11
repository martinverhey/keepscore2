import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/standing.dart';
import '../../domain/rating_point.dart';

enum ProfileStatus { loading, ready, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.standing,
    this.playerCount = 0,
    this.history = const [],
    this.failure,
  });

  final ProfileStatus status;
  final Standing? standing;
  final int playerCount;
  final List<RatingPoint> history;
  final Failure? failure;

  @override
  List<Object?> get props => [status, standing, playerCount, history, failure];
}
