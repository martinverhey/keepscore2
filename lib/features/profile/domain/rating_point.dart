import 'package:equatable/equatable.dart';

class RatingPoint extends Equatable {
  const RatingPoint({
    required this.playedAt,
    required this.ratingAfter,
    required this.ratingDelta,
  });

  factory RatingPoint.fromMap(Map<String, dynamic> map) {
    final match = map['matches'] as Map<String, dynamic>;
    return RatingPoint(
      playedAt: DateTime.parse(match['played_at'] as String).toLocal(),
      ratingAfter: _toDouble(map['rating_after']),
      ratingDelta: _toDouble(map['rating_delta']),
    );
  }

  final DateTime playedAt;
  final double ratingAfter;
  final double ratingDelta;

  @override
  List<Object?> get props => [playedAt, ratingAfter, ratingDelta];
}

double _toDouble(Object? value) => switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s) ?? 0,
      _ => 0,
    };
