import 'rating_point.dart';

abstract interface class ProfileRepository {
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    int limit = 10,
  });
}
