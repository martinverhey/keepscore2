enum GameType {
  oneVOne,
  twoVTwo,
  threeVThree,
  fourVFour,
  mixed;

  static GameType fromWire(String value) => switch (value) {
    '1v1' => GameType.oneVOne,
    '2v2' => GameType.twoVTwo,
    '3v3' => GameType.threeVThree,
    '4v4' => GameType.fourVFour,
    _ => GameType.mixed,
  };

  String get wireValue => switch (this) {
    GameType.oneVOne => '1v1',
    GameType.twoVTwo => '2v2',
    GameType.threeVThree => '3v3',
    GameType.fourVFour => '4v4',
    GameType.mixed => 'mixed',
  };
}
