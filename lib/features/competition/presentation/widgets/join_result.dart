class JoinResult {
  const JoinResult.joined(String this.competitionId);
  const JoinResult.back() : competitionId = null;

  final String? competitionId;
}
