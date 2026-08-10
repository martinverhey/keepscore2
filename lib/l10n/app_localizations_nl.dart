// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'KeepScore2';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonCopy => 'Kopiëren';

  @override
  String get errorGeneric => 'Er is iets misgegaan. Probeer het opnieuw.';

  @override
  String get errorNetwork =>
      'Geen verbinding. Controleer je internet en probeer het opnieuw.';

  @override
  String get errorNotAuthorized => 'Je hebt hier geen rechten voor.';

  @override
  String get errorSignedOut => 'Je sessie is verlopen. Log opnieuw in.';

  @override
  String get authSignInTitle => 'Welkom bij KeepScore2';

  @override
  String get authSignInSubtitle =>
      'Houd je wedstrijden bij en klim op het klassement.';

  @override
  String get authContinueWithApple => 'Doorgaan met Apple';

  @override
  String get authContinueWithGoogle => 'Doorgaan met Google';

  @override
  String get authContinueWithEmail => 'Doorgaan met e-mail';

  @override
  String get authContinueAsGuest => 'Doorgaan als gast';

  @override
  String get authEmailTitle => 'Inloggen met e-mail';

  @override
  String get authEmailSubtitle =>
      'We sturen je een code van zes cijfers. Geen wachtwoord nodig.';

  @override
  String get authEmailLabel => 'E-mailadres';

  @override
  String get authEmailInvalid => 'Dit lijkt geen e-mailadres te zijn.';

  @override
  String get authSendCode => 'Code versturen';

  @override
  String get authResendCode => 'Nieuwe code versturen';

  @override
  String get authCodeLabel => 'Code van zes cijfers';

  @override
  String get authCodeTitle => 'Voer je code in';

  @override
  String authCodeSubtitle(String email) {
    return 'We hebben een code van 6 cijfers naar $email gestuurd.';
  }

  @override
  String get authVerify => 'Bevestigen';

  @override
  String get authSignOut => 'Uitloggen';

  @override
  String get authGuestBadge => 'Gast';

  @override
  String get authUpgradeTitle => 'Maak een account';

  @override
  String get authUpgradeBody =>
      'Als gast kun je rondkijken, maar je hebt een account nodig om competities te maken en wedstrijden vast te leggen. Je geschiedenis blijft behouden.';

  @override
  String get competitionsTitle => 'Competities';

  @override
  String get competitionsEmpty => 'Je zit nog niet in een competitie.';

  @override
  String get competitionsCreate => 'Competitie maken';

  @override
  String get competitionsJoin => 'Deelnemen aan competitie';

  @override
  String get competitionNameLabel => 'Naam van de competitie';

  @override
  String get competitionSeasonLengthLabel => 'Lengte van het seizoen';

  @override
  String get seasonMonthly => 'Maandelijks';

  @override
  String get seasonQuarterly => 'Per kwartaal';

  @override
  String get seasonYearly => 'Jaarlijks';

  @override
  String get competitionJoinCodeLabel => 'Competitiecode';

  @override
  String get competitionCodeCopied => 'Gekopieerd';

  @override
  String get competitionNameTooShort =>
      'Geef de competitie een naam van minstens 2 tekens.';

  @override
  String get competitionCreateSubmit => 'Competitie maken';

  @override
  String competitionSeasonExplainer(int rating) {
    return 'Aan het begin van elk seizoen gaan alle ratings terug naar $rating.';
  }

  @override
  String competitionPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spelers',
      one: '1 speler',
    );
    return '$_temp0';
  }

  @override
  String competitionMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wedstrijden',
      one: '1 wedstrijd',
      zero: 'Nog geen wedstrijden',
    );
    return '$_temp0';
  }

  @override
  String get competitionGuestCannotCreate =>
      'Als gast kun je rondkijken, maar voor het maken van een competitie heb je een account nodig.';

  @override
  String get competitionCodeHelp => 'Iedereen met deze code kan meedoen.';

  @override
  String get competitionNotFound =>
      'Deze competitie bestaat niet meer, of je zit er niet meer in.';

  @override
  String get competitionSettings => 'Instellingen';

  @override
  String get competitionSettingsTitle => 'Competitie-instellingen';

  @override
  String get competitionSettingsSave => 'Wijzigingen opslaan';

  @override
  String get competitionSettingsSaved => 'Wijzigingen opgeslagen.';

  @override
  String get competitionSettingsOwnerOnly =>
      'Alleen de beheerder kan deze instellingen wijzigen.';

  @override
  String get competitionSeasonLengthWarning =>
      'Gespeelde seizoenen behouden hun uitslagen. Dit verandert alleen hoe volgende seizoenen lopen.';

  @override
  String get competitionKFactorLabel => 'K-factor';

  @override
  String get competitionKFactorHelp =>
      'Hoeveel één wedstrijd een rating kan verschuiven. Hoger betekent grotere sprongen.';

  @override
  String get competitionKFactorInvalid => 'Kies een K-factor tussen 1 en 200.';

  @override
  String get competitionMovLabel => 'Scoreverschil';

  @override
  String get competitionMovHelp =>
      'Grotere overwinningen verschuiven ratings verder. Zet dit uit om elke winst even zwaar te laten tellen.';

  @override
  String get competitionMovCapLabel => 'Maximale vermenigvuldiging';

  @override
  String get competitionMovCapHelp =>
      'Het maximum waarmee een monsterzege de ratingwijziging vergroot.';

  @override
  String get competitionMovCapInvalid => 'Kies een maximum tussen 1,0 en 5,0.';

  @override
  String get competitionAllowDrawsLabel => 'Gelijkspel toestaan';

  @override
  String get competitionAllowDrawsHelp =>
      'Maakt het mogelijk een wedstrijd met gelijke score op te slaan.';

  @override
  String get joinTitle => 'Deelnemen aan een competitie';

  @override
  String get joinSubtitle =>
      'Voer de code van zes tekens in die je van de organisator hebt gekregen.';

  @override
  String get joinLookUp => 'Competitie opzoeken';

  @override
  String get joinCodeInvalid => 'Een code bestaat uit zes tekens.';

  @override
  String joinConfirmTitle(String name) {
    return 'Deelnemen aan $name?';
  }

  @override
  String joinRunBy(String owner) {
    return 'Beheerd door $owner';
  }

  @override
  String get joinClaimTitle => 'Ben jij een van deze spelers?';

  @override
  String get joinClaimSubtitle =>
      'Kies je naam om de rating en wedstrijdgeschiedenis over te nemen. Tik nogmaals om de keuze ongedaan te maken.';

  @override
  String get joinAsNewPlayer => 'Deelnemen als nieuwe speler';

  @override
  String get joinConfirm => 'Deelnemen';

  @override
  String get joinAlreadyMember => 'Je zit al in deze competitie.';

  @override
  String get leaderboardTitle => 'Klassement';

  @override
  String get leaderboardEmpty =>
      'Dit seizoen zijn er nog geen wedstrijden gespeeld.';

  @override
  String get leaderboardNoPlayers =>
      'Nog geen spelers. Voeg er een paar toe en leg een wedstrijd vast.';

  @override
  String get leaderboardCurrentSeason => 'Huidig seizoen';

  @override
  String leaderboardSeasonEnds(String date) {
    return 'Loopt tot $date';
  }

  @override
  String get leaderboardPickSeason => 'Kies een seizoen';

  @override
  String get leaderboardUnplayed => 'Nog niet gespeeld';

  @override
  String seasonQuarterLabel(int quarter, String year) {
    return 'K$quarter $year';
  }

  @override
  String get leaderboardRank => 'Positie';

  @override
  String get leaderboardPlayer => 'Speler';

  @override
  String get leaderboardRating => 'Rating';

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '${wins}W · ${losses}V · ${draws}G';
  }

  @override
  String get matchesTitle => 'Wedstrijden';

  @override
  String get matchesEmpty => 'Nog geen wedstrijden. Leg je eerste vast.';

  @override
  String get matchNew => 'Nieuwe wedstrijd';

  @override
  String get matchNewTitle => 'Wedstrijd vastleggen';

  @override
  String get matchTeamA => 'Team A';

  @override
  String get matchTeamB => 'Team B';

  @override
  String get matchScore => 'Score';

  @override
  String get matchSubmit => 'Wedstrijd opslaan';

  @override
  String get matchDeleteConfirm =>
      'Deze wedstrijd verwijderen? De ratings van het seizoen worden opnieuw berekend.';

  @override
  String get matchPickTeamsTitle => 'Wie hebben er gespeeld?';

  @override
  String get matchPickTeamsHelp =>
      'Tik op A of B om iemand aan die kant te zetten. Tik nogmaals om diegene eraf te halen.';

  @override
  String get matchBench => 'Speelt niet mee';

  @override
  String get matchScoreTitle => 'Eindstand';

  @override
  String matchScoreTeam(String team) {
    return 'Score $team';
  }

  @override
  String get matchSwapSides => 'Kanten wisselen';

  @override
  String get matchClearTeams => 'Teams wissen';

  @override
  String get matchPreviewTitle => 'Wat dit oplevert';

  @override
  String get matchPreviewCaveat =>
      'Een schatting. De definitieve cijfers worden berekend bij het opslaan.';

  @override
  String matchTeamRating(String rating) {
    return 'Teamrating $rating';
  }

  @override
  String get matchNeedsBothTeams => 'Zet minstens één speler aan elke kant.';

  @override
  String get matchScoreMissing => 'Vul beide scores in.';

  @override
  String get matchDrawNotAllowed =>
      'Deze competitie staat geen gelijkspel toe.';

  @override
  String get matchGuestCannotLog =>
      'Als gast kun je rondkijken, maar voor het vastleggen van wedstrijden heb je een account nodig.';

  @override
  String get matchNeedsPlayers =>
      'Voeg eerst spelers toe voordat je een wedstrijd vastlegt.';

  @override
  String get matchDetailTitle => 'Wedstrijd';

  @override
  String get matchNotFound => 'Deze wedstrijd bestaat niet meer.';

  @override
  String get matchDelete => 'Wedstrijd verwijderen';

  @override
  String get matchDeleteTitle => 'Deze wedstrijd verwijderen?';

  @override
  String get matchEditScore => 'Score aanpassen';

  @override
  String get matchEditScoreTitle => 'Score aanpassen';

  @override
  String get matchEditScoreHelp =>
      'Het seizoen wordt vanaf deze wedstrijd opnieuw berekend.';

  @override
  String get matchDraw => 'Gelijkspel';

  @override
  String get matchLoadMore => 'Meer laden';

  @override
  String get playersTitle => 'Spelers';

  @override
  String get playersAddDummy => 'Speler toevoegen';

  @override
  String get playersDisplayNameLabel => 'Naam';

  @override
  String get playersUnclaimed => 'Niet geclaimd';

  @override
  String get playersEmpty => 'Nog geen spelers.';

  @override
  String get playersYou => 'Jij';

  @override
  String get playersOwner => 'Beheerder';

  @override
  String get playersEdit => 'Bewerken';

  @override
  String get playersAddTitle => 'Speler toevoegen';

  @override
  String get playersAddSubtitle =>
      'Met een tijdelijke speler kun je wedstrijden vastleggen voor iemand die nog niet meedoet. Diegene kan die naam later claimen met de competitiecode.';

  @override
  String get playersNameTooShort => 'Vul een naam van minstens 2 tekens in.';

  @override
  String get playersRenameTitle => 'Speler hernoemen';

  @override
  String get playersRename => 'Hernoemen';

  @override
  String get playersRemove => 'Uit de lijst halen';

  @override
  String playersRemoveConfirmTitle(String name) {
    return '$name uit de lijst halen?';
  }

  @override
  String get playersRemoveConfirmBody =>
      'Wedstrijden en ratings blijven bewaard, en de speler verdwijnt uit het klassement. Je kunt de speler altijd terugzetten.';

  @override
  String get playersRemoved => 'Verwijderd';

  @override
  String get playersRestore => 'Terugzetten';

  @override
  String get playersGuestCannotAdd =>
      'Als gast kun je rondkijken, maar voor het toevoegen van spelers heb je een account nodig.';
}
