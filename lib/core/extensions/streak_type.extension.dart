import '../../features/profile/domain/streak_type.enum.dart';

extension StreakTypeTier on StreakType {
  int tier(int count) {
    if (this == StreakType.none) return 0;
    if (count >= 25) return 4;
    if (count >= 10) return 3;
    if (count >= 5) return 2;
    if (count >= 3) return 1;
    return 0;
  }
}
