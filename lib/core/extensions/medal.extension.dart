import 'package:flutter/widgets.dart';

import '../../features/leaderboard/domain/medal.enum.dart';
import '../theme/app_tokens.dart';

extension MedalColor on Medal {
  Color get color => switch (this) {
    Medal.gold => AppColors.gold,
    Medal.silver => AppColors.silver,
    Medal.bronze => AppColors.bronze,
  };
}
