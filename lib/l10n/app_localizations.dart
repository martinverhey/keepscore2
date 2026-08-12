import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KeepScore2'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorNotAuthorized;

  /// No description provided for @errorSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorSignedOut;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KeepScore2'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your matches, climb the leaderboard.'**
  String get authSignInSubtitle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get authContinueWithEmail;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authEmailTitle;

  /// No description provided for @authEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a six-digit code. No password needed.'**
  String get authEmailSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailLabel;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address.'**
  String get authEmailInvalid;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get authResendCode;

  /// No description provided for @authCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Six-digit code'**
  String get authCodeLabel;

  /// No description provided for @authCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get authCodeTitle;

  /// No description provided for @authCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String authCodeSubtitle(String email);

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authGuestBadge.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get authGuestBadge;

  /// No description provided for @authUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authUpgradeTitle;

  /// No description provided for @authUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Guests can look around, but you need an account to create competitions and log matches. Your history stays with you.'**
  String get authUpgradeBody;

  /// No description provided for @competitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get competitionsTitle;

  /// No description provided for @competitionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in any competition yet.'**
  String get competitionsEmpty;

  /// No description provided for @competitionsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create competition'**
  String get competitionsCreate;

  /// No description provided for @competitionsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join competition'**
  String get competitionsJoin;

  /// No description provided for @competitionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition name'**
  String get competitionNameLabel;

  /// No description provided for @competitionSeasonLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Season length'**
  String get competitionSeasonLengthLabel;

  /// No description provided for @seasonMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get seasonMonthly;

  /// No description provided for @seasonQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get seasonQuarterly;

  /// No description provided for @seasonYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get seasonYearly;

  /// No description provided for @competitionJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition code'**
  String get competitionJoinCodeLabel;

  /// No description provided for @competitionCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get competitionCodeCopied;

  /// No description provided for @competitionNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Give the competition a name of at least 2 characters.'**
  String get competitionNameTooShort;

  /// No description provided for @competitionCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create competition'**
  String get competitionCreateSubmit;

  /// No description provided for @competitionSeasonExplainer.
  ///
  /// In en, this message translates to:
  /// **'At the start of every season all ratings reset to {rating}.'**
  String competitionSeasonExplainer(int rating);

  /// No description provided for @competitionPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player} other{{count} players}}'**
  String competitionPlayers(int count);

  /// No description provided for @competitionMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches yet} =1{1 match} other{{count} matches}}'**
  String competitionMatches(int count);

  /// No description provided for @competitionGuestCannotCreate.
  ///
  /// In en, this message translates to:
  /// **'Guests can look around, but creating a competition needs an account.'**
  String get competitionGuestCannotCreate;

  /// No description provided for @competitionCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code can join.'**
  String get competitionCodeHelp;

  /// No description provided for @competitionQrInvite.
  ///
  /// In en, this message translates to:
  /// **'Scan to join instantly'**
  String get competitionQrInvite;

  /// No description provided for @competitionQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Point a camera at this code — no typing required.'**
  String get competitionQrHelp;

  /// No description provided for @competitionInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite players'**
  String get competitionInviteTitle;

  /// No description provided for @competitionInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get competitionInviteAction;

  /// No description provided for @competitionUseQrInstead.
  ///
  /// In en, this message translates to:
  /// **'Use QR code instead'**
  String get competitionUseQrInstead;

  /// No description provided for @competitionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This competition is gone, or you\'re no longer in it.'**
  String get competitionNotFound;

  /// No description provided for @competitionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get competitionSettings;

  /// No description provided for @competitionMenuSectionCompetition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get competitionMenuSectionCompetition;

  /// No description provided for @competitionMenuSectionUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get competitionMenuSectionUser;

  /// No description provided for @competitionMenuSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get competitionMenuSectionSystem;

  /// No description provided for @competitionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition settings'**
  String get competitionSettingsTitle;

  /// No description provided for @playersManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage players'**
  String get playersManageTitle;

  /// No description provided for @competitionSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get competitionSettingsSave;

  /// No description provided for @competitionSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get competitionSettingsSaved;

  /// No description provided for @competitionSettingsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change these settings.'**
  String get competitionSettingsOwnerOnly;

  /// No description provided for @competitionSeasonLengthWarning.
  ///
  /// In en, this message translates to:
  /// **'Seasons already played keep their results. This only changes how future seasons are cut.'**
  String get competitionSeasonLengthWarning;

  /// No description provided for @competitionKFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'K-factor'**
  String get competitionKFactorLabel;

  /// No description provided for @competitionKFactorHelp.
  ///
  /// In en, this message translates to:
  /// **'How far a single match can move a rating. Higher means bigger swings.'**
  String get competitionKFactorHelp;

  /// No description provided for @competitionKFactorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick a K-factor between 1 and 200.'**
  String get competitionKFactorInvalid;

  /// No description provided for @competitionMovLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin of victory'**
  String get competitionMovLabel;

  /// No description provided for @competitionMovHelp.
  ///
  /// In en, this message translates to:
  /// **'Bigger wins move ratings further. Turn this off to score every win the same.'**
  String get competitionMovHelp;

  /// No description provided for @competitionMovCapLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum multiplier'**
  String get competitionMovCapLabel;

  /// No description provided for @competitionMovCapHelp.
  ///
  /// In en, this message translates to:
  /// **'The most a blowout can multiply the rating change by.'**
  String get competitionMovCapHelp;

  /// No description provided for @competitionMovCapInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick a cap between 1.0 and 5.0.'**
  String get competitionMovCapInvalid;

  /// No description provided for @competitionAllowDrawsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow draws'**
  String get competitionAllowDrawsLabel;

  /// No description provided for @competitionAllowDrawsHelp.
  ///
  /// In en, this message translates to:
  /// **'Lets a match be saved with equal scores.'**
  String get competitionAllowDrawsHelp;

  /// No description provided for @competitionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get competitionManage;

  /// No description provided for @competitionRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename competition'**
  String get competitionRenameTitle;

  /// No description provided for @competitionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get competitionRename;

  /// No description provided for @competitionLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave competition'**
  String get competitionLeave;

  /// No description provided for @competitionLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String competitionLeaveConfirmTitle(String name);

  /// No description provided for @competitionLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your matches and ratings stay on record, but you\'ll need the code to rejoin.'**
  String get competitionLeaveConfirmBody;

  /// No description provided for @competitionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete competition'**
  String get competitionDelete;

  /// No description provided for @competitionDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String competitionDeleteConfirmTitle(String name);

  /// No description provided for @competitionDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every player, match and rating in this competition. This can\'t be undone.'**
  String get competitionDeleteConfirmBody;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a competition'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-character code from whoever set it up.'**
  String get joinSubtitle;

  /// No description provided for @joinLookUp.
  ///
  /// In en, this message translates to:
  /// **'Find competition'**
  String get joinLookUp;

  /// No description provided for @joinCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'A code is six characters.'**
  String get joinCodeInvalid;

  /// No description provided for @joinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {name}?'**
  String joinConfirmTitle(String name);

  /// No description provided for @joinRunBy.
  ///
  /// In en, this message translates to:
  /// **'Run by {owner}'**
  String joinRunBy(String owner);

  /// No description provided for @joinClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you one of these players?'**
  String get joinClaimTitle;

  /// No description provided for @joinClaimSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your name to take over its rating and match history. Tap again to deselect.'**
  String get joinClaimSubtitle;

  /// No description provided for @joinAsNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Join as a new player'**
  String get joinAsNewPlayer;

  /// No description provided for @joinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinConfirm;

  /// No description provided for @joinAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in this competition.'**
  String get joinAlreadyMember;

  /// No description provided for @joinViewCompetition.
  ///
  /// In en, this message translates to:
  /// **'View competition'**
  String get joinViewCompetition;

  /// No description provided for @joinNewPlayerNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get joinNewPlayerNameTitle;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'No players yet. Add a few and log a match.'**
  String get leaderboardNoPlayers;

  /// No description provided for @leaderboardCurrentSeason.
  ///
  /// In en, this message translates to:
  /// **'Current season'**
  String get leaderboardCurrentSeason;

  /// No description provided for @leaderboardSeasonEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String leaderboardSeasonEnds(String date);

  /// No description provided for @leaderboardPickSeason.
  ///
  /// In en, this message translates to:
  /// **'Choose a season'**
  String get leaderboardPickSeason;

  /// No description provided for @leaderboardUnplayed.
  ///
  /// In en, this message translates to:
  /// **'Not played yet'**
  String get leaderboardUnplayed;

  /// No description provided for @seasonQuarterLabel.
  ///
  /// In en, this message translates to:
  /// **'Q{quarter} {year}'**
  String seasonQuarterLabel(int quarter, String year);

  /// No description provided for @leaderboardRecord.
  ///
  /// In en, this message translates to:
  /// **'{wins}W · {losses}L · {draws}D'**
  String leaderboardRecord(int wins, int losses, int draws);

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// No description provided for @matchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matches yet.'**
  String get matchesEmpty;

  /// No description provided for @matchesCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first match.'**
  String get matchesCreateHint;

  /// No description provided for @matchesCreateHintAction.
  ///
  /// In en, this message translates to:
  /// **'Create Match'**
  String get matchesCreateHintAction;

  /// No description provided for @matchDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get matchDayToday;

  /// No description provided for @matchDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get matchDayYesterday;

  /// No description provided for @matchNew.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get matchNew;

  /// No description provided for @matchNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter match'**
  String get matchNewTitle;

  /// No description provided for @matchTeamA.
  ///
  /// In en, this message translates to:
  /// **'Team A'**
  String get matchTeamA;

  /// No description provided for @matchTeamB.
  ///
  /// In en, this message translates to:
  /// **'Team B'**
  String get matchTeamB;

  /// No description provided for @matchScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get matchScore;

  /// No description provided for @matchSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save match'**
  String get matchSubmit;

  /// No description provided for @matchDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this match? Ratings for the season will be recalculated.'**
  String get matchDeleteConfirm;

  /// No description provided for @matchPickTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose players'**
  String get matchPickTeamsTitle;

  /// No description provided for @matchPickTeamsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap a team below to choose who played.'**
  String get matchPickTeamsHelp;

  /// No description provided for @matchTapToSelectPlayers.
  ///
  /// In en, this message translates to:
  /// **'Tap to add players'**
  String get matchTapToSelectPlayers;

  /// No description provided for @matchScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Final score'**
  String get matchScoreTitle;

  /// No description provided for @matchScoreTeam.
  ///
  /// In en, this message translates to:
  /// **'{team} score'**
  String matchScoreTeam(String team);

  /// No description provided for @matchPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What this is worth'**
  String get matchPreviewTitle;

  /// No description provided for @matchPreviewCaveat.
  ///
  /// In en, this message translates to:
  /// **'An estimate. The final numbers are calculated when the match is saved.'**
  String get matchPreviewCaveat;

  /// No description provided for @matchTeamRating.
  ///
  /// In en, this message translates to:
  /// **'Team rating {rating}'**
  String matchTeamRating(String rating);

  /// No description provided for @matchNeedsBothTeams.
  ///
  /// In en, this message translates to:
  /// **'Put at least one player on each side.'**
  String get matchNeedsBothTeams;

  /// No description provided for @matchScoreMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter both scores.'**
  String get matchScoreMissing;

  /// No description provided for @matchDrawNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This competition doesn\'t allow draws.'**
  String get matchDrawNotAllowed;

  /// No description provided for @matchGuestCannotLog.
  ///
  /// In en, this message translates to:
  /// **'Guests can look around, but logging a match needs an account.'**
  String get matchGuestCannotLog;

  /// No description provided for @matchNeedsPlayers.
  ///
  /// In en, this message translates to:
  /// **'Add players and start creating matches.'**
  String get matchNeedsPlayers;

  /// No description provided for @matchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchDetailTitle;

  /// No description provided for @matchNotFound.
  ///
  /// In en, this message translates to:
  /// **'This match is gone.'**
  String get matchNotFound;

  /// No description provided for @matchDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete match'**
  String get matchDelete;

  /// No description provided for @matchDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this match?'**
  String get matchDeleteTitle;

  /// No description provided for @matchEditScore.
  ///
  /// In en, this message translates to:
  /// **'Edit score'**
  String get matchEditScore;

  /// No description provided for @matchEditScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Change the score'**
  String get matchEditScoreTitle;

  /// No description provided for @matchEditScoreHelp.
  ///
  /// In en, this message translates to:
  /// **'The season is recalculated from this match onwards.'**
  String get matchEditScoreHelp;

  /// No description provided for @matchDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get matchDraw;

  /// No description provided for @matchLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get matchLoadMore;

  /// No description provided for @playersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersTitle;

  /// No description provided for @playersAddDummy.
  ///
  /// In en, this message translates to:
  /// **'Add a dummy'**
  String get playersAddDummy;

  /// No description provided for @playersDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playersDisplayNameLabel;

  /// No description provided for @playersUnclaimed.
  ///
  /// In en, this message translates to:
  /// **'Not claimed'**
  String get playersUnclaimed;

  /// No description provided for @playersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players yet.'**
  String get playersEmpty;

  /// No description provided for @playersYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get playersYou;

  /// No description provided for @playersOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get playersOwner;

  /// No description provided for @playersDummy.
  ///
  /// In en, this message translates to:
  /// **'Dummy'**
  String get playersDummy;

  /// No description provided for @playersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get playersEdit;

  /// No description provided for @playersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a dummy'**
  String get playersAddTitle;

  /// No description provided for @playersAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create as many dummies as you want. You can use them to create matches. Or they can be used as placeholders for players who might join later. Another player can claim a dummy after joining your competition.'**
  String get playersAddSubtitle;

  /// No description provided for @playersNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of at least 2 characters.'**
  String get playersNameTooShort;

  /// No description provided for @playersRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename player'**
  String get playersRenameTitle;

  /// No description provided for @playersRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get playersRename;

  /// No description provided for @playersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from roster'**
  String get playersRemove;

  /// No description provided for @playersRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String playersRemoveConfirmTitle(String name);

  /// No description provided for @playersRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Their matches and ratings stay on record, and they drop off the leaderboard. You can add them back at any time.'**
  String get playersRemoveConfirmBody;

  /// No description provided for @playersRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get playersRemoved;

  /// No description provided for @playersRestore.
  ///
  /// In en, this message translates to:
  /// **'Add back'**
  String get playersRestore;

  /// No description provided for @playersGuestCannotAdd.
  ///
  /// In en, this message translates to:
  /// **'Guests can look around, but adding players needs an account.'**
  String get playersGuestCannotAdd;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get profileTitle;

  /// No description provided for @profileRank.
  ///
  /// In en, this message translates to:
  /// **'#{rank} of {count}'**
  String profileRank(int rank, int count);

  /// No description provided for @profileWinRate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% win rate'**
  String profileWinRate(int percent);

  /// No description provided for @profileTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get profileTrendTitle;

  /// No description provided for @profileNotEnoughMatches.
  ///
  /// In en, this message translates to:
  /// **'Play a couple more matches to see your trend.'**
  String get profileNotEnoughMatches;

  /// No description provided for @profileGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String profileGreeting(String name);

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @themeOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeOptionSystem;

  /// No description provided for @themeOptionLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeOptionLight;

  /// No description provided for @themeOptionDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeOptionDark;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
