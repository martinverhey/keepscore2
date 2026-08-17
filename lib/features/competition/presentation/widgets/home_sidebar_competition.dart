class HomeSidebarCompetition {
  const HomeSidebarCompetition({
    required this.competitionId,
    required this.competitionName,
    required this.canManageSettings,
  });

  final String competitionId;
  final String? competitionName;
  final bool canManageSettings;
}
