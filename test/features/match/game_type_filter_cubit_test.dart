import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  blocTest<GameTypeFilterCubit, GameType?>(
    'defaults to combined when nothing has been stored',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: GameTypeFilterCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [],
  );

  blocTest<GameTypeFilterCubit, GameType?>(
    'loads a previously stored game type',
    setUp: () =>
        SharedPreferences.setMockInitialValues({'selected_game_type': '2v2'}),
    build: GameTypeFilterCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [GameType.twoVTwo],
  );

  blocTest<GameTypeFilterCubit, GameType?>(
    'selecting a game type emits it and persists it for the next launch',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: GameTypeFilterCubit.new,
    act: (cubit) => cubit.select(GameType.oneVOne),
    expect: () => [GameType.oneVOne],
    verify: (_) async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_game_type'), '1v1');
    },
  );

  blocTest<GameTypeFilterCubit, GameType?>(
    'selecting combined after a specific type clears the stored value',
    setUp: () =>
        SharedPreferences.setMockInitialValues({'selected_game_type': '1v1'}),
    build: GameTypeFilterCubit.new,
    act: (cubit) async {
      await cubit.load();
      await cubit.select(null);
    },
    expect: () => [GameType.oneVOne, null],
    verify: (_) async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_game_type'), isNull);
    },
  );

  blocTest<GameTypeFilterCubit, GameType?>(
    'selecting the already-selected game type is a no-op',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: GameTypeFilterCubit.new,
    act: (cubit) async {
      await cubit.select(GameType.mixed);
      await cubit.select(GameType.mixed);
    },
    expect: () => [GameType.mixed],
  );
}
