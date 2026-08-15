enum MatchTeam {
  a,
  b;

  static MatchTeam fromWire(String value) =>
      value == 'b' ? MatchTeam.b : MatchTeam.a;

  MatchTeam get opposite => this == MatchTeam.a ? MatchTeam.b : MatchTeam.a;
}
