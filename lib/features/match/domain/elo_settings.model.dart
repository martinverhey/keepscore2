class EloSettings {
  const EloSettings({
    this.kFactor = 32,
    this.movEnabled = true,
    this.movCap = 2.5,
    this.startingRating = 1000,
  });

  final int kFactor;
  final bool movEnabled;
  final double movCap;
  final int startingRating;
}
