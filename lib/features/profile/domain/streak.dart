import 'package:equatable/equatable.dart';

import 'streak_type.dart';

export 'streak_type.dart';

class Streak extends Equatable {
  const Streak({required this.type, required this.count});

  const Streak.none() : type = StreakType.none, count = 0;

  factory Streak.fromMap(Map<String, dynamic> map) => Streak(
    type: StreakType.fromWire(map['streak_type'] as String? ?? 'none'),
    count: (map['streak_count'] as num?)?.toInt() ?? 0,
  );

  final StreakType type;
  final int count;

  @override
  List<Object?> get props => [type, count];
}
