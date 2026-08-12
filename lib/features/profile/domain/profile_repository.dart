import 'head_to_head_record.dart';
import 'rating_point.dart';
import 'streak.dart';

abstract interface class ProfileRepository {
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    int limit = 10,
  });

  Future<int> totalMatchesPlayed({required String playerId});

  Future<Streak> currentStreak({
    required String seasonId,
    required String playerId,
  });

  Future<List<HeadToHeadRecord>> headToHead({
    required String playerId,
    required String opponentId,
  });
}
