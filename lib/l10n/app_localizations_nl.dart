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
  String get commonDone => 'Klaar';

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
  String get competitionsAdd => 'Competitie toevoegen';

  @override
  String get competitionsCreate => 'Competitie maken';

  @override
  String get competitionsJoin => 'Deelnemen aan competitie';

  @override
  String get competitionsAddHint =>
      'Gebruik + om je eerste competitie te maken of eraan deel te nemen.';

  @override
  String get competitionsJoinHint =>
      'Gebruik + om deel te nemen aan je eerste competitie.';

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
      'Als gast kun je deelnemen aan een competitie en rondkijken, maar voor het maken van een competitie heb je een account nodig.';

  @override
  String get competitionCodeHelp => 'Iedereen met deze code kan meedoen.';

  @override
  String get competitionQrInvite => 'Scan om direct mee te doen';

  @override
  String get competitionQrHelp =>
      'Richt een camera op deze code — typen hoeft niet.';

  @override
  String get competitionInviteTitle => 'Spelers uitnodigen';

  @override
  String get competitionInviteAction => 'Uitnodigen';

  @override
  String get competitionUseQrInstead => 'Gebruik liever een QR-code';

  @override
  String get competitionNotFound =>
      'Deze competitie bestaat niet meer, of je zit er niet meer in.';

  @override
  String get competitionSettings => 'Instellingen';

  @override
  String get competitionSettingsSectionCompetition => 'Competitie';

  @override
  String get competitionSettingsSectionUser => 'Gebruiker';

  @override
  String get competitionSettingsSectionSystem => 'Systeem';

  @override
  String get configurationTitle => 'Configuratie';

  @override
  String get playersManageTitle => 'Spelers beheren';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String get historyEmpty => 'Er zijn nog geen seizoenen afgelopen.';

  @override
  String get configurationSave => 'Wijzigingen opslaan';

  @override
  String get configurationSaved => 'Wijzigingen opgeslagen.';

  @override
  String get configurationOwnerOnly =>
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
  String get competitionManage => 'Beheren';

  @override
  String get competitionRenameTitle => 'Competitie hernoemen';

  @override
  String get competitionRename => 'Hernoemen';

  @override
  String get competitionLeave => 'Competitie verlaten';

  @override
  String competitionLeaveConfirmTitle(String name) {
    return '$name verlaten?';
  }

  @override
  String get competitionLeaveConfirmBody =>
      'Je wedstrijden en ratings blijven bewaard, maar je hebt de code weer nodig om opnieuw mee te doen.';

  @override
  String get competitionDelete => 'Competitie verwijderen';

  @override
  String competitionDeleteConfirmTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get competitionDeleteConfirmBody =>
      'Dit verwijdert definitief alle spelers, wedstrijden en ratings in deze competitie. Dit kan niet ongedaan worden gemaakt.';

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
      'Nog geen spelers. Voeg er een paar toe en leg een wedstrijd vast.';

  @override
  String get leaderboardCurrentSeason => 'Huidig seizoen';

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
  String get matchesEmpty => 'Nog geen wedstrijden.';

  @override
  String get matchesCreateHintTabBar =>
      'Tik hieronder op Nieuwe wedstrijd om je eerste wedstrijd aan te maken.';

  @override
  String get matchesCreateHintSidebar =>
      'Gebruik Nieuwe wedstrijd om je eerste wedstrijd aan te maken.';

  @override
  String get matchDayToday => 'Vandaag';

  @override
  String get matchDayYesterday => 'Gisteren';

  @override
  String get matchNew => 'Nieuwe wedstrijd';

  @override
  String get matchNewTitle => 'Nieuwe wedstrijd';

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
  String get matchPickTeamsTitle => 'Spelers';

  @override
  String get matchTapToSelectPlayers => 'Tik om spelers toe te voegen';

  @override
  String get matchScoreTitle => 'Eindstand';

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
  String get matchNeedsPlayers => 'Voeg spelers toe en maak wedstrijden aan.';

  @override
  String get matchDiscardTitle => 'Wedstrijd weggooien?';

  @override
  String get matchDiscardConfirm =>
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
  String get playersEmpty => 'Nog geen spelers.';

  @override
  String get playersYou => 'Jij';

  @override
  String get playersOwner => 'Beheerder';

  @override
  String get playersUnclaimed => 'Niet geclaimd';

  @override
  String get playersEdit => 'Bewerken';

  @override
  String get playersAddTitle => 'Speler toevoegen';

  @override
  String get playersAddSubtitle =>
      'Maak zoveel spelers aan als je wilt. Je kunt ze gebruiken om wedstrijden vast te leggen. Of ze dienen als plaatshouder voor spelers die later meedoen. Een andere speler kan een speler claimen nadat die zich bij je competitie heeft aangesloten.';

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
  String get profileBestWinStreakLabel => 'Beste winreeks';

  @override
  String get profileBestLossStreakLabel => 'Slechtste verliesreeks';

  @override
  String get profileTrendTitle => 'Recente vorm';

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
    return 'Nog geen wedstrijden tegen $name.';
  }

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
  String get profileHistoryEmpty => 'Nog geen eerdere seizoenen.';

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
