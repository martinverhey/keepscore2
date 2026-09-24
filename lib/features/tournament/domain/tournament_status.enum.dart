enum TournamentStatus {
  active,
  completed;

  static TournamentStatus fromWire(String value) => switch (value) {
    'completed' => TournamentStatus.completed,
    _ => TournamentStatus.active,
  };

  String get wireValue => switch (this) {
    TournamentStatus.active => 'active',
    TournamentStatus.completed => 'completed',
  };
}
