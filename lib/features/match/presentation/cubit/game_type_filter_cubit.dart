import 'package:bloc/bloc.dart';

import '../../../../core/data/game_type_filter_store.dart';
import '../../domain/game_type.enum.dart';

class GameTypeFilterCubit extends Cubit<GameType?> {
  GameTypeFilterCubit() : super(null);

  Future<void> load() async {
    final stored = await GameTypeFilterStore.get();
    if (isClosed || stored == state) return;
    emit(stored);
  }

  Future<void> select(GameType? gameType) async {
    if (gameType == state) return;
    emit(gameType);
    await GameTypeFilterStore.set(gameType);
  }
}
