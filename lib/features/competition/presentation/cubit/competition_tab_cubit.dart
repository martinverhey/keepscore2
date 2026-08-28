import 'package:bloc/bloc.dart';

import '../widgets/competition_tab.enum.dart';

export '../widgets/competition_tab.enum.dart';

class CompetitionTabCubit extends Cubit<CompetitionTab> {
  CompetitionTabCubit() : super(CompetitionTab.leaderboard);

  void select(CompetitionTab tab) => emit(tab);

  void reset() => emit(CompetitionTab.leaderboard);
}
