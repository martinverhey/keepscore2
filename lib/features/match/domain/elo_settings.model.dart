class EloSettings {
  const EloSettings({
    this.kFactor = 60,
    this.movEnabled = true,
    this.movCap = 10,
    this.shutoutBonus = true,
    this.shutoutMultiplier = 2,
    this.startingRating = 1000,
  });

  static const int minKFactor = 1;
  static const int maxKFactor = 200;
  static const double minMovCap = 1;
  static const double maxMovCap = 50;
  static const double minShutoutMultiplier = 1;
  static const double maxShutoutMultiplier = 10;

  final int kFactor;
  final bool movEnabled;
  final double movCap;
  final bool shutoutBonus;
  final double shutoutMultiplier;
  final int startingRating;

  static bool kFactorIsValid(int? value) =>
      value != null && value >= minKFactor && value <= maxKFactor;

  static bool movCapIsValid(double? value) =>
      value != null && value >= minMovCap && value <= maxMovCap;

  static bool shutoutMultiplierIsValid(double? value) =>
      value != null &&
      value >= minShutoutMultiplier &&
      value <= maxShutoutMultiplier;
}
