enum Medal {
  gold,
  silver,
  bronze;

  static Medal? fromWire(String? value) => switch (value) {
    'gold' => Medal.gold,
    'silver' => Medal.silver,
    'bronze' => Medal.bronze,
    _ => null,
  };
}
