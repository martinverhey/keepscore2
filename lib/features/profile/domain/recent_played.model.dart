import 'package:equatable/equatable.dart';

class RecentPlayed extends Equatable {
  const RecentPlayed({required this.today, required this.week});

  const RecentPlayed.zero() : today = 0, week = 0;

  factory RecentPlayed.fromMap(Map<String, dynamic> map) => RecentPlayed(
    today: (map['today_played'] as num?)?.toInt() ?? 0,
    week: (map['week_played'] as num?)?.toInt() ?? 0,
  );

  final int today;
  final int week;

  @override
  List<Object?> get props => [today, week];
}
