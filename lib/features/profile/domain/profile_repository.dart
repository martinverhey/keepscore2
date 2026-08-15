import '../../match/domain/game_type.enum.dart';
import 'head_to_head_record.model.dart';
import 'profile_stats.model.dart';
import 'rating_point.model.dart';

abstract interface class ProfileRepository {
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    GameType? gameType,
    int limit = 10,
  });

  Future<ProfileStats> profileStats({
    required String playerId,
    String? seasonId,
    GameType? gameType,
  });

  Future<List<HeadToHeadRecord>> headToHead({
    required String playerId,
    required String opponentId,
  });
}
