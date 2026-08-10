import 'package:equatable/equatable.dart';

enum SeasonLength {
  monthly('monthly'),
  quarterly('quarterly'),
  yearly('yearly');

  const SeasonLength(this.wireName);
  final String wireName;

  static SeasonLength fromWire(String value) => SeasonLength.values.firstWhere(
        (v) => v.wireName == value,
        orElse: () => SeasonLength.monthly,
      );
}

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

class CompetitionOverview extends Equatable {
  const CompetitionOverview({
    required this.competition,
    required this.playerCount,
    required this.matchCount,
    this.lastPlayedAt,
    this.myPlayerId,
  });

  factory CompetitionOverview.fromMap(Map<String, dynamic> map) =>
      CompetitionOverview(
        competition: Competition.fromMap(map),
        playerCount: (map['player_count'] as num?)?.toInt() ?? 0,
        matchCount: (map['match_count'] as num?)?.toInt() ?? 0,
        lastPlayedAt: map['last_played_at'] == null
            ? null
            : DateTime.parse(map['last_played_at'] as String),
        myPlayerId: map['my_player_id'] as String?,
      );

  final Competition competition;
  final int playerCount;
  final int matchCount;
  final DateTime? lastPlayedAt;
  final String? myPlayerId;

  String get id => competition.id;

  @override
  List<Object?> get props =>
      [competition, playerCount, matchCount, lastPlayedAt, myPlayerId];
}

double _toDouble(Object? value) => switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s) ?? 0,
      _ => 0,
    };
