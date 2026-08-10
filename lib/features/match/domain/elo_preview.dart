class EloPreview {
  const EloPreview({
    required this.teamARating,
    required this.teamBRating,
    required this.deltaA,
  });

  final double teamARating;
  final double teamBRating;
  final double deltaA;

  double get deltaB => -deltaA;
}
