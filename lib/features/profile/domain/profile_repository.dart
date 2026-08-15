import '../../match/domain/game_type.enum.dart';
import 'best_streaks.model.dart';
import 'head_to_head_record.model.dart';
import 'rating_point.model.dart';
import 'recent_played.model.dart';
import 'streak.model.dart';

abstract interface class ProfileRepository {
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    GameType? gameType,
    int limit = 10,
  });

  Future<int> totalMatchesPlayed({
    required String playerId,
    GameType? gameType,
  });

  Future<Streak> currentStreak({
    required String seasonId,
    required String playerId,
    GameType? gameType,
  });

  Future<BestStreaks> bestStreaks({
    required String playerId,
    GameType? gameType,
  });

  Future<RecentPlayed> recentPlayed({
    required String seasonId,
    required String playerId,
    GameType? gameType,
  });

  Future<List<HeadToHeadRecord>> headToHead({
    required String playerId,
    required String opponentId,
  });

  Future<double> bestRating({required String playerId, GameType? gameType});
}
