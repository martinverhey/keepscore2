import 'package:equatable/equatable.dart';

import 'best_streaks.model.dart';
import 'recent_played.model.dart';
import 'streak.model.dart';

class ProfileStats extends Equatable {
  const ProfileStats({
    required this.totalPlayed,
    required this.bestStreaks,
    required this.bestRating,
    required this.streak,
    required this.recentPlayed,
  });

  factory ProfileStats.fromMap(Map<String, dynamic> map) => ProfileStats(
    totalPlayed: (map['total_played'] as num?)?.toInt() ?? 0,
    bestStreaks: BestStreaks.fromMap(map),
    bestRating: _toDouble(map['best_rating']),
    streak: Streak.fromMap(map),
    recentPlayed: RecentPlayed.fromMap(map),
  );

  final int totalPlayed;
  final BestStreaks bestStreaks;
  final double bestRating;
  final Streak streak;
  final RecentPlayed recentPlayed;

  @override
  List<Object?> get props => [
    totalPlayed,
    bestStreaks,
    bestRating,
    streak,
    recentPlayed,
  ];
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
