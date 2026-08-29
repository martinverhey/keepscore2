import 'package:equatable/equatable.dart';

class TeamAreaMember extends Equatable {
  const TeamAreaMember({
    required this.id,
    required this.displayName,
    required this.rating,
  });

  final String id;
  final String displayName;
  final double rating;

  @override
  List<Object?> get props => [id, displayName, rating];
}
