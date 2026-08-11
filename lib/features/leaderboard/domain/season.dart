import 'package:equatable/equatable.dart';

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

  DateTime get midpoint =>
      startsAt.add(Duration(microseconds: endsAt.difference(startsAt).inMicroseconds ~/ 2));

  bool get hasStarted => id != null;

  @override
  List<Object?> get props => [id, startsAt, endsAt];
}
