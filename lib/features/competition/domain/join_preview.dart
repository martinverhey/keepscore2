import 'package:equatable/equatable.dart';

class ClaimablePlayer extends Equatable {
  const ClaimablePlayer({required this.id, required this.displayName});

  factory ClaimablePlayer.fromMap(Map<String, dynamic> map) => ClaimablePlayer(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
      );

  final String id;
  final String displayName;

  @override
  List<Object?> get props => [id, displayName];
}

class JoinPreview extends Equatable {
  const JoinPreview({
    required this.competitionId,
    required this.name,
    required this.playerCount,
    required this.alreadyMember,
    required this.claimable,
    this.ownerName,
  });

  factory JoinPreview.fromMap(Map<String, dynamic> map) => JoinPreview(
        competitionId: map['competition_id'] as String,
        name: map['name'] as String,
        ownerName: map['owner_name'] as String?,
        playerCount: (map['player_count'] as num?)?.toInt() ?? 0,
        alreadyMember: map['already_member'] as bool? ?? false,
        claimable: ((map['unclaimed'] as List<dynamic>?) ?? const [])
            .map((e) => ClaimablePlayer.fromMap(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String competitionId;
  final String name;
  final String? ownerName;
  final int playerCount;
  final bool alreadyMember;
  final List<ClaimablePlayer> claimable;

  @override
  List<Object?> get props =>
      [competitionId, name, ownerName, playerCount, alreadyMember, claimable];
}
