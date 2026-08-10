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
