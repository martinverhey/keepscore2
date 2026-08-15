import 'package:equatable/equatable.dart';

import 'season_length.enum.dart';

export 'competition_overview.model.dart';
export 'season_length.enum.dart';

class Competition extends Equatable {
  const Competition({
    required this.id,
    required this.joinCode,
    required this.name,
    required this.ownerId,
    required this.seasonLength,
    required this.timezone,
    required this.startingRating,
    required this.kFactor,
    required this.movEnabled,
    required this.movCap,
    required this.allowDraws,
    required this.createdAt,
  });

  factory Competition.fromMap(Map<String, dynamic> map) => Competition(
    id: map['id'] as String,
    joinCode: map['join_code'] as String,
    name: map['name'] as String,
    ownerId: map['owner_id'] as String,
    seasonLength: SeasonLength.fromWire(map['season_length'] as String),
    timezone: map['timezone'] as String,
    startingRating: map['starting_rating'] as int,
    kFactor: map['k_factor'] as int,
    movEnabled: map['mov_enabled'] as bool,
    movCap: _toDouble(map['mov_cap']),
    allowDraws: map['allow_draws'] as bool,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  final String id;
  final String joinCode;
  final String name;
  final String ownerId;
  final SeasonLength seasonLength;
  final String timezone;
  final int startingRating;
  final int kFactor;
  final bool movEnabled;
  final double movCap;
  final bool allowDraws;
  final DateTime createdAt;

  bool isOwnedBy(String? userId) => userId != null && userId == ownerId;

  @override
  List<Object?> get props => [
    id,
    joinCode,
    name,
    ownerId,
    seasonLength,
    timezone,
    startingRating,
    kFactor,
    movEnabled,
    movCap,
    allowDraws,
    createdAt,
  ];
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
