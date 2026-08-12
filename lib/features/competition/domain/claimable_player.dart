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
