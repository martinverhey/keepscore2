import 'package:equatable/equatable.dart';

class Player extends Equatable {
  const Player({
    required this.id,
    required this.competitionId,
    required this.displayName,
    required this.isActive,
    this.userId,
  });

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'] as String,
        competitionId: map['competition_id'] as String,
        displayName: map['display_name'] as String,
        isActive: map['is_active'] as bool? ?? true,
        userId: map['user_id'] as String?,
      );

  final String id;
  final String competitionId;
  final String displayName;
  final bool isActive;
  final String? userId;

  bool get isClaimed => userId != null;

  bool get isPlaceholder => userId == null;

  @override
  List<Object?> get props => [id, competitionId, displayName, isActive, userId];
}
