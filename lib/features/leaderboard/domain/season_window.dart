import 'package:equatable/equatable.dart';

class SeasonWindow extends Equatable {
  const SeasonWindow({
    required this.startsAt,
    required this.endsAt,
    this.id,
  });

  factory SeasonWindow.fromMap(Map<String, dynamic> map) => SeasonWindow(
        id: map['season_id'] as String?,
        startsAt: DateTime.parse(map['season_starts_at'] as String),
        endsAt: DateTime.parse(map['season_ends_at'] as String),
      );

  final String? id;
  final DateTime startsAt;
  final DateTime endsAt;

  bool get hasNoMatchesYet => id == null;

  @override
  List<Object?> get props => [id, startsAt, endsAt];
}
