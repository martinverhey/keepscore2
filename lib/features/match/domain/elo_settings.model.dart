class EloSettings {
  const EloSettings({
    this.kFactor = 60,
    this.movEnabled = true,
    this.movCap = 10,
    this.startingRating = 1000,
  });

  final int kFactor;
  final bool movEnabled;
  final double movCap;
  final int startingRating;
}
