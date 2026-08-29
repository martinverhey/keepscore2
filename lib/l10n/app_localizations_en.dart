// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KeepScore2';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDone => 'Done';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorNotAuthorized => 'You don\'t have permission to do that.';

  @override
  String get errorSignedOut => 'Your session expired. Please sign in again.';

  @override
  String get authSignInTitle => 'Welcome to KeepScore2';

  @override
  String get authSignInSubtitle => 'Track your matches, climb the leaderboard.';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithEmail => 'Continue with email';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authEmailTitle => 'Sign in with email';

  @override
  String get authEmailSubtitle =>
      'We\'ll send you a six-digit code. No password needed.';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authEmailInvalid => 'That doesn\'t look like an email address.';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authResendCode => 'Send a new code';

  @override
  String get authCodeLabel => 'Six-digit code';

  @override
  String get authCodeTitle => 'Enter your code';

  @override
  String authCodeSubtitle(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get authVerify => 'Verify';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authGuestBadge => 'Guest';

  @override
  String get authUpgradeTitle => 'Create an account';

  @override
  String get authUpgradeBody =>
      'Guests can look around, but you need an account to create competitions and create matches. Your history stays with you.';

  @override
  String get competitionsTitle => 'Competitions';

  @override
  String get competitionsEmpty => 'You\'re not in any competition yet.';

  @override
  String get competitionsCreate => 'Create competition';

  @override
  String get competitionsJoin => 'Join competition';

  @override
  String get competitionNameLabel => 'Competition name';

  @override
  String get competitionSeasonLengthLabel => 'Season length';

  @override
  String get seasonMonthly => 'Monthly';

  @override
  String get seasonQuarterly => 'Quarterly';

  @override
  String get seasonYearly => 'Yearly';

  @override
  String get competitionJoinCodeLabel => 'Competition code';

  @override
  String get competitionCodeCopied => 'Copied';

  @override
  String get competitionNameTooShort =>
      'Give the competition a name of at least 2 characters.';

  @override
  String get competitionCreateSubmit => 'Create competition';

  @override
  String competitionSeasonExplainer(int rating) {
    return 'At the start of every season all ratings reset to $rating.';
  }

  @override
  String competitionPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String competitionMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'No matches yet',
    );
    return '$_temp0';
  }

  @override
  String get competitionGuestCannotCreate =>
      'Guests can look around, but creating a competition needs an account.';

  @override
  String get competitionCodeHelp => 'Anyone with this code can join.';

  @override
  String get competitionQrInvite => 'Scan to join instantly';

  @override
  String get competitionQrHelp =>
      'Point a camera at this code — no typing required.';

  @override
  String get competitionInviteTitle => 'Invite players';

  @override
  String get competitionInviteAction => 'Invite';

  @override
  String get competitionUseQrInstead => 'Use QR code instead';

  @override
  String get competitionNotFound =>
      'This competition is gone, or you\'re no longer in it.';

  @override
  String get competitionSettings => 'Settings';

  @override
  String get competitionSettingsSectionCompetition => 'Competition';

  @override
  String get competitionSettingsSectionUser => 'User';

  @override
  String get competitionSettingsSectionSystem => 'System';

  @override
  String get configurationTitle => 'Configuration';

  @override
  String get playersManageTitle => 'Manage players';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No seasons have finished yet.';

  @override
  String get configurationSave => 'Save changes';

  @override
  String get configurationSaved => 'Changes saved.';

  @override
  String get configurationOwnerOnly =>
      'Only the owner can change these settings.';

  @override
  String get competitionSeasonLengthWarning =>
      'Seasons already played keep their results. This only changes how future seasons are cut.';

  @override
  String get competitionKFactorLabel => 'K-factor';

  @override
  String get competitionKFactorHelp =>
      'How far a single match can move a rating. Higher means bigger swings.';

  @override
  String get competitionKFactorInvalid => 'Pick a K-factor between 1 and 200.';

  @override
  String get competitionMovLabel => 'Margin of victory';

  @override
  String get competitionMovHelp =>
      'Bigger wins move ratings further. Turn this off to score every win the same.';

  @override
  String get competitionMovCapLabel => 'Maximum multiplier';

  @override
  String get competitionMovCapHelp =>
      'The most a blowout can multiply the rating change by.';

  @override
  String get competitionMovCapInvalid => 'Pick a cap between 1.0 and 5.0.';

  @override
  String get competitionAllowDrawsLabel => 'Allow draws';

  @override
  String get competitionAllowDrawsHelp =>
      'Lets a match be saved with equal scores.';

  @override
  String get competitionManage => 'Manage';

  @override
  String get competitionRenameTitle => 'Rename competition';

  @override
  String get competitionRename => 'Rename';

  @override
  String get competitionLeave => 'Leave competition';

  @override
  String competitionLeaveConfirmTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get competitionLeaveConfirmBody =>
      'Your matches and ratings stay on record, but you\'ll need the code to rejoin.';

  @override
  String get competitionDelete => 'Delete competition';

  @override
  String competitionDeleteConfirmTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get competitionDeleteConfirmBody =>
      'This permanently deletes every player, match and rating in this competition. This can\'t be undone.';

  @override
  String get joinTitle => 'Join a competition';

  @override
  String get joinSubtitle =>
      'Enter the six-character code from whoever set it up.';

  @override
  String get joinLookUp => 'Find competition';

  @override
  String get joinCodeInvalid => 'A code is six characters.';

  @override
  String joinConfirmTitle(String name) {
    return 'Join $name';
  }

  @override
  String joinRunBy(String owner) {
    return 'Run by $owner';
  }

  @override
  String get joinClaimTitle => 'Are you one of these players?';

  @override
  String get joinClaimSubtitle =>
      'Pick your name to take over its rating and match history. Tap again to deselect.';

  @override
  String get joinAsNewPlayer => 'Join as a new player';

  @override
  String get joinConfirm => 'Join';

  @override
  String get joinAlreadyMember => 'You\'re already in this competition.';

  @override
  String get joinViewCompetition => 'View competition';

  @override
  String get joinNewPlayerNameTitle => 'What\'s your name?';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardNoPlayers =>
      'No players yet. Add a few and log a match.';

  @override
  String get leaderboardCurrentSeason => 'Current season';

  @override
  String leaderboardSeasonEnds(String date) {
    return 'Ends $date';
  }

  @override
  String get leaderboardPickSeason => 'Choose a season';

  @override
  String leaderboardTodayGain(String amount) {
    return 'Gained $amount points today';
  }

  @override
  String leaderboardTodayLoss(String amount) {
    return 'Lost $amount points today';
  }

  @override
  String seasonQuarterLabel(int quarter, String year) {
    return 'Q$quarter $year';
  }

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '${wins}W · ${losses}L · ${draws}D';
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
  String get gameTypeMixed => 'Mixed';

  @override
  String get leaderboardFilterAll => 'All';

  @override
  String get gameTypeFilterPick => 'Filter by game type';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get matchesEmpty => 'No matches yet.';

  @override
  String matchesFilterEmpty(String gameType) {
    return 'No $gameType matches yet.';
  }

  @override
  String get matchesCreateHint => 'Create your first match.';

  @override
  String get matchesCreateHintAction => 'Create Match';

  @override
  String get matchDayToday => 'Today';

  @override
  String get matchDayYesterday => 'Yesterday';

  @override
  String get matchNew => 'New match';

  @override
  String get matchNewTitle => 'New Match';

  @override
  String get matchTeamA => 'Team A';

  @override
  String get matchTeamB => 'Team B';

  @override
  String get matchScore => 'Score';

  @override
  String get matchSubmit => 'Save match';

  @override
  String get matchDeleteConfirm =>
      'Delete this match? Ratings for the season will be recalculated.';

  @override
  String get matchPickTeamsTitle => 'Players';

  @override
  String get matchTapToSelectPlayers => 'Tap to add players';

  @override
  String get matchScoreTitle => 'Final score';

  @override
  String matchTeamRating(String rating) {
    return 'Team rating $rating';
  }

  @override
  String get matchNeedsBothTeams => 'Put at least one player on each side.';

  @override
  String get matchScoreMissing => 'Enter both scores.';

  @override
  String get matchDrawNotAllowed => 'This competition doesn\'t allow draws.';

  @override
  String get matchGuestCannotLog =>
      'Guests can look around, but logging a match needs an account.';

  @override
  String get matchNeedsPlayers => 'Add players and start creating matches.';

  @override
  String get matchDiscardTitle => 'Discard this match?';

  @override
  String get matchDiscardConfirm =>
      'The players and score you entered will be lost.';

  @override
  String get matchDiscard => 'Discard';

  @override
  String get matchKeepEditing => 'Keep editing';

  @override
  String get matchDetailTitle => 'Match';

  @override
  String get matchNotFound => 'This match is gone.';

  @override
  String get matchDelete => 'Delete match';

  @override
  String get matchDeleteTitle => 'Delete this match?';

  @override
  String get matchEditScore => 'Edit score';

  @override
  String get matchEditScoreTitle => 'Change the score';

  @override
  String get matchEditScoreHelp =>
      'The season is recalculated from this match onwards.';

  @override
  String get matchDraw => 'Draw';

  @override
  String get matchLoadMore => 'Load more';

  @override
  String get playersTitle => 'Manage Players';

  @override
  String get playersAddDummy => 'Add a dummy';

  @override
  String get playersDisplayNameLabel => 'Name';

  @override
  String get playersEmpty => 'No players yet.';

  @override
  String get playersYou => 'You';

  @override
  String get playersOwner => 'Owner';

  @override
  String get playersDummy => 'Dummy';

  @override
  String get playersEdit => 'Edit';

  @override
  String get playersAddTitle => 'Add a dummy';

  @override
  String get playersAddSubtitle =>
      'Create as many dummies as you want. You can use them to create matches. Or they can be used as placeholders for players who might join later. Another player can claim a dummy after joining your competition.';

  @override
  String get playersNameTooShort => 'Enter a name of at least 2 characters.';

  @override
  String get playersRenameTitle => 'Rename player';

  @override
  String get playersRename => 'Rename';

  @override
  String get playersRemove => 'Remove from player list';

  @override
  String playersRemoveConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get playersRemoveConfirmBody =>
      'Their matches and ratings stay on record, and they drop off the leaderboard. You can add them back at any time.';

  @override
  String get playersRemoved => 'Removed';

  @override
  String get playersRestore => 'Add back';

  @override
  String get playersGuestCannotAdd =>
      'Guests can look around, but adding players needs an account.';

  @override
  String get profileTitle => 'Your stats';

  @override
  String profileRank(int rank, int count) {
    return '#$rank of $count';
  }

  @override
  String profileWinRate(int percent) {
    return '$percent% win rate';
  }

  @override
  String get profileSeasonRatingLabel => 'Season rating';

  @override
  String get profileBestRatingLabel => 'Best rating';

  @override
  String get profileWinsLabel => 'Wins';

  @override
  String get profileLossesLabel => 'Losses';

  @override
  String get profileDrawsLabel => 'Draws';

  @override
  String get profileWinRateLabel => 'Win rate';

  @override
  String get profileWinStreakLabel => 'Win streak season';

  @override
  String get profileWinStreakShortLabel => 'Win streak';

  @override
  String get profileLossStreakLabel => 'Loss streak';

  @override
  String get profileBestWinStreakLabel => 'Win streak overall';

  @override
  String get profileBestLossStreakLabel => 'Worst loss streak';

  @override
  String get profileTrendTitle => 'Recent form';

  @override
  String get profileNotEnoughMatches =>
      'Play a couple more matches to see your trend.';

  @override
  String get profileTabOverview => 'Overview';

  @override
  String get profileTabVersus => 'Versus';

  @override
  String get profileTabHistory => 'History';

  @override
  String profileStreakWin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins in a row',
      one: '1 win in a row',
    );
    return '$_temp0';
  }

  @override
  String profileStreakMilestoneWins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '1 win',
    );
    return '$_temp0';
  }

  @override
  String profileStreakLoss(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count losses in a row',
      one: '1 loss in a row',
    );
    return '$_temp0';
  }

  @override
  String profileHeadToHeadTitle(String name) {
    return 'Your record vs $name';
  }

  @override
  String profileVersusEmpty(String name) {
    return 'No matches against $name yet.';
  }

  @override
  String get profileGamesTitle => 'Games';

  @override
  String get profileTodayGamesLabel => 'Today';

  @override
  String get profileThisWeekGamesLabel => 'This week';

  @override
  String get profileSeasonGamesLabel => 'Season';

  @override
  String get profileTotalGamesLabel => 'Total';

  @override
  String get profileRecentMatchesTitle => 'Recent matches';

  @override
  String get profileHistoryEmpty => 'No past seasons yet.';

  @override
  String get settingsDarkModeTitle => 'Dark mode';

  @override
  String get themeOptionLight => 'Light';

  @override
  String get themeOptionDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get languageOptionSystem => 'System';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionDutch => 'Nederlands';
}
