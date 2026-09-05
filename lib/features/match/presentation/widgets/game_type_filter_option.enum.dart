import '../../domain/game_type.enum.dart';

enum GameTypeFilterOption {
  all,
  oneVOne,
  twoVTwo,
  threeVThree,
  fourVFour,
  mixed;

  GameType? get gameType => switch (this) {
    GameTypeFilterOption.all => null,
    GameTypeFilterOption.oneVOne => GameType.oneVOne,
    GameTypeFilterOption.twoVTwo => GameType.twoVTwo,
    GameTypeFilterOption.threeVThree => GameType.threeVThree,
    GameTypeFilterOption.fourVFour => GameType.fourVFour,
    GameTypeFilterOption.mixed => GameType.mixed,
  };

  static GameTypeFilterOption from(GameType? gameType) => switch (gameType) {
    null => GameTypeFilterOption.all,
    GameType.oneVOne => GameTypeFilterOption.oneVOne,
    GameType.twoVTwo => GameTypeFilterOption.twoVTwo,
    GameType.threeVThree => GameTypeFilterOption.threeVThree,
    GameType.fourVFour => GameTypeFilterOption.fourVFour,
    GameType.mixed => GameTypeFilterOption.mixed,
  };
}
