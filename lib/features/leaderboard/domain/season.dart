import 'package:equatable/equatable.dart';

/// One scoring period of a competition.
///
/// [id] is null for the current calendar window when nobody has played in it
/// yet: `seasons` only gets a row once a match lands in it, but the app still
/// has to show the window everyone is currently playing for.
class Season extends Equatable {
  const Season({required this.startsAt, required this.endsAt, this.id});

  factory Season.fromMap(Map<String, dynamic> map) => Season(
    id: map['id'] as String,
    startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
  );

  final String? id;
  final DateTime startsAt;
  final DateTime endsAt;

  /// The instant halfway through, which is what a label should be derived
  /// from: the boundaries are midnight in the competition's timezone, so on a
  /// device further west "August" starts on 31 July.
  DateTime get midpoint =>
      startsAt.add(Duration(microseconds: endsAt.difference(startsAt).inMicroseconds ~/ 2));

  bool get hasStarted => id != null;

  @override
  List<Object?> get props => [id, startsAt, endsAt];
}
