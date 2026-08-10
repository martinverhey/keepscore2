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
      'Guests can look around, but you need an account to create competitions and log matches. Your history stays with you.';

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
  String get competitionNotFound =>
      'This competition is gone, or you\'re no longer in it.';

  @override
  String get competitionSettings => 'Settings';

  @override
  String get competitionSettingsTitle => 'Competition settings';

  @override
  String get competitionSettingsSave => 'Save changes';

  @override
  String get competitionSettingsSaved => 'Changes saved.';

  @override
  String get competitionSettingsOwnerOnly =>
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
    return 'Join $name?';
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
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardEmpty => 'No matches played this season yet.';

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
  String get leaderboardUnplayed => 'Not played yet';

  @override
  String seasonQuarterLabel(int quarter, String year) {
    return 'Q$quarter $year';
  }

  @override
  String get leaderboardRank => 'Rank';

  @override
  String get leaderboardPlayer => 'Player';

  @override
  String get leaderboardRating => 'Rating';

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '${wins}W · ${losses}L · ${draws}D';
  }

  @override
  String get matchesTitle => 'Matches';

  @override
  String get matchesEmpty => 'No matches yet. Log your first one.';

  @override
  String get matchNew => 'New match';

  @override
  String get matchNewTitle => 'Log a match';

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
  String get matchPickTeamsTitle => 'Who played?';

  @override
  String get matchPickTeamsHelp =>
      'Tap A or B to put someone on that side. Tap again to take them off.';

  @override
  String get matchBench => 'Not playing';

  @override
  String get matchScoreTitle => 'Final score';

  @override
  String matchScoreTeam(String team) {
    return '$team score';
  }

  @override
  String get matchSwapSides => 'Swap sides';

  @override
  String get matchClearTeams => 'Clear teams';

  @override
  String get matchPreviewTitle => 'What this is worth';

  @override
  String get matchPreviewCaveat =>
      'An estimate. The final numbers are calculated when the match is saved.';

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
  String get matchNeedsPlayers =>
      'Add players to the roster before logging a match.';

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
  String get playersTitle => 'Players';

  @override
  String get playersAddDummy => 'Add player';

  @override
  String get playersDisplayNameLabel => 'Name';

  @override
  String get playersUnclaimed => 'Not claimed';

  @override
  String get playersEmpty => 'No players yet.';

  @override
  String get playersYou => 'You';

  @override
  String get playersOwner => 'Owner';

  @override
  String get playersEdit => 'Edit';

  @override
  String get playersAddTitle => 'Add a player';

  @override
  String get playersAddSubtitle =>
      'A placeholder lets you log matches for someone who hasn\'t joined yet. They can claim the name later with the competition code.';

  @override
  String get playersNameTooShort => 'Enter a name of at least 2 characters.';

  @override
  String get playersRenameTitle => 'Rename player';

  @override
  String get playersRename => 'Rename';

  @override
  String get playersRemove => 'Remove from roster';

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
}
