import '../../app/router/app_router.dart';
import '../../features/competition/presentation/widgets/competition_tab.enum.dart';

extension CompetitionTabRoute on CompetitionTab {
  String route(String competitionId) => switch (this) {
    CompetitionTab.leaderboard => Routes.leaderboard(competitionId),
    CompetitionTab.matches => Routes.matches(competitionId),
    CompetitionTab.competitions => Routes.competitions(competitionId),
  };
}
