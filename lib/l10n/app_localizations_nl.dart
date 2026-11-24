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
  String get commonLeave => 'Verlaten';

  @override
  String get commonRemove => 'Weghalen';

  @override
  String get commonLoading => 'Laden…';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonMoreActions => 'Meer acties';

  @override
  String get commonDone => 'Klaar';

  @override
  String get commonNext => 'Volgende';

  @override
  String get commonPrevious => 'Vorige';

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
  String get authSignOutGuestConfirmTitle => 'Uitloggen uit dit gastaccount?';

  @override
  String get authSignOutGuestConfirmBody =>
      'Op een gastaccount kun je niet opnieuw inloggen, dus je raakt de competities kwijt waar je ermee aan meedoet.';

  @override
  String get authGuestBadge => 'Gast';

  @override
  String get authUpgradeTitle => 'Maak een account';

  @override
  String get authUpgradeBody =>
      'Als gast kun je rondkijken, maar je hebt een account nodig om competities aan te maken en wedstrijden vast te leggen. Je geschiedenis blijft behouden.';

  @override
  String get competitionsTitle => 'Competities';

  @override
  String get competitionsCreateShort => 'Aanmaken';

  @override
  String competitionSwitch(String name) {
    return 'Wissel van competitie, nu $name';
  }

  @override
  String get welcomeBody =>
      'Doe mee met een competitie via de code, of begin er zelf een.';

  @override
  String get competitionsCreate => 'Competitie aanmaken';

  @override
  String get competitionsJoin => 'Deelnemen aan competitie';

  @override
  String get competitionsJoinShort => 'Deelnemen';

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
  String get competitionNameTooShort => 'Gebruik minstens 2 tekens.';

  @override
  String competitionSeasonExplainer(int rating) {
    return 'Elk seizoen begint iedereen weer op $rating.';
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
  String get competitionPlayedToday => 'Vandaag gespeeld';

  @override
  String get competitionPlayedYesterday => 'Gisteren gespeeld';

  @override
  String competitionPlayedDaysAgo(int count) {
    return '$count dagen geleden gespeeld';
  }

  @override
  String competitionPlayedOn(String date) {
    return 'Laatst gespeeld op $date';
  }

  @override
  String get competitionNotPlayed => 'Nog niet gespeeld';

  @override
  String get competitionGuestCannotCreate =>
      'Als gast kun je deelnemen aan een competitie en rondkijken, maar voor het aanmaken van een competitie heb je een account nodig.';

  @override
  String get competitionInviteTitle => 'Spelers uitnodigen';

  @override
  String get competitionInviteAction => 'Uitnodigen';

  @override
  String get competitionNotFound =>
      'Deze competitie bestaat niet meer, of je zit er niet meer in.';

  @override
  String get profilePageTitle => 'Profiel';

  @override
  String get profileChangeName => 'Naam wijzigen';

  @override
  String get competitionSettingsSectionSystem => 'Systeem';

  @override
  String get playersManageTitle => 'Spelers beheren';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String get historyEmpty => 'Afgelopen seizoenen verschijnen hier.';

  @override
  String get competitionEditSave => 'Wijzigingen opslaan';

  @override
  String get competitionEditOwnerOnly =>
      'Alleen de beheerder kan deze instellingen wijzigen.';

  @override
  String get competitionSeasonLengthWarning =>
      'Gespeelde seizoenen behouden hun uitslagen. Dit verandert alleen hoe volgende seizoenen lopen.';

  @override
  String get competitionKFactorLabel => 'Basispunten';

  @override
  String get competitionKFactorHelp =>
      'Punten die per wedstrijd op het spel staan, zonder bonuspunten. Hoger betekent grotere sprongen.';

  @override
  String get competitionKFactorInvalid =>
      'Kies een getal van 1 tot en met 200.';

  @override
  String get competitionMovLabel => 'Scoreverschil';

  @override
  String get competitionMovHelp => 'Wie ruimer wint, krijgt bonuspunten.';

  @override
  String get competitionMovCapLabel => 'Maximaal aantal bonuspunten';

  @override
  String get competitionMovCapInvalid => 'Kies een getal van 1 tot en met 50.';

  @override
  String get competitionShutoutBonusLabel => 'Vermenigvuldiger bij een nul';

  @override
  String get competitionShutoutBonusHelp =>
      'Vermenigvuldigt de bonuspunten als de verliezer 0 scoort.';

  @override
  String get competitionShutoutMultiplierLabel => 'Vermenigvuldiger';

  @override
  String get competitionShutoutMultiplierInvalid =>
      'Kies een getal van 1 tot en met 10.';

  @override
  String get competitionAdvancedLabel => 'Geavanceerd';

  @override
  String get competitionRenameTitle => 'Competitie hernoemen';

  @override
  String get competitionEdit => 'Bewerken';

  @override
  String get competitionRename => 'Hernoemen';

  @override
  String get competitionLeave => 'Competitie verlaten';

  @override
  String competitionLeaveConfirmTitle(String name) {
    return 'Competitie \'$name\' verlaten?';
  }

  @override
  String get competitionLeaveConfirmBody =>
      'Je wedstrijden en ratings blijven bewaard, maar je hebt de code weer nodig om opnieuw mee te doen.';

  @override
  String get competitionDelete => 'Competitie verwijderen';

  @override
  String competitionDeleteConfirmTitle(String name) {
    return 'Competitie \'$name\' verwijderen?';
  }

  @override
  String get competitionDeleteConfirmBody =>
      'Dit verwijdert definitief alle spelers, wedstrijden en ratings in deze competitie. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get joinScanTitle => 'Scan een QR-code';

  @override
  String get joinScanSubtitle =>
      'Richt de camera op de QR-code van de competitie waaraan je wilt deelnemen.';

  @override
  String get joinScanEnterCode => 'Code handmatig invoeren';

  @override
  String get joinScanUnavailable =>
      'De camera is niet beschikbaar. Voer de code handmatig in.';

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
  String get joinViewCompetition => 'Bekijk competitie';

  @override
  String get joinNewPlayerNameTitle => 'Wat is je naam?';

  @override
  String get leaderboardTitle => 'Klassement';

  @override
  String get leaderboardNoPlayers =>
      'Nog geen spelers. Voeg er een paar toe en maak een wedstrijd aan.';

  @override
  String get leaderboardCurrentSeason => 'Huidig seizoen';

  @override
  String get leaderboardManage => 'Beheren';

  @override
  String leaderboardSeasonEnds(String date) {
    return 'Loopt tot $date';
  }

  @override
  String seasonRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get leaderboardPickSeason => 'Kies een seizoen';

  @override
  String leaderboardTodayGain(String amount) {
    return 'Vandaag $amount punten gewonnen';
  }

  @override
  String leaderboardTodayLoss(String amount) {
    return 'Vandaag $amount punten verloren';
  }

  @override
  String seasonQuarterLabel(int quarter, String year) {
    return 'K$quarter $year';
  }

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '${wins}W · ${losses}V · ${draws}G';
  }

  @override
  String get gameType1v1 => '1v1';

  @override
  String get gameType2v2 => '2v2';

  @override
  String get gameType3v3 => '3v3';

  @override
  String get gameType4v4 => '4v4';

  @override
  String get gameTypeMixed => 'Gemengd';

  @override
  String get leaderboardFilterAll => 'Alles';

  @override
  String get gameTypeFilterPick => 'Filter op speltype';

  @override
  String get matchesTitle => 'Wedstrijden';

  @override
  String get matchesEmpty => 'Wedstrijden verschijnen hier.';

  @override
  String get matchesCreateTip =>
      'Druk op de +-knop hieronder om een wedstrijd aan te maken.';

  @override
  String get matchesCreateTipSidebar =>
      'Druk op de +-knop hiernaast om een wedstrijd aan te maken.';

  @override
  String get matchDayToday => 'Vandaag';

  @override
  String get matchDayYesterday => 'Gisteren';

  @override
  String get matchNew => 'Nieuwe wedstrijd';

  @override
  String get matchNewTitle => 'Nieuwe wedstrijd';

  @override
  String get matchTeamA => 'Team 1';

  @override
  String get matchTeamB => 'Team 2';

  @override
  String get matchScore => 'Score';

  @override
  String get matchSubmit => 'Wedstrijd opslaan';

  @override
  String get matchDeleteConfirmBody =>
      'De ratings van het seizoen worden opnieuw berekend.';

  @override
  String get matchPickTeamsTitle => 'Spelers';

  @override
  String get matchTapToSelectPlayers => 'Tik om spelers toe te voegen';

  @override
  String get matchTapToSelectPlayer => 'Tik om een speler te kiezen';

  @override
  String get matchModeOneVsOne => '1v1';

  @override
  String get matchModeTeams => 'Teams';

  @override
  String get matchPlayerA => 'Speler 1';

  @override
  String get matchPlayerB => 'Speler 2';

  @override
  String get matchScoreTitle => 'Eindstand';

  @override
  String get matchNeedsBothTeams => 'Zet minstens één speler aan elke kant.';

  @override
  String get matchScoreMissing => 'Vul beide scores in.';

  @override
  String get matchGuestCannotCreate =>
      'Als gast kun je rondkijken, maar voor het aanmaken van wedstrijden heb je een account nodig.';

  @override
  String get matchNeedsPlayers => 'Voeg spelers toe en maak wedstrijden aan.';

  @override
  String get matchDiscardConfirmTitle => 'Wedstrijd weggooien?';

  @override
  String get matchDiscardConfirmBody =>
      'De ingevulde spelers en score gaan verloren.';

  @override
  String get matchDiscard => 'Weggooien';

  @override
  String get matchKeepEditing => 'Verder invullen';

  @override
  String get matchDetailTitle => 'Wedstrijd';

  @override
  String get matchNotFound => 'Deze wedstrijd bestaat niet meer.';

  @override
  String get matchDelete => 'Wedstrijd verwijderen';

  @override
  String get matchDeleteConfirmTitle => 'Deze wedstrijd verwijderen?';

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
  String get matchWinChanceTitle => 'Winkans';

  @override
  String matchAddedBy(String name, String date) {
    return '$name op $date';
  }

  @override
  String get matchAddedByUnknown => 'Iemand';

  @override
  String get matchLoadMore => 'Meer laden';

  @override
  String get playersTitle => 'Spelers beheren';

  @override
  String get playersAddPlayer => 'Speler toevoegen';

  @override
  String get playersDisplayNameLabel => 'Naam';

  @override
  String get playersEmpty => 'Spelers verschijnen hier.';

  @override
  String get playersYou => 'Jij';

  @override
  String get playersOwner => 'Beheerder';

  @override
  String get playersUnclaimed => 'Niet geclaimd';

  @override
  String get playersAddTitle => 'Speler toevoegen';

  @override
  String get playersAddSubtitle =>
      'Voeg zoveel spelers toe als je wilt. Je kunt ze gebruiken om wedstrijden vast te leggen. Of ze dienen als placeholder voor spelers die later meedoen. Een speler kan een ongeclaimde speler claimen nadat die zich bij je competitie heeft aangesloten.';

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
    return 'Speler \'$name\' uit de lijst halen?';
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

  @override
  String get profileTitle => 'Jouw statistieken';

  @override
  String profileRank(int rank, int count) {
    return '#$rank van $count';
  }

  @override
  String profileWinRate(int percent) {
    return '$percent% winst';
  }

  @override
  String get profileSeasonRatingLabel => 'Rating';

  @override
  String get profileBestRatingLabel => 'Beste rating';

  @override
  String get profileWinsLabel => 'Gewonnen';

  @override
  String get profileLossesLabel => 'Verloren';

  @override
  String get profileDrawsLabel => 'Gelijk';

  @override
  String get profileWinRateLabel => 'W/L ratio';

  @override
  String get profileWinStreakLabel => 'Winreeks';

  @override
  String get profileLossStreakLabel => 'Verliesreeks';

  @override
  String get profileStreakTitle => 'Reeks';

  @override
  String get profileStreakWinsLabel => 'Gewonnen';

  @override
  String get profileStreakLosingLabel => 'Verliezend';

  @override
  String get profileStreakCurrentLabel => 'Huidig';

  @override
  String get profileStreakBestLabel => 'Beste';

  @override
  String get profileStreakWorstLabel => 'Slechtste';

  @override
  String get profileTrendTitle => 'Trend';

  @override
  String get profileNotEnoughMatches =>
      'Speel nog een paar wedstrijden om je trend te zien.';

  @override
  String get profileTabOverview => 'Overzicht';

  @override
  String get profileTabVersus => 'Versus';

  @override
  String get profileTabHistory => 'Geschiedenis';

  @override
  String profileStreakWin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer op rij gewonnen',
      one: '1 keer op rij gewonnen',
    );
    return '$_temp0';
  }

  @override
  String profileStreakLoss(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer op rij verloren',
      one: '1 keer op rij verloren',
    );
    return '$_temp0';
  }

  @override
  String profileHeadToHeadTitle(String name) {
    return 'Jouw resultaat tegen $name';
  }

  @override
  String profileVersusEmpty(String name) {
    return 'Wedstrijden tegen $name verschijnen hier.';
  }

  @override
  String get profileBiggestHumiliationLabel => 'Grootste vernedering';

  @override
  String get profileUltimateDisrespectLabel => 'Ultiem disrespect';

  @override
  String get profileTotalDisrespectsLabel => 'Totaal disrespect';

  @override
  String get profileGamesTitle => 'Wedstrijden';

  @override
  String get profileTodayGamesLabel => 'Vandaag';

  @override
  String get profileThisWeekGamesLabel => 'Deze week';

  @override
  String get profileSeasonGamesLabel => 'Seizoen';

  @override
  String get profileTotalGamesLabel => 'Totaal';

  @override
  String get profileRecentMatchesTitle => 'Recente wedstrijden';

  @override
  String get profileHistoryEmpty => 'Eerdere seizoenen verschijnen hier.';

  @override
  String get settingsDarkModeTitle => 'Donkere modus';

  @override
  String get themeOptionLight => 'Licht';

  @override
  String get themeOptionDark => 'Donker';

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get languageOptionSystem => 'Systeem';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionDutch => 'Nederlands';

  @override
  String settingsVersionLabel(String version) {
    return 'Versie $version';
  }
}
