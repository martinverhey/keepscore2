enum StreakType {
  none,
  win,
  loss;

  static StreakType fromWire(String value) => switch (value) {
    'win' => StreakType.win,
    'loss' => StreakType.loss,
    _ => StreakType.none,
  };
}
