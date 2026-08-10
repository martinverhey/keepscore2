import 'package:equatable/equatable.dart';

class MatchParticipant extends Equatable {
  const MatchParticipant({
    required this.playerId,
    required this.displayName,
    required this.ratingBefore,
    required this.ratingDelta,
  });

  factory MatchParticipant.fromMap(Map<String, dynamic> map) =>
      MatchParticipant(
        playerId: map['player_id'] as String,
        displayName: map['display_name'] as String,
        ratingBefore: _toDouble(map['rating_before']),
        ratingDelta: _toDouble(map['rating_delta']),
      );

  final String playerId;
  final String displayName;
  final double ratingBefore;
  final double ratingDelta;

  double get ratingAfter => ratingBefore + ratingDelta;

  @override
  List<Object?> get props => [playerId, displayName, ratingBefore, ratingDelta];
}

double _toDouble(Object? value) => switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s) ?? 0,
      _ => 0,
    };
